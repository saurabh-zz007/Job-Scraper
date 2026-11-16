import logging
from datetime import datetime, timezone
import httpx

from data_collection.scrapers.base import BaseScraper
from data_collection.schemas import RawJob

logger = logging.getLogger(__name__)

class LeverScraper(BaseScraper):
    """
    Scraper for job boards hosted on Lever.
    API endpoint: https://api.lever.co/v0/postings/{board_id}?mode=json
    """

    def __init__(self, board_id: str, company_name: str | None = None):
        super().__init__(board_id, company_name)
        self.endpoint = f"https://api.lever.co/v0/postings/{self.board_id}?mode=json"

    async def fetch_and_normalize(self) -> list[RawJob]:
        normalized_jobs: list[RawJob] = []

        async with httpx.AsyncClient(timeout=20.0) as client:
            try:
                response = await client.get(self.endpoint)
                response.raise_for_status()
            except httpx.HTTPError as exc:
                logger.error(
                    "HTTP error fetching Lever jobs for board '%s': %s",
                    self.board_id,
                    exc
                )
                return []
            except Exception as exc:
                logger.error(
                    "Unexpected error fetching Lever jobs for board '%s': %s",
                    self.board_id,
                    exc
                )
                return []

        try:
            postings = response.json()
        except Exception as exc:
            logger.error(
                "Failed to parse JSON response from Lever for board '%s': %s",
                self.board_id,
                exc
            )
            return []

        if not isinstance(postings, list):
            logger.warning(
                "Expected list of postings from Lever for board '%s', received %s",
                self.board_id,
                type(postings)
            )
            return []

        for item in postings:
            try:
                source_id = str(item["id"]) if item.get("id") is not None else None
                source_url = (
                    item.get("hostedUrl")
                    or item.get("applyUrl")
                    or f"https://jobs.lever.co/{self.board_id}/{source_id}"
                )
                company = self.company_name or self.board_id.capitalize()
                raw_title = item.get("text") or ""

                categories = item.get("categories") or {}
                raw_location = categories.get("location") if isinstance(categories, dict) else None

                # Assemble HTML description payload directly
                description_parts = []
                if item.get("description"):
                    description_parts.append(str(item.get("description")))
                
                # Append list sections if present (e.g., What You'll Do, Who You Are)
                lists = item.get("lists") or []
                if isinstance(lists, list):
                    for section in lists:
                        if isinstance(section, dict):
                            header = section.get("text") or ""
                            content = section.get("content") or ""
                            description_parts.append(f"<div><h3>{header}</h3>{content}</div>")

                if item.get("additional"):
                    description_parts.append(f"<div>{item.get('additional')}</div>")

                description = " ".join(description_parts)

                # Parse Unix timestamp in milliseconds
                posted_at = None
                created_at = item.get("createdAt")
                if isinstance(created_at, (int, float)):
                    try:
                        posted_at = datetime.fromtimestamp(created_at / 1000.0, tz=timezone.utc)
                    except (ValueError, OSError, OverflowError):
                        posted_at = None

                job = RawJob(
                    source_name="Lever",
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
                    "Skipping malformed Lever job item on board '%s': %s",
                    self.board_id,
                    item_err
                )
                continue

        logger.info(
            "Successfully fetched and normalized %d jobs from Lever board '%s'",
            len(normalized_jobs),
            self.board_id
        )
        return normalized_jobs

