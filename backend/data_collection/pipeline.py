import asyncio
import hashlib
import logging
from typing import Any

from core.models import Job
from data_collection.scrapers.base import BaseScraper
from data_collection.scrapers.greenhouse import GreenhouseScraper
from data_collection.scrapers.lever import LeverScraper
from data_collection.schemas import RawJob

# TODO: Replace it with Redis Queue
from data_filtering.synthetic_router import enqueue_job

logger = logging.getLogger(__name__)

def get_default_scrapers() -> list[BaseScraper]:
    """
    Default list of scrapers configured for ingestion.
    Following Open/Closed Principle: new scrapers can be registered here
    or passed directly to run_collection_pipeline.
    """
    return [
        GreenhouseScraper("No_Name"),
        LeverScraper("No_Name"),
    ]

async def run_collection_pipeline(
    scrapers: list[BaseScraper] | None = None
) -> dict[str, Any]:
    """
    Executes the job data collection pipeline:
    1. Runs all configured scrapers concurrently using asyncio.gather.
    2. Flattens and prepares validated job records.
    3. Bulk inserts new records into PostgreSQL while ignoring duplicates by source_url.
    4. Commits the transaction and returns an ingestion summary.
    """
    if scrapers is None:
        scrapers = get_default_scrapers()

    logger.info("Starting collection pipeline with %d scrapers", len(scrapers))

    # Run all scrapers concurrently
    tasks = [scraper.fetch_and_normalize() for scraper in scrapers]
    # Runs all scraper at exact same time
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Flatten the results into a single list of RawJob objects
    flat_jobs: list[RawJob] = []
    for idx, res in enumerate(results):
        if isinstance(res, Exception):
            scraper_name = scrapers[idx].__class__.__name__
            board_id = getattr(scrapers[idx], "board_id", "unknown")
            logger.error(
                "Scraper %s (board_id='%s') raised an unhandled exception: %s",
                scraper_name,
                board_id,
                res,
                exc_info=res
            )
            continue
        if isinstance(res, list):
            flat_jobs.extend(res)

    attempted_count = len(flat_jobs)
    if attempted_count == 0:
        logger.info("No jobs fetched across all scrapers. Pipeline complete.")
        return {
            "status": "success",
            "attempted": 0,
            "inserted": 0,
            "ignored": 0
        }

    # Prepare raw dictionary payloads matching the Job SQLAlchemy model
    job_columns = set(Job.__table__.columns.keys())

    for job in flat_jobs:
        job_dict = job.model_dump()

        # Compute content_hash for deduplication / integrity if column exists
        if "content_hash" in job_columns and "content_hash" not in job_dict:
            hash_str = f"{job.raw_title}|{job.company_name}|{job.description}"
            job_dict["content_hash"] = hashlib.sha256(hash_str.encode("utf-8")).hexdigest()
 
        # Filter strictly by Job model columns to avoid Unconsumed column errors
        clean_row = {k: v for k, v in job_dict.items() if k in job_columns}
        enqueue_job(clean_row)

    return {"status": "Jobs queued for processing"}

    

