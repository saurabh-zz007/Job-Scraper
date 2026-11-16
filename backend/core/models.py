import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, Text, Integer, DateTime, Enum, Float, Numeric
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID, JSONB

class Base(DeclarativeBase):
    """Base class for all SQLAlchemy 2.0 models."""
    pass

class JobStatus(str, enum.Enum):
    """ETL Pipeline states for the job record."""
    RAW = "RAW"
    PROCESSING = "PROCESSING"
    PUBLISHED = "PUBLISHED"
    FAILED = "FAILED"
    DUPLICATE = "DUPLICATE"


class Job(Base):
    __tablename__ = "jobs"

    # Primary Key
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    # Raw Scraped Data
    source_url: Mapped[str] = mapped_column(
        String, unique=True, index=True, nullable=False
    )
    source_name: Mapped[str] = mapped_column(String, nullable=False)
    source_id: Mapped[str | None] = mapped_column(String, nullable=True)
    company_name: Mapped[str] = mapped_column(String, nullable=False)
    raw_title: Mapped[str] = mapped_column(String, nullable=False)
    raw_location: Mapped[str | None] = mapped_column(String)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    raw_payload: Mapped[dict | None] = mapped_column(JSONB)

    # Deduplication
    content_hash: Mapped[str] = mapped_column(
        String, index=True, nullable=False
    )

    # LLM Enriched Data
    inferred_role: Mapped[str | None] = mapped_column(String)
    inferred_city: Mapped[str | None] = mapped_column(String)
    inferred_job_type: Mapped[str | None] = mapped_column(String)
    inferred_experience: Mapped[str | None] = mapped_column(String)
    inferred_work_mode: Mapped[str | None] = mapped_column(String)
    inferred_skills: Mapped[list | None] = mapped_column(JSONB)

    classification_confidence: Mapped[float | None] = mapped_column(Float)
    llm_model: Mapped[str | None] = mapped_column(String)
    prompt_version: Mapped[str | None] = mapped_column(String)

    # Processing State
    etl_status: Mapped[JobStatus] = mapped_column(
        Enum(JobStatus), default=JobStatus.RAW, nullable=False
    )
    processing_attempts: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    last_error: Mapped[str | None] = mapped_column(Text)

    # Cost Tracking
    llm_input_tokens: Mapped[int | None] = mapped_column(Integer)
    llm_output_tokens: Mapped[int | None] = mapped_column(Integer)
    llm_cost_usd: Mapped[Decimal | None] = mapped_column(Numeric(12, 8))

    # Job Lifecycle
    posted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    classified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
