import asyncio
import logging
import math
from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import (
    select,
    func,
    case,
    delete,
    and_,
    or_,
)
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Job, JobStatus
from admin.schemas import (
    DashboardMetricsResponse,
    PipelineLiveStatus,
    FunnelMetrics,
    LLMEconomics,
    QualityMetrics,
    SourceMetric,
    PromptVersionMetric,
    TopErrorMetric,
    JobListItem,
    PaginatedJobsResponse,
    JobDetailResponse,
)

logger = logging.getLogger(__name__)

# Batch run state tracker
_batch_running: bool = False


def is_batch_running() -> bool:
    return _batch_running


def set_batch_running(running: bool) -> None:
    global _batch_running
    _batch_running = running


def get_llm_queue_depth() -> int:
    try:
        from llm_tagging.synthetic_router import _llm_ingestion_queue
        return _llm_ingestion_queue.qsize()
    except Exception:
        return 0


def _map_status_filter(status_str: str | None) -> JobStatus | None:
    """Map UI/query status strings (including CLASSIFIED/FILTERED aliases) to JobStatus."""
    if not status_str or status_str.upper() == "ALL":
        return None
    val = status_str.strip().upper()
    if val in ("CLASSIFIED", "PUBLISHED"):
        return JobStatus.PUBLISHED
    if val in ("FILTERED", "PROCESSING", "PENDING"):
        return JobStatus.PROCESSING
    if val == "RAW":
        return JobStatus.RAW
    if val == "FAILED":
        return JobStatus.FAILED
    if val == "DUPLICATE":
        return JobStatus.DUPLICATE
    if val in JobStatus.__members__:
        return JobStatus[val]
    return None


