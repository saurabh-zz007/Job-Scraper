from datetime import datetime
from typing import Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class PipelineLiveStatus(BaseModel):
    batch_running: bool
    llm_queue_depth: int


class FunnelMetrics(BaseModel):
    total_jobs: int
    raw: int
    filtered_pending_llm: int
    classified: int
    failed: int


class LLMEconomics(BaseModel):
    total_cost_usd: float
    cost_last_24h_usd: float
    avg_cost_per_job_usd: float
    total_input_tokens: int
    total_output_tokens: int


class QualityMetrics(BaseModel):
    avg_confidence: float
    low_confidence_jobs: int
    stale_jobs_over_14d: int


class SourceMetric(BaseModel):
    source_name: str
    total: int
    classified: int
    failed: int
    avg_confidence: float


class PromptVersionMetric(BaseModel):
    llm_model: str | None = None
    prompt_version: str | None = None
    jobs_processed: int
    avg_confidence: float
    avg_cost_usd: float


class TopErrorMetric(BaseModel):
    error: str
    count: int


class DashboardMetricsResponse(BaseModel):
    pipeline_live: PipelineLiveStatus
    funnel: FunnelMetrics
    llm_economics: LLMEconomics
    quality: QualityMetrics
    by_source: list[SourceMetric]
    by_prompt_version: list[PromptVersionMetric]
    top_errors: list[TopErrorMetric]


class JobListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    company_name: str
    raw_title: str
    raw_location: str | None = None
    source_name: str
    etl_status: str
    inferred_role: str | None = None
    inferred_city: str | None = None
    inferred_work_mode: str | None = None
    inferred_experience: str | None = None
    classification_confidence: float | None = None
    processing_attempts: int = 0
    llm_cost_usd: float | None = None
    last_error: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class PaginatedJobsResponse(BaseModel):
    items: list[JobListItem]
    total: int
    page: int
    page_size: int
    total_pages: int


class JobDetailResponse(JobListItem):
    source_url: str
    description: str
    raw_payload: dict[str, Any] | None = None
    inferred_job_type: str | None = None
    inferred_skills: list[str] = Field(default_factory=list)
    llm_model: str | None = None
    prompt_version: str | None = None
    llm_input_tokens: int | None = None
    llm_output_tokens: int | None = None
    posted_at: datetime | None = None
    last_seen_at: datetime | None = None
    classified_at: datetime | None = None


class BulkActionResponse(BaseModel):
    affected_count: int
    message: str


class RetryFailedRequest(BaseModel):
    job_ids: list[UUID] | None = None

