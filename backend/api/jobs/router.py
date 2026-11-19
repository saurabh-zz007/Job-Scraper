from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db import get_db
from api.jobs.schemas import (
    JobListResponse,
    JobResponse,
    JobFilterOptionsResponse,
    JobStatsResponse,
)
from api.jobs.service import JobService

router = APIRouter(prefix="/jobs", tags=["Jobs Feed & Filters"])
job_service = JobService()


@router.get(
    "",
    response_model=JobListResponse,
    status_code=status.HTTP_200_OK,
    summary="List Jobs with Filters & Search",
    description=(
        "Retrieve a paginated, filtered, and sorted list of tech jobs. "
        "Supports full-text keyword search across titles, companies, and JSONB inferred skills, "
        "multi-select category filters, and sorting by newest or AI classification confidence."
    ),
)
async def list_jobs_endpoint(
    search: str | None = Query(
        None,
        description="Search term matching title, company name, or extracted skills",
    ),
    roles: list[str] | None = Query(
        None,
        description="Role categories (multi-select, e.g. 'Backend Engineer', 'DevOps / SRE')",
    ),
    work_modes: list[str] | None = Query(
        None,
        description="Work modes (e.g. 'remote', 'hybrid', 'onsite')",
    ),
    job_types: list[str] | None = Query(
        None,
        description="Job types (e.g. 'full-time', 'contract', 'internship')",
    ),
    experience_levels: list[str] | None = Query(
        None,
        description="Experience levels (e.g. 'intern', 'entry', 'mid', 'senior', 'lead')",
    ),
    cities: list[str] | None = Query(
        None,
        description="City locations (e.g. 'San Francisco', 'New York', 'London')",
    ),
    sources: list[str] | None = Query(
        None,
        description="ATS job board sources (e.g. 'Greenhouse', 'Lever', 'Ashby')",
    ),
    etl_status: str | None = Query(
        "PUBLISHED",
        description="ETL state filter (default: 'PUBLISHED', or pass 'ALL' for every state)",
    ),
    sort_by: str = Query(
        "newest",
        description="Sort by 'newest' (posted date descending) or 'confidence' (match % descending)",
    ),
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    limit: int = Query(20, ge=1, le=100, description="Items per page (max 100)"),
    db: AsyncSession = Depends(get_db),
) -> JobListResponse:
    """Fetch paginated, filtered jobs."""
    return await job_service.list_jobs(
        session=db,
        search=search,
        roles=roles,
        work_modes=work_modes,
        job_types=job_types,
        experience_levels=experience_levels,
        cities=cities,
        sources=sources,
        etl_status=etl_status,
        sort_by=sort_by,
        page=page,
        limit=limit,
    )


@router.get(
    "/filters",
    response_model=JobFilterOptionsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Dynamic Filter Options",
    description=(
        "Fetch distinct available values across all filter dimensions (roles, work modes, "
        "job types, experience levels, cities, ATS sources) computed directly from published database records."
    ),
)
async def get_filters_endpoint(
    db: AsyncSession = Depends(get_db),
) -> JobFilterOptionsResponse:
    """Fetch all unique filter values currently available in the dataset."""
    return await job_service.get_filter_options(session=db)


@router.get(
    "/stats",
    response_model=JobStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Pipeline & Dataset Metrics",
    description="Fetch aggregated statistics on ingestion status, work mode distributions, LLM cost, and tokens.",
)
async def get_stats_endpoint(
    db: AsyncSession = Depends(get_db),
) -> JobStatsResponse:
    """Fetch dataset and ingestion health stats."""
    return await job_service.get_stats(session=db)


@router.get(
    "/{job_id}",
    response_model=JobResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Job by ID",
    description="Fetch full details for a single job listing by its UUID.",
)
async def get_job_endpoint(
    job_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> JobResponse:
    """Fetch single job details."""
    return await job_service.get_job(session=db, job_id=job_id)

