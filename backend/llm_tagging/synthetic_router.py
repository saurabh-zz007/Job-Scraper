import logging
import asyncio

from typing import Any
from sqlalchemy import update, select, or_, and_

from core.db import AsyncSessionLocal
from core.models import Job, JobStatus
from core.settings import settings
from llm_tagging.llm_ingestion import LLMIngestion
from llm_tagging.rule_based_ingestions import RuleBasedEnricher
from llm_tagging.schemas import LLMJobInput

logger = logging.getLogger(__name__)

_llm_ingestion_queue = asyncio.Queue()
_worker_tasks: list[asyncio.Task] = []

async def llm_tagging(job_data: dict[str, Any]):
    _llm_ingestion_queue.put_nowait(job_data)


async def _synthetic_llm_worker(worker_id: int)-> None:
    logger.info("LLM Tagging worker-%d ready", worker_id)

    llm_ingestion_service = LLMIngestion()
    rule_based_ingestion_service = RuleBasedEnricher(settings.LLM_MODEL)

    while True:
        job_data = await _llm_ingestion_queue.get()
        job_id = job_data["id"]

        if job_id is None:
            logger.error("Worker-%d received job without 'id': %s", worker_id, job_data.get("source_url"))
            _llm_ingestion_queue.task_done()
            continue

        try:
            llm_input = LLMJobInput(
                job_id=job_id,
                title=job_data.get("raw_title"),
                location=job_data.get("raw_location"),
                description=job_data.get("description")
            )

            llm_tags, llm_usage_metrics = await llm_ingestion_service.extract_llm_tags(llm_input)
            rule_based_ingestions = rule_based_ingestion_service.build_rule_based_payload(
                job_data=llm_input,
                llm_fields=llm_tags,
                usage=llm_usage_metrics,
                posted_at = job_data.get("posted_at"),
                current_attempts=job_data.get("processing_attempts", 0)
            )

            updated_value = {
                **llm_tags.model_dump(),
                **rule_based_ingestions.model_dump(),
            }

            async with AsyncSessionLocal() as session:
                stmt = (
                    update(Job)
                    .where(Job.id == job_id)
                    .values(**updated_value)
                )
                await session.execute(stmt)
                await session.commit()

            logger.info(
                "[DB ENRICHED - ID: %s] %s | confidence=%.2f | cost=$%.6f",
                job_id,
                llm_input.title,
                rule_based_ingestions.classification_confidence,
                rule_based_ingestions.llm_cost_usd,
            )

        except Exception as e:
            logger.error(
                "Worker-%d error processing %s: %s",
                worker_id,
                job_id,
                job_data.get("source_url"),
                e,
                exc_info=True,
            )
            try:
                async with AsyncSessionLocal() as session:
                    stmt = (
                        update(Job)
                        .where(Job.id == job_id)
                        .values(
                            etl_status=JobStatus.FAILED,
                            last_error=str(e),
                            processing_attempts=Job.processing_attempts + 1,
                        )
                    )
                    await session.execute(stmt)
                    await session.commit()
            except Exception as db_err:
                logger.error("Worker-%d failed to update error state for %s: %s", worker_id, job_id, db_err)
        finally:
            _llm_ingestion_queue.task_done()


async def recover_pending_llm_jobs() -> int:

    async with AsyncSessionLocal() as session:
        stmt = (
            select(
                Job.id,
                Job.raw_title,
                Job.raw_location,
                Job.description,
                Job.posted_at,
                Job.source_url,
            )
            .where(
                or_(
                    Job.etl_status == JobStatus.RAW,
                    and_(
                        Job.etl_status == JobStatus.FAILED,
                        Job.processing_attempts < 3,
                    ),
                )
            )
            .order_by(Job.created_at.asc())
        )
        result = await session.execute(stmt)
        rows = result.all()
        for row in rows:
            job_payload = {
                "id": row.id,
                "raw_title": row.raw_title,
                "raw_location": row.raw_location,
                "description": row.description,
                "posted_at": row.posted_at,
                "source_url": row.source_url,
            }
            await llm_tagging(job_payload)
        return len(rows)

def start_synthetic_LLM_workers(num_workers: int = 3) -> None:
    for i in range(num_workers):
        task = asyncio.create_task(_synthetic_llm_worker(i + 1))
        _worker_tasks.append(task)


async def stop_synthetic_LLM_workers() -> None:
    for task in _worker_tasks:
        task.cancel()
    await asyncio.gather(*_worker_tasks, return_exceptions=True)
    _worker_tasks.clear()