import logging
from datetime import datetime
import httpx

from data_collection.scrapers.base import BaseScraper
from data_collection.schemas import RawJob

logger = logging.getLogger(__name__)

class GreenhouseScraper(BaseScraper):
    """
    Scraper for job boards hosted on Greenhouse.
    API endpoint: https://boards-api.greenhouse.io/v1/boards/{board_id}/jobs?content=true
    """

    def __init__(self, board_id: str, company_name: str | None = None):
        super().__init__(board_id, company_name)
        self.endpoint = f"https://boards-api.greenhouse.io/v1/boards/{self.board_id}/jobs?content=true"

    async def fetch_and_normalize(self) -> list[RawJob]:
        normalized_jobs: list[RawJob] = []

        async with httpx.AsyncClient(timeout=20.0) as client:
            try:
                response = await client.get(self.endpoint)
                response.raise_for_status()
            except httpx.HTTPError as exc:
                logger.error(
                    "HTTP error fetching Greenhouse jobs for board '%s': %s",
                    self.board_id,
                    exc
                )
                return []
            except Exception as exc:
                logger.error(
                    "Unexpected error fetching Greenhouse jobs for board '%s': %s",
                    self.board_id,
                    exc
                )
                return []

        try:
            payload = response.json()
        except Exception as exc:
            logger.error(
                "Failed to parse JSON response from Greenhouse for board '%s': %s",
                self.board_id,
                exc
            )
            return []

        jobs_list = payload.get("jobs", [])
        for item in jobs_list:
            try:
                source_id = str(item["id"]) if item.get("id") is not None else None
                source_url = item.get("absolute_url") or ""
                company = item.get("company_name") or self.company_name or self.board_id.capitalize()
                raw_title = item.get("title") or ""

                location_val = item.get("location")
                raw_location = None
                if isinstance(location_val, dict):
                    raw_location = location_val.get("name")
                elif isinstance(location_val, str):
                    raw_location = location_val

                # Map HTML description directly (RawJob validator handles stripping and normalizing)
                description = item.get("content") or ""

                # Parse timestamp if available
                posted_at = None
                date_str = item.get("updated_at") or item.get("first_published")
                if date_str:
                    try:
                        posted_at = datetime.fromisoformat(date_str)
                    except (ValueError, TypeError):
                        posted_at = None

                job = RawJob(
                    source_name="Greenhouse",
                    source_id=source_id,
                    source_url=source_url,
                    company_name=company,
                    raw_title=raw_title,
                    raw_location=raw_location,
                    description=description,
                    posted_at=posted_at
                )
                normalized_jobs.append(job)
            except Exception as item_err:
                logger.warning(
                    "Skipping malformed Greenhouse job item on board '%s': %s",
                    self.board_id,
                    item_err
                )
                continue

        logger.info(
            "Successfully fetched and normalized %d jobs from Greenhouse board '%s'",
            len(normalized_jobs),
            self.board_id
        )
        return normalized_jobs