class AdminService:
    """Pure SQLAlchemy aggregation & control logic for Admin Operations."""

    async def get_dashboard_metrics(self, db: AsyncSession) -> DashboardMetricsResponse:
        """
        Derive all financial, funnel, and quality metrics dynamically from Job
        using SQL func.count, func.sum, func.avg, and case(...).
        """
        now_utc = datetime.now(timezone.utc)
        twenty_four_hours_ago = now_utc - timedelta(hours=24)
        fourteen_days_ago = now_utc - timedelta(days=14)

        # 1. Pipeline Live Status
        pipeline_live = PipelineLiveStatus(
            batch_running=is_batch_running(),
            llm_queue_depth=get_llm_queue_depth(),
        )

        # 2. Funnel Metrics
        funnel_stmt = select(
            func.count(Job.id).label("total_jobs"),
            func.count(case((Job.etl_status == JobStatus.RAW, 1))).label("raw"),
            func.count(case((Job.etl_status == JobStatus.PROCESSING, 1))).label("filtered_pending_llm"),
            func.count(case((Job.etl_status == JobStatus.PUBLISHED, 1))).label("classified"),
            func.count(case((Job.etl_status == JobStatus.FAILED, 1))).label("failed"),
        )
        funnel_res = await db.execute(funnel_stmt)
        f_row = funnel_res.one()

        funnel = FunnelMetrics(
            total_jobs=int(f_row.total_jobs or 0),
            raw=int(f_row.raw or 0),
            filtered_pending_llm=int(f_row.filtered_pending_llm or 0),
            classified=int(f_row.classified or 0),
            failed=int(f_row.failed or 0),
        )

        # 3. LLM Economics
        econ_stmt = select(
            func.coalesce(func.sum(Job.llm_cost_usd), 0.0).label("total_cost_usd"),
            func.coalesce(
                func.sum(case((Job.updated_at >= twenty_four_hours_ago, Job.llm_cost_usd), else_=0.0)),
                0.0,
            ).label("cost_last_24h_usd"),
            func.coalesce(func.sum(Job.llm_input_tokens), 0).label("total_input_tokens"),
            func.coalesce(func.sum(Job.llm_output_tokens), 0).label("total_output_tokens"),
            func.count(case((Job.etl_status == JobStatus.PUBLISHED, 1))).label("classified_count"),
        )
        econ_res = await db.execute(econ_stmt)
        e_row = econ_res.one()

        total_cost = float(e_row.total_cost_usd or 0.0)
        cost_24h = float(e_row.cost_last_24h_usd or 0.0)
        total_inp = int(e_row.total_input_tokens or 0)
        total_out = int(e_row.total_output_tokens or 0)
        classified_count = int(e_row.classified_count or 0)
        avg_cost_per_job = (total_cost / classified_count) if classified_count > 0 else 0.0

        llm_economics = LLMEconomics(
            total_cost_usd=round(total_cost, 6),
            cost_last_24h_usd=round(cost_24h, 6),
            avg_cost_per_job_usd=round(avg_cost_per_job, 6),
            total_input_tokens=total_inp,
            total_output_tokens=total_out,
        )

        # 4. Quality Metrics
        quality_stmt = select(
            func.coalesce(
                func.avg(case((Job.etl_status == JobStatus.PUBLISHED, Job.classification_confidence))),
                0.0,
            ).label("avg_confidence"),
            func.count(
                case(
                    (
                        and_(
                            Job.etl_status == JobStatus.PUBLISHED,
                            Job.classification_confidence < 0.60,
                        ),
                        1,
                    )
                )
            ).label("low_confidence_jobs"),
            func.count(
                case(
                    (
                        and_(
                            Job.updated_at <= fourteen_days_ago,
                            Job.etl_status == JobStatus.PUBLISHED,
                        ),
                        1,
                    )
                )
            ).label("stale_jobs_over_14d"),
        )
        quality_res = await db.execute(quality_stmt)
        q_row = quality_res.one()

        quality = QualityMetrics(
            avg_confidence=round(float(q_row.avg_confidence or 0.0), 4),
            low_confidence_jobs=int(q_row.low_confidence_jobs or 0),
            stale_jobs_over_14d=int(q_row.stale_jobs_over_14d or 0),
        )

        # 5. By Source
        source_stmt = (
            select(
                Job.source_name,
                func.count(Job.id).label("total"),
                func.count(case((Job.etl_status == JobStatus.PUBLISHED, 1))).label("classified"),
                func.count(case((Job.etl_status == JobStatus.FAILED, 1))).label("failed"),
                func.coalesce(func.avg(Job.classification_confidence), 0.0).label("avg_confidence"),
            )
            .group_by(Job.source_name)
            .order_by(func.count(Job.id).desc())
        )
        source_res = await db.execute(source_stmt)
        by_source = [
            SourceMetric(
                source_name=row.source_name,
                total=int(row.total or 0),
                classified=int(row.classified or 0),
                failed=int(row.failed or 0),
                avg_confidence=round(float(row.avg_confidence or 0.0), 4),
            )
            for row in source_res.all()
        ]

        # 6. By Prompt Version & Model
        prompt_stmt = (
            select(
                Job.llm_model,
                Job.prompt_version,
                func.count(Job.id).label("jobs_processed"),
                func.coalesce(func.avg(Job.classification_confidence), 0.0).label("avg_confidence"),
                func.coalesce(func.avg(Job.llm_cost_usd), 0.0).label("avg_cost_usd"),
            )
            .where(Job.prompt_version.isnot(None))
            .group_by(Job.llm_model, Job.prompt_version)
            .order_by(func.count(Job.id).desc())
        )
        prompt_res = await db.execute(prompt_stmt)
        by_prompt_version = [
            PromptVersionMetric(
                llm_model=row.llm_model,
                prompt_version=row.prompt_version,
                jobs_processed=int(row.jobs_processed or 0),
                avg_confidence=round(float(row.avg_confidence or 0.0), 4),
                avg_cost_usd=round(float(row.avg_cost_usd or 0.0), 6),
            )
            for row in prompt_res.all()
        ]

        # 7. Top Errors
        errors_stmt = (
            select(
                Job.last_error,
                func.count(Job.id).label("count"),
            )
            .where(
                and_(
                    Job.last_error.isnot(None),
                    Job.last_error != "",
                )
            )
            .group_by(Job.last_error)
            .order_by(func.count(Job.id).desc())
            .limit(10)
        )
        errors_res = await db.execute(errors_stmt)
        top_errors = [
            TopErrorMetric(
                error=row.last_error,
                count=int(row.count or 0),
            )
            for row in errors_res.all()
        ]

        return DashboardMetricsResponse(
            pipeline_live=pipeline_live,
            funnel=funnel,
            llm_economics=llm_economics,
            quality=quality,
            by_source=by_source,
            by_prompt_version=by_prompt_version,
            top_errors=top_errors,
        )

    async def list_jobs(
        self,
        db: AsyncSession,
        page: int = 1,
        page_size: int = 25,
        etl_status: str | None = None,
        source_name: str | None = None,
        search: str | None = None,
        max_confidence: float | None = None,
    ) -> PaginatedJobsResponse:
        """
        Lightweight paginated list of jobs for the Admin table,
        excluding heavy text/JSON payloads, ordered by Job.updated_at.desc().
        """
        if page < 1:
            page = 1
        if page_size < 1:
            page_size = 25
        elif page_size > 100:
            page_size = 100

        conditions = []

        # Status filter
        status_enum = _map_status_filter(etl_status)
        if status_enum is not None:
            conditions.append(Job.etl_status == status_enum)

        # Source filter
        if source_name and source_name.strip() and source_name.upper() != "ALL":
            conditions.append(Job.source_name.ilike(source_name.strip()))

        # Search filter (company name or title)
        if search and search.strip():
            pat = f"%{search.strip()}%"
            conditions.append(
                or_(
                    Job.raw_title.ilike(pat),
                    Job.company_name.ilike(pat),
                )
            )

        # Max confidence filter (e.g. low confidence < 0.60)
        if max_confidence is not None:
            conditions.append(Job.classification_confidence <= max_confidence)

        where_clause = and_(*conditions) if conditions else None

        # Count total
        count_stmt = select(func.count(Job.id))
        if where_clause is not None:
            count_stmt = count_stmt.where(where_clause)
        total_res = await db.execute(count_stmt)
        total = total_res.scalar() or 0

        # Query items
        query_stmt = (
            select(
                Job.id,
                Job.company_name,
                Job.raw_title,
                Job.raw_location,
                Job.source_name,
                Job.etl_status,
                Job.inferred_role,
                Job.inferred_city,
                Job.inferred_work_mode,
                Job.inferred_experience,
                Job.classification_confidence,
                Job.processing_attempts,
                Job.llm_cost_usd,
                Job.last_error,
                Job.created_at,
                Job.updated_at,
            )
            .order_by(Job.updated_at.desc().nullslast(), Job.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        if where_clause is not None:
            query_stmt = query_stmt.where(where_clause)

        items_res = await db.execute(query_stmt)
        rows = items_res.all()

        items = [
            JobListItem(
                id=row.id,
                company_name=row.company_name,
                raw_title=row.raw_title,
                raw_location=row.raw_location,
                source_name=row.source_name,
                etl_status=str(row.etl_status.value if hasattr(row.etl_status, "value") else row.etl_status),
                inferred_role=row.inferred_role,
                inferred_city=row.inferred_city,
                inferred_work_mode=row.inferred_work_mode,
                inferred_experience=row.inferred_experience,
                classification_confidence=row.classification_confidence,
                processing_attempts=row.processing_attempts or 0,
                llm_cost_usd=float(row.llm_cost_usd) if row.llm_cost_usd is not None else None,
                last_error=row.last_error,
                created_at=row.created_at,
                updated_at=row.updated_at,
            )
            for row in rows
        ]

        total_pages = math.ceil(total / page_size) if total > 0 else 0

        return PaginatedJobsResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )

    async def get_job_detail(self, db: AsyncSession, job_id: UUID) -> JobDetailResponse | None:
        """Fetch full job details including raw_payload, description, and LLM metrics."""
        stmt = select(Job).where(Job.id == job_id)
        res = await db.execute(stmt)
        job = res.scalar_one_or_none()
        if not job:
            return None

        return JobDetailResponse(
            id=job.id,
            company_name=job.company_name,
            raw_title=job.raw_title,
            raw_location=job.raw_location,
            source_name=job.source_name,
            etl_status=str(job.etl_status.value if hasattr(job.etl_status, "value") else job.etl_status),
            inferred_role=job.inferred_role,
            inferred_city=job.inferred_city,
            inferred_work_mode=job.inferred_work_mode,
            inferred_experience=job.inferred_experience,
            classification_confidence=job.classification_confidence,
            processing_attempts=job.processing_attempts,
            llm_cost_usd=float(job.llm_cost_usd) if job.llm_cost_usd is not None else None,
            last_error=job.last_error,
            created_at=job.created_at,
            updated_at=job.updated_at,
            source_url=job.source_url,
            description=job.description,
            raw_payload=job.raw_payload,
            inferred_job_type=job.inferred_job_type,
            inferred_skills=job.inferred_skills or [],
            llm_model=job.llm_model,
            prompt_version=job.prompt_version,
            llm_input_tokens=job.llm_input_tokens,
            llm_output_tokens=job.llm_output_tokens,
            posted_at=job.posted_at,
            last_seen_at=job.last_seen_at,
            classified_at=job.classified_at,
        )

    async def retry_failed_jobs(
        self,
        db: AsyncSession,
        job_ids: list[UUID] | None = None,
    ) -> int:
        """
        Resets failed jobs back to PROCESSING/pending state, clears last_error,
        commits to DB, and re-enqueues into _llm_ingestion_queue.
        """
        stmt = select(Job).where(Job.etl_status == JobStatus.FAILED)
        if job_ids:
            stmt = stmt.where(Job.id.in_(job_ids))

        res = await db.execute(stmt)
        jobs_to_retry = list(res.scalars().all())

        if not jobs_to_retry:
            return 0

        for job in jobs_to_retry:
            job.etl_status = JobStatus.PROCESSING
            job.processing_attempts = 0
            job.last_error = None
            job.updated_at = datetime.now(timezone.utc)

        await db.commit()

        # Re-enqueue into LLM queue
        try:
            from llm_tagging.synthetic_router import llm_tagging
            for job in jobs_to_retry:
                payload = {
                    "id": job.id,
                    "raw_title": job.raw_title,
                    "raw_location": job.raw_location,
                    "description": job.description,
                    "source_url": job.source_url,
                    "posted_at": job.posted_at,
                    "processing_attempts": 0,
                }
                await llm_tagging(payload)
        except Exception as e:
            logger.warning("Could not re-enqueue all jobs into LLM queue: %s", e)

        return len(jobs_to_retry)

    async def reclassify_jobs(
        self,
        db: AsyncSession,
        prompt_version: str | None = None,
        max_confidence: float | None = None,
    ) -> int:
        """
        Re-queues matching CLASSIFIED jobs for fresh LLM tagging
        (e.g. across a new prompt version or low-confidence subset).
        """
        conditions = [Job.etl_status == JobStatus.PUBLISHED]

        if prompt_version:
            conditions.append(Job.prompt_version != prompt_version)
        if max_confidence is not None:
            conditions.append(Job.classification_confidence <= max_confidence)

        stmt = select(Job).where(and_(*conditions))
        res = await db.execute(stmt)
        jobs = list(res.scalars().all())

        if not jobs:
            return 0

        for job in jobs:
            job.etl_status = JobStatus.PROCESSING
            job.processing_attempts = 0
            job.updated_at = datetime.now(timezone.utc)

        await db.commit()

        try:
            from llm_tagging.synthetic_router import llm_tagging
            for job in jobs:
                payload = {
                    "id": job.id,
                    "raw_title": job.raw_title,
                    "raw_location": job.raw_location,
                    "description": job.description,
                    "source_url": job.source_url,
                    "posted_at": job.posted_at,
                    "processing_attempts": 0,
                }
                await llm_tagging(payload)
        except Exception as e:
            logger.warning("Could not re-enqueue jobs for reclassification: %s", e)

        return len(jobs)

    async def purge_jobs(
        self,
        db: AsyncSession,
        status_filter: str | None = None,
        older_than_days: int | None = None,
    ) -> int:
        """
        Deletes matching rows. Requires at least one filter guard
        so accidental empty calls cannot wipe the entire table.
        """
        status_enum = _map_status_filter(status_filter)

        if status_enum is None and (older_than_days is None or older_than_days <= 0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Safety guard: You must specify either a valid 'etl_status' or 'older_than_days' > 0 to purge records.",
            )

        conditions = []
        if status_enum is not None:
            conditions.append(Job.etl_status == status_enum)

        if older_than_days is not None and older_than_days > 0:
            cutoff = datetime.now(timezone.utc) - timedelta(days=older_than_days)
            conditions.append(Job.updated_at <= cutoff)

        del_stmt = delete(Job).where(and_(*conditions))
        result = await db.execute(del_stmt)
        await db.commit()

        return result.rowcount or 0

    async def delete_single_job(self, db: AsyncSession, job_id: UUID) -> bool:
        """Delete a single job row by UUID."""
        stmt = delete(Job).where(Job.id == job_id)
        result = await db.execute(stmt)
        await db.commit()
        return (result.rowcount or 0) > 0

    async def trigger_batch_in_background(self) -> dict:
        """Triggers the full batch scraping & ingestion pipeline in the background."""
        if is_batch_running():
            return {
                "batch_running": True,
                "message": "A pipeline batch ingestion job is already running.",
            }

        set_batch_running(True)

        async def _run():
            try:
                from data_collection.pipeline import run_collection_pipeline
                logger.info("[ADMIN] Starting background batch collection pipeline...")
                await run_collection_pipeline()
                logger.info("[ADMIN] Batch collection pipeline completed.")
            except Exception as e:
                logger.error("[ADMIN] Error running batch collection pipeline: %s", e)
            finally:
                set_batch_running(False)

        asyncio.create_task(_run())

        return {
            "batch_running": True,
            "message": "Batch ingestion pipeline triggered successfully in background.",
        }

