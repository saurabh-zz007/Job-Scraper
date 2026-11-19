from llm_tagging.schemas import LLMInferedFields, LLMJobInput, LLMUsageMetrics, RuleBasedEnrichmentResult
from core.models import JobStatus
from datetime import datetime, timezone
from decimal import Decimal

class RuleBasedEnricher:
    def __init__(
        self,
        llm_model: str,
        prompt_version: str = "v1.0.0",
        max_attempts: int = 3
    )->None:
        self.llm_model = llm_model
        self.prompt_version = prompt_version
        self.max_attempts = max_attempts

    def calculate_confidence(
        self,
        llm_fields: LLMInferedFields,
        description_length: int,
    ) -> float:
        score = 0.0

        # 1. Role category (0.25)
        if llm_fields.inferred_role not in ("other", "unknown", ""):
            score += 0.25

        # 2. Skills richness (0.25)
        skill_count = len(llm_fields.inferred_skills)
        if skill_count >= 3:
            score += 0.25
        elif skill_count >= 1:
            score += 0.15

        # 3. Experience level (0.20)
        if llm_fields.inferred_experience != "unknown":
            score += 0.20

        # 4. Work mode (0.15)
        if llm_fields.inferred_work_mode != "unknown":
            score += 0.15

        # 5. Job type (0.10)
        if llm_fields.inferred_job_type != "unknown":
            score += 0.10

        # 6. Location / Remote clarity (0.05)
        if llm_fields.inferred_city or llm_fields.inferred_work_mode == "remote":
            score += 0.05

        # Penalize thin/stub descriptions
        if description_length < 150:
            score *= 0.7

        return round(min(score, 1.0), 2)

    def build_rule_based_payload(
        self,
        job_data: LLMJobInput,
        llm_fields: LLMInferedFields,
        usage: LLMUsageMetrics,
        current_attempts: int = 0,
        posted_at: datetime | None = None,
    ) -> RuleBasedEnrichmentResult:
        """
        Builds the complete rule-based + metadata update dictionary for a successfully classified job.
        """
        now = datetime.now(timezone.utc)
        confidence = self.calculate_confidence(
            llm_fields=llm_fields,
            description_length=len(job_data.description or ""),
        )

        # Quantize float cost to exact 8 decimal places for Numeric(12, 8)
        cost_decimal = Decimal(str(usage.total_cost)).quantize(Decimal("0.00000001"))

        return RuleBasedEnrichmentResult(
            classification_confidence=confidence,
            llm_model=self.llm_model,
            prompt_version=self.prompt_version,
            etl_status=JobStatus.PUBLISHED,
            processing_attempts=current_attempts + 1,
            last_error=None,
            llm_input_tokens=usage.prompt_tokens,
            llm_output_tokens=usage.completion_tokens,
            llm_cost_usd=cost_decimal,
            posted_at=posted_at,
            last_seen_at=now,
            classified_at=now,
        )
