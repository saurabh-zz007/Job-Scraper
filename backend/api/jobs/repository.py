import logging
from uuid import UUID
from sqlalchemy import (
    select,
    func,
    or_,
    and_,
    cast,
    String,
    distinct,
)
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Job, JobStatus

logger = logging.getLogger(__name__)


class JobRepository:
    """SQLAlchemy 2.0 async repository for Job queries and aggregations."""

    async def get_jobs(
        self,
        session: AsyncSession,
        search: str | None = None,
        roles: list[str] | None = None,
        work_modes: list[str] | None = None,
        job_types: list[str] | None = None,
        experience_levels: list[str] | None = None,
        cities: list[str] | None = None,
        sources: list[str] | None = None,
        etl_status: JobStatus | None = None,
        sort_by: str = "newest",
        skip: int = 0,
        limit: int = 20,
    ) -> tuple[list[Job], int]:
        """
        Query jobs with filtering, full-text keyword search across title, company,
        and JSONB inferred_skills, dynamic ordering, and pagination.
        """
        conditions = []

        # 1. Status Filter
        if etl_status is not None:
            conditions.append(Job.etl_status == etl_status)

        # 2. Keyword Search
        if search and search.strip():
            clean_search = f"%{search.strip()}%"
            # Cast JSONB inferred_skills to String for fast substring matching
            skills_cast = cast(Job.inferred_skills, String)
            search_clause = or_(
                Job.raw_title.ilike(clean_search),
                Job.company_name.ilike(clean_search),
                skills_cast.ilike(clean_search),
            )
            conditions.append(search_clause)

        # 3. Role Categories (multi-select)
        if roles:
            clean_roles = [r.strip() for r in roles if r.strip()]
            if clean_roles:
                conditions.append(Job.inferred_role.in_(clean_roles))

        # 4. Work Modes (multi-select)
        if work_modes:
            clean_modes = [m.strip().lower() for m in work_modes if m.strip()]
            if clean_modes:
                conditions.append(Job.inferred_work_mode.in_(clean_modes))

        # 5. Job Types (multi-select)
        if job_types:
            clean_types = [t.strip().lower() for t in job_types if t.strip()]
            if clean_types:
                conditions.append(Job.inferred_job_type.in_(clean_types))

        # 6. Experience Levels (multi-select)
        if experience_levels:
            clean_exp = [e.strip().lower() for e in experience_levels if e.strip()]
            if clean_exp:
                conditions.append(Job.inferred_experience.in_(clean_exp))

        # 7. Cities / Locations (multi-select)
        if cities:
            clean_cities = [c.strip() for c in cities if c.strip()]
            if clean_cities:
                conditions.append(Job.inferred_city.in_(clean_cities))

        # 8. ATS Sources (multi-select)
        if sources:
            clean_sources = [s.strip() for s in sources if s.strip()]
            if clean_sources:
                conditions.append(Job.source_name.in_(clean_sources))

        # Combine conditions
        where_clause = and_(*conditions) if conditions else None

        # Count total matching rows
        count_stmt = select(func.count(Job.id))
        if where_clause is not None:
            count_stmt = count_stmt.where(where_clause)
        total_res = await session.execute(count_stmt)
        total_count = total_res.scalar() or 0

        # Query paginated rows
        query_stmt = select(Job)
        if where_clause is not None:
            query_stmt = query_stmt.where(where_clause)

        # Sorting
        if sort_by == "confidence":
            query_stmt = query_stmt.order_by(
                Job.classification_confidence.desc().nullslast(),
                Job.posted_at.desc().nullslast(),
                Job.created_at.desc(),
            )
        else:
            # Default "newest"
            query_stmt = query_stmt.order_by(
                Job.posted_at.desc().nullslast(),
                Job.created_at.desc(),
            )

        query_stmt = query_stmt.offset(skip).limit(limit)

        result = await session.execute(query_stmt)
        items = list(result.scalars().all())

        return items, total_count

    async def get_job_by_id(
        self,
        session: AsyncSession,
        job_id: UUID,
    ) -> Job | None:
        """Fetch a single job record by its UUID primary key."""
        stmt = select(Job).where(Job.id == job_id)
        result = await session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_filter_options(
        self,
        session: AsyncSession,
        etl_status: JobStatus | None = JobStatus.PUBLISHED,
    ) -> dict:
        """
        Efficiently query distinct values across all filter dimensions from the DB.
        """
        status_filter = Job.etl_status == etl_status if etl_status else True

        # Roles
        roles_stmt = (
            select(Job.inferred_role)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.inferred_role.isnot(None),
                    Job.inferred_role != "",
                )
            )
            .order_by(Job.inferred_role)
        )
        roles_res = await session.execute(roles_stmt)
        roles = [r for r in roles_res.scalars().all() if r]

        # Work Modes
        modes_stmt = (
            select(Job.inferred_work_mode)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.inferred_work_mode.isnot(None),
                    Job.inferred_work_mode != "",
                )
            )
            .order_by(Job.inferred_work_mode)
        )
        modes_res = await session.execute(modes_stmt)
        work_modes = [m for m in modes_res.scalars().all() if m]

        # Job Types
        types_stmt = (
            select(Job.inferred_job_type)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.inferred_job_type.isnot(None),
                    Job.inferred_job_type != "",
                )
            )
            .order_by(Job.inferred_job_type)
        )
        types_res = await session.execute(types_stmt)
        job_types = [t for t in types_res.scalars().all() if t]

        # Experience Levels
        exp_stmt = (
            select(Job.inferred_experience)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.inferred_experience.isnot(None),
                    Job.inferred_experience != "",
                )
            )
            .order_by(Job.inferred_experience)
        )
        exp_res = await session.execute(exp_stmt)
        experience_levels = [e for e in exp_res.scalars().all() if e]

        # Preferred ordering for experience levels
        order_map = {"intern": 0, "entry": 1, "mid": 2, "senior": 3, "lead": 4}
        experience_levels.sort(key=lambda x: order_map.get(x.lower(), 99))

        # Cities
        cities_stmt = (
            select(Job.inferred_city)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.inferred_city.isnot(None),
                    Job.inferred_city != "",
                )
            )
            .order_by(Job.inferred_city)
        )
        cities_res = await session.execute(cities_stmt)
        cities = [c for c in cities_res.scalars().all() if c]

        # Sources
        sources_stmt = (
            select(Job.source_name)
            .distinct()
            .where(
                and_(
                    status_filter,
                    Job.source_name.isnot(None),
                    Job.source_name != "",
                )
            )
            .order_by(Job.source_name)
        )
        sources_res = await session.execute(sources_stmt)
        sources = [s for s in sources_res.scalars().all() if s]

        # Total count
        count_stmt = select(func.count(Job.id)).where(status_filter)
        total_res = await session.execute(count_stmt)
        total_jobs = total_res.scalar() or 0

        return {
            "roles": roles,
            "work_modes": work_modes,
            "job_types": job_types,
            "experience_levels": experience_levels,
            "cities": cities,
            "sources": sources,
            "total_jobs": total_jobs,
        }

    async def get_stats(self, session: AsyncSession) -> dict:
        """Compute aggregated dataset metrics and ETL pipeline status counts."""
        # Status counts
        status_stmt = select(Job.etl_status, func.count(Job.id)).group_by(Job.etl_status)
        status_res = await session.execute(status_stmt)
        status_counts = {str(row[0].value if hasattr(row[0], "value") else row[0]): row[1] for row in status_res.all()}

        total_jobs = sum(status_counts.values())
        published_jobs = status_counts.get("PUBLISHED", 0)
        raw_jobs = status_counts.get("RAW", 0)
        processing_jobs = status_counts.get("PROCESSING", 0)
        failed_jobs = status_counts.get("FAILED", 0)

        # By Work Mode
        mode_stmt = (
            select(Job.inferred_work_mode, func.count(Job.id))
            .where(Job.inferred_work_mode.isnot(None))
            .group_by(Job.inferred_work_mode)
        )
        mode_res = await session.execute(mode_stmt)
        by_work_mode = {str(row[0]): row[1] for row in mode_res.all()}

        # By Source
        source_stmt = select(Job.source_name, func.count(Job.id)).group_by(Job.source_name)
        source_res = await session.execute(source_stmt)
        by_source = {str(row[0]): row[1] for row in source_res.all()}

        # Total Tokens & Cost
        cost_stmt = select(
            func.coalesce(func.sum(Job.llm_cost_usd), 0.0),
            func.coalesce(func.sum(Job.llm_input_tokens), 0),
            func.coalesce(func.sum(Job.llm_output_tokens), 0),
        )
        cost_res = await session.execute(cost_stmt)
        cost_row = cost_res.one()
        total_cost = float(cost_row[0]) if cost_row[0] is not None else 0.0
        total_tokens = int(cost_row[1] or 0) + int(cost_row[2] or 0)

        return {
            "total_jobs": total_jobs,
            "published_jobs": published_jobs,
            "raw_jobs": raw_jobs,
            "processing_jobs": processing_jobs,
            "failed_jobs": failed_jobs,
            "by_work_mode": by_work_mode,
            "by_source": by_source,
            "total_llm_cost_usd": round(total_cost, 6),
            "total_tokens": total_tokens,
        }
