from typing import Any
from fastapi import APIRouter, status, BackgroundTasks

from data_collection.pipeline import run_collection_pipeline
from data_collection.schemas import CollectionTriggerRequest
from data_collection.scrapers.base import BaseScraper
from data_collection.scrapers.greenhouse import GreenhouseScraper
from data_collection.scrapers.lever import LeverScraper

router = APIRouter(prefix="/jobs", tags=["Data Collection"])


@router.post(
    "/collect",
    status_code=status.HTTP_200_OK,
    summary="Trigger Job Data Collection Pipeline",
    description=(
        "Concurrently fetches job postings from configured scrapers, "
        "normalizes text, and bulk inserts them into PostgreSQL with deduplication on source_url. "
        "Optionally accepts custom board lists for Greenhouse and Lever."
    )
)
async def collect_jobs_endpoint(
    background_tasks: BackgroundTasks,
    payload: CollectionTriggerRequest | None = None,
) -> dict[str, Any]:
    """
    HTTP endpoint to trigger the job ingestion pipeline.
    Returns status and counts of attempted, inserted, and ignored jobs.
    """
    custom_scrapers: list[BaseScraper] | None = None
    if payload and (payload.greenhouse_boards or payload.lever_boards):
        custom_scrapers = []
        if payload.greenhouse_boards:
            for board in payload.greenhouse_boards:
                custom_scrapers.append(GreenhouseScraper(board_id=board))
        if payload.lever_boards:
            for board in payload.lever_boards:
                custom_scrapers.append(LeverScraper(board_id=board))

    background_tasks.add_task(run_collection_pipeline, custom_scrapers)
    return {"status": "Collection started"}
