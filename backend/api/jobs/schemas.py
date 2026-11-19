from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class JobResponse(BaseModel):
    """Full Job response schema matching PostgreSQL model and Flutter frontend JobModel."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    source_url: str
    source_name: str
    source_id: str | None = None
    company_name: str
    raw_title: str
    raw_location: str | None = None
    description: str
    raw_payload: dict[str, Any] | None = None
    content_hash: str

    # LLM Enriched Fields
    inferred_role: str | None = None
    inferred_city: str | None = None
    inferred_job_type: str | None = None
    inferred_experience: str | None = None
    inferred_work_mode: str | None = None
    inferred_skills: list[str] = Field(default_factory=list)

    classification_confidence: float | None = None
    llm_model: str | None = None
    prompt_version: str | None = None

    # Processing State
    etl_status: str
    processing_attempts: int = 0
    last_error: str | None = None

    # Token and Cost Tracking
    llm_input_tokens: int | None = None
    llm_output_tokens: int | None = None
    llm_cost_usd: float | None = None

    # Timestamps
    posted_at: datetime | None = None
    last_seen_at: datetime | None = None
    classified_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class JobListResponse(BaseModel):
    """Paginated list of jobs."""
    total: int
    page: int
    limit: int
    total_pages: int
    items: list[JobResponse]


class JobFilterOptionsResponse(BaseModel):
    """Dynamic filter choices aggregated directly from the database."""
    roles: list[str]
    work_modes: list[str]
    job_types: list[str]
    experience_levels: list[str]
    cities: list[str]
    sources: list[str]
    total_jobs: int


class JobStatsResponse(BaseModel):
    """Ingestion pipeline and dataset statistics."""
    total_jobs: int
    published_jobs: int
    raw_jobs: int
    processing_jobs: int
    failed_jobs: int
    by_work_mode: dict[str, int]
    by_source: dict[str, int]
    total_llm_cost_usd: float
    total_tokens: int

