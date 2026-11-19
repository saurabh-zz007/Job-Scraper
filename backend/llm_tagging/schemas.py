from uuid import UUID
from pydantic import BaseModel, Field, field_validator
from typing import Literal
from datetime import datetime
from decimal import Decimal
from typing import Any


from core.models import JobStatus

JOB_TYPE_MAP = {
    "full-time": "full-time",
    "fulltime": "full-time",
    "full_time": "full-time",
    "ft": "full-time",
    "permanent": "full-time",
    "part-time": "part-time",
    "parttime": "part-time",
    "part_time": "part-time",
    "pt": "part-time",
    "contract": "contract",
    "contractor": "contract",
    "temporary": "contract",
    "freelance": "contract",
    "internship": "internship",
    "intern": "internship",
    "co-op": "internship",
    "coop": "internship",
}
EXPERIENCE_MAP = {
    "intern": "intern",
    "internship": "intern",
    "entry": "entry",
    "entry-level": "entry",
    "entry_level": "entry",
    "fresher": "entry",
    "junior": "entry",
    "associate": "entry",
    "mid": "mid",
    "mid-level": "mid",
    "mid_level": "mid",
    "intermediate": "mid",
    "senior": "senior",
    "sr": "senior",
    "sr.": "senior",
    "lead": "lead",
    "principal": "lead",
    "staff": "lead",
}
WORK_MODE_MAP = {
    "remote": "remote",
    "wfh": "remote",
    "work from home": "remote",
    "hybrid": "hybrid",
    "flexible": "hybrid",
    "onsite": "onsite",
    "on-site": "onsite",
    "on_site": "onsite",
    "in-office": "onsite",
    "office": "onsite",
}

class LLMJobInput(BaseModel):
    job_id: UUID
    title: str
    location: str| None = None
    description: str

class LLMInferedFields(BaseModel):
    inferred_city: str | None = Field(
        default=None
    )
    inferred_job_type: Literal["full-time", "part-time", "contract", "internship", "unknown"] = "unknown"
    inferred_experience: Literal["intern", "entry", "mid", "senior", "lead", "unknown"] = "unknown"
    inferred_work_mode: Literal["remote", "hybrid", "onsite", "unknown"] = "unknown"
    inferred_skills: list[str] = Field(
        default_factory=list, description="Normalized technical skills, languages, and frameworks"
    )
    inferred_role: str = Field(
        default="other"
    )

    @field_validator("inferred_city", mode="before")
    @classmethod
    def clean_city(cls, v: Any) -> str | None:
        if not v or not isinstance(v, str):
            return None
        cleaned = v.strip()
        if cleaned.lower() in ("null", "none", "n/a", "unknown", "undefined", ""):
            return None
        return cleaned
    @field_validator("inferred_job_type", mode="before")
    @classmethod
    def normalize_job_type(cls, v: Any) -> str:
        if not v or not isinstance(v, str):
            return "unknown"
        val = str(v).strip().lower()
        return JOB_TYPE_MAP.get(val, "unknown")
    @field_validator("inferred_experience", mode="before")
    @classmethod
    def normalize_experience(cls, v: Any) -> str:
        if not v or not isinstance(v, str):
            return "unknown"
        val = str(v).strip().lower()
        return EXPERIENCE_MAP.get(val, "unknown")
    @field_validator("inferred_work_mode", mode="before")
    @classmethod
    def normalize_work_mode(cls, v: Any) -> str:
        if not v or not isinstance(v, str):
            return "unknown"
        val = str(v).strip().lower()
        return WORK_MODE_MAP.get(val, "unknown")
    @field_validator("inferred_skills", mode="before")
    @classmethod
    def normalize_skills(cls, v: Any) -> list[str]:
        if not v:
            return []
        if isinstance(v, str):
            # In case LLM returns comma-separated string instead of a list
            return [s.strip() for s in v.split(",") if s.strip()]
        if isinstance(v, list):
            return [str(s).strip() for s in v if s and str(s).strip()]
        return []
    @field_validator("inferred_role", mode="before")
    @classmethod
    def normalize_role(cls, v: Any) -> str:
        if not v or not isinstance(v, str):
            return "other"
        cleaned = str(v).strip()
        return cleaned if cleaned else "other"

class LLMUsageMetrics(BaseModel):
    prompt_tokens: int
    completion_tokens: int
    total_cost: float

class RuleBasedEnrichmentResult(BaseModel):
    """
    Maps directly onto your SQLAlchemy Job model columns on a successful tagging run.
    Use `result.model_dump()` inside SQLAlchemy `update(Job).values(**result.model_dump())`.
    """

    # Classification & Model Metadata
    classification_confidence: float
    llm_model: str
    prompt_version: str

    # Processing State
    etl_status: JobStatus
    processing_attempts: int
    last_error: str | None = None

    # Cost Tracking (Decimal matches Numeric(12, 8))
    llm_input_tokens: int
    llm_output_tokens: int
    llm_cost_usd: Decimal

    # Job Lifecycle
    posted_at: datetime | None = None
    last_seen_at: datetime
    classified_at: datetime
