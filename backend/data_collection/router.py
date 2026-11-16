from typing import Any
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from core.db import get_db
from data_collection.pipeline import run_collection_pipeline
from data_collection.schemas import JobCollectionResponse, CollectionTriggerRequest
from data_collection.scrapers.base import BaseScraper
from data_collection.scrapers.greenhouse import GreenhouseScraper
from data_collection.scrapers.lever import LeverScraper

router = APIRouter(prefix="/jobs", tags=["Data Collection"])


@router.post(
    "/collect",
    response_model=JobCollectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Trigger Job Data Collection Pipeline",
    description=(
        "Concurrently fetches job postings from configured scrapers, "
        "normalizes text, and bulk inserts them into PostgreSQL with deduplication on source_url. "
        "Optionally accepts custom board lists for Greenhouse and Lever."
    )
)
async def collect_jobs_endpoint(
    payload: CollectionTriggerRequest | None = None,
    db: AsyncSession = Depends(get_db)
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

    summary = await run_collection_pipeline(db_session=db, scrapers=custom_scrapers)
    return summary
