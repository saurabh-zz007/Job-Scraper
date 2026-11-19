import json
import re

from core.settings import settings
from openai import AsyncOpenAI
from llm_tagging.schemas import LLMJobInput, LLMInferedFields, LLMUsageMetrics

class LLMIngestion:
    def __init__(self):
        self.client = AsyncOpenAI(
            api_key = settings.DEEPSEEK_API_KEY,
            base_url = settings.DEEPSEEK_URL,
            timeout = 30.0
        )
        self.SYSTEM_PROMPT="""
        You are a technical job data extractor. Analyze the job title, location, and description, and return ONLY valid JSON matching this exact schema:
        {
        "inferred_city": string or null,
        "inferred_job_type": "full-time" | "part-time" | "contract" | "internship" | "unknown",
        "inferred_experience": "intern" | "entry" | "mid" | "senior" | "lead" | "unknown",
        "inferred_work_mode": "remote" | "hybrid" | "onsite" | "unknown",
        "inferred_skills": ["skill1", "skill2"],
        "inferred_role": string
        }

        Rules:
        - Normalize skill names (e.g., "React.js" -> "React", "Postgres" -> "PostgreSQL").
        - Keep inferred_skills concise (max 15 core technical skills).
        - If a field cannot be determined from the text, use "unknown" (or null for inferred_city).
        """

    def _calculate_cost(self, prompt_tokens: int, completion_tokens: int) -> float:
        input_cost_per_1M = settings.LLM_INPUT_COST_PER_1M
        output_cost_per_1M = settings.LLM_OUTPUT_COST_PER_1M

        input_cost = (prompt_tokens / 1_000_000) * input_cost_per_1M
        output_cost = (completion_tokens / 1_000_000) * output_cost_per_1M

        return round(input_cost + output_cost, 6)
        
    async def extract_llm_tags(self, job_data: LLMJobInput) -> tuple[LLMInferedFields, LLMUsageMetrics]:
        user_content = (
            f"Job Title: {job_data.title}\n"
            f"Raw Location: {job_data.location or 'Not specified'}\n"
            f"Description:\n{job_data.description[:12000]}"  # Guard against unusually massive JDs
        )

        response = await self.client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=[
                {"role": "system", "content": self.SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            response_format={"type": "json_object"},
            temperature=0.0,  # Deterministic extraction
        )

        raw_content = response.choices[0].message.content or "{}"
        
        # 1. Strip markdown fences like ```json ... ``` 
        cleaned_json = raw_content.strip()
        if cleaned_json.startswith("```"):
            cleaned_json = re.sub(r"^```(?:json)?\s*", "", cleaned_json)
            cleaned_json = re.sub(r"\s*```$", "", cleaned_json)
            cleaned_json = cleaned_json.strip()
        # 2. Safe parse with fallback
        try:
            parsed_data = json.loads(cleaned_json)
        except json.JSONDecodeError:
            parsed_data = {}
        # 3. Validated with forgiving pre-validators
        inferred = LLMInferedFields.model_validate(parsed_data)
        prompt_tokens = response.usage.prompt_tokens if response.usage else 0
        completion_tokens = response.usage.completion_tokens if response.usage else 0
        usage_metrics = LLMUsageMetrics(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_cost=self._calculate_cost(prompt_tokens, completion_tokens),
        )
        return inferred, usage_metrics