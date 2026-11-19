from uuid import UUID
from fastapi import APIRouter, Depends, Query, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from core.db import get_db
from admin.schemas import (
    DashboardMetricsResponse,
    PaginatedJobsResponse,
    JobDetailResponse,
    BulkActionResponse,
    RetryFailedRequest,
)
from admin.service import AdminService

router = APIRouter(tags=["Admin Operations Console"])
admin_service = AdminService()


@router.get(
    "/dashboard",
    response_model=DashboardMetricsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Admin Dashboard Metrics",
    description="Returns live pipeline state, funnel progression, LLM spend, token economics, and quality stats.",
)
async def get_dashboard_endpoint(
    db: AsyncSession = Depends(get_db),
) -> DashboardMetricsResponse:
    return await admin_service.get_dashboard_metrics(db)


@router.get(
    "/jobs",
    response_model=PaginatedJobsResponse,
    status_code=status.HTTP_200_OK,
    summary="List Jobs for Admin Console",
    description="Paginated list of jobs with filters for status, source, company/title search, and max confidence.",
)
async def list_admin_jobs_endpoint(
    page: int = Query(1, ge=1, description="Page number starting at 1"),
    page_size: int = Query(25, ge=1, le=100, description="Items per page"),
    etl_status: str | None = Query(None, description="Status filter (RAW, FILTERED, CLASSIFIED, FAILED, ALL)"),
    source_name: str | None = Query(None, description="ATS source filter"),
    search: str | None = Query(None, description="Company or title keyword search"),
    max_confidence: float | None = Query(None, description="Upper bound for classification confidence"),
    db: AsyncSession = Depends(get_db),
) -> PaginatedJobsResponse:
    return await admin_service.list_jobs(
        db=db,
        page=page,
        page_size=page_size,
        etl_status=etl_status,
        source_name=source_name,
        search=search,
        max_confidence=max_confidence,
    )


@router.post(
    "/jobs/retry-failed",
    response_model=BulkActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Retry Failed Jobs",
    description="Resets failed jobs to PROCESSING state and re-enqueues them into the LLM queue.",
)
async def retry_failed_jobs_endpoint(
    payload: RetryFailedRequest | None = None,
    db: AsyncSession = Depends(get_db),
) -> BulkActionResponse:
    job_ids = payload.job_ids if payload else None
    count = await admin_service.retry_failed_jobs(db, job_ids)
    return BulkActionResponse(
        affected_count=count,
        message=f"Successfully re-enqueued {count} failed jobs into the LLM processing queue.",
    )


@router.post(
    "/jobs/reclassify",
    response_model=BulkActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Reclassify Jobs",
    description="Re-enqueues published jobs for fresh LLM tagging by prompt version or max confidence threshold.",
)
async def reclassify_jobs_endpoint(
    prompt_version: str | None = Query(None, description="Only reclassify jobs processed with a different prompt version"),
    max_confidence: float | None = Query(None, description="Upper confidence threshold for reclassification"),
    db: AsyncSession = Depends(get_db),
) -> BulkActionResponse:
    count = await admin_service.reclassify_jobs(db, prompt_version, max_confidence)
    return BulkActionResponse(
        affected_count=count,
        message=f"Successfully re-enqueued {count} jobs for reclassification.",
    )


@router.delete(
    "/jobs/purge",
    response_model=BulkActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Purge Jobs with Guardrail",
    description="Controlled purge requiring status filter or age in days.",
)
async def purge_jobs_endpoint(
    etl_status: str | None = Query(None, description="Status filter (e.g. FAILED, DUPLICATE)"),
    older_than_days: int | None = Query(None, ge=1, description="Purge rows older than N days"),
    db: AsyncSession = Depends(get_db),
) -> BulkActionResponse:
    count = await admin_service.purge_jobs(db, etl_status, older_than_days)
    return BulkActionResponse(
        affected_count=count,
        message=f"Successfully purged {count} matching job records.",
    )


@router.delete(
    "/jobs/{job_id}",
    response_model=BulkActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete Single Job",
    description="Permanently deletes a single job record by UUID.",
)
async def delete_job_endpoint(
    job_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> BulkActionResponse:
    deleted = await admin_service.delete_single_job(db, job_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID '{job_id}' not found.",
        )
    return BulkActionResponse(
        affected_count=1,
        message=f"Job '{job_id}' deleted successfully.",
    )


@router.get(
    "/jobs/{job_id}",
    response_model=JobDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Job Detail for Inspection",
    description="Returns complete job record including description, raw JSON payload, tokens, and errors.",
)
async def get_job_detail_endpoint(
    job_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> JobDetailResponse:
    detail = await admin_service.get_job_detail(db, job_id)
    if not detail:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID '{job_id}' not found.",
        )
    return detail


@router.post(
    "/pipeline/trigger",
    response_model=BulkActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Trigger Pipeline Batch Ingestion",
    description="Triggers the background scrapers and ETL pipeline ingestion process.",
)
async def trigger_pipeline_endpoint() -> BulkActionResponse:
    res = await admin_service.trigger_batch_in_background()
    return BulkActionResponse(
        affected_count=1 if res.get("batch_running") else 0,
        message=res.get("message", "Pipeline triggered."),
    )
