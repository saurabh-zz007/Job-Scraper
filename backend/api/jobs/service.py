import math
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import JobStatus
from api.jobs.repository import JobRepository
from api.jobs.schemas import (
    JobListResponse,
    JobResponse,
    JobFilterOptionsResponse,
    JobStatsResponse,
)


def _parse_multi_param(param_list: list[str] | None) -> list[str]:
    """Helper to split comma-separated strings inside query param lists."""
    if not param_list:
        return []
    result = []
    for item in param_list:
        if not item:
            continue
        for part in item.split(","):
            cleaned = part.strip()
            if cleaned:
                result.append(cleaned)
    return result


class JobService:
    """Business logic service for the Job domain."""

    def __init__(self, repository: JobRepository | None = None) -> None:
        self.repository = repository or JobRepository()

    async def list_jobs(
        self,
        session: AsyncSession,
        search: str | None = None,
        roles: list[str] | None = None,
        work_modes: list[str] | None = None,
        job_types: list[str] | None = None,
        experience_levels: list[str] | None = None,
        cities: list[str] | None = None,
        sources: list[str] | None = None,
        etl_status: str | None = "PUBLISHED",
        sort_by: str = "newest",
        page: int = 1,
        limit: int = 20,
    ) -> JobListResponse:
        """Fetch filtered and paginated job postings."""
        if page < 1:
            page = 1
        if limit < 1:
            limit = 20
        elif limit > 100:
            limit = 100

        skip = (page - 1) * limit

        # Parse possible comma-separated lists
        parsed_roles = _parse_multi_param(roles)
        parsed_modes = _parse_multi_param(work_modes)
        parsed_types = _parse_multi_param(job_types)
        parsed_exp = _parse_multi_param(experience_levels)
        parsed_cities = _parse_multi_param(cities)
        parsed_sources = _parse_multi_param(sources)

        # Parse etl_status enum if provided
        status_enum: JobStatus | None = None
        if etl_status:
            clean_status = etl_status.strip().upper()
            if clean_status in JobStatus.__members__:
                status_enum = JobStatus[clean_status]
            elif clean_status.lower() != "all":
                status_enum = JobStatus.PUBLISHED

        # Normalize sort_by
        clean_sort = "confidence" if sort_by and sort_by.strip().lower() == "confidence" else "newest"

        items, total = await self.repository.get_jobs(
            session=session,
            search=search,
            roles=parsed_roles,
            work_modes=parsed_modes,
            job_types=parsed_types,
            experience_levels=parsed_exp,
            cities=parsed_cities,
            sources=parsed_sources,
            etl_status=status_enum,
            sort_by=clean_sort,
            skip=skip,
            limit=limit,
        )

        total_pages = math.ceil(total / limit) if total > 0 else 0

        return JobListResponse(
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
            items=[JobResponse.model_validate(item) for item in items],
        )

    async def get_job(
        self,
        session: AsyncSession,
        job_id: UUID,
    ) -> JobResponse:
        """Fetch single job detail by ID."""
        job = await self.repository.get_job_by_id(session, job_id)
        if not job:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job with ID '{job_id}' not found.",
            )
        return JobResponse.model_validate(job)

    async def get_filter_options(
        self,
        session: AsyncSession,
    ) -> JobFilterOptionsResponse:
        """Fetch distinct filter options for the frontend sidebar."""
        data = await self.repository.get_filter_options(session, etl_status=JobStatus.PUBLISHED)
        return JobFilterOptionsResponse(**data)

    async def get_stats(
        self,
        session: AsyncSession,
    ) -> JobStatsResponse:
        """Fetch ingestion stats and dataset metrics."""
        data = await self.repository.get_stats(session)
        return JobStatsResponse(**data)

