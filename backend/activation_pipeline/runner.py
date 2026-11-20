import asyncio
import logging
import re
from sqlalchemy import select

from core.db import AsyncSessionLocal
from activation_pipeline.models import CompanyTarget
from data_collection.pipeline import run_collection_pipeline
from data_collection.scrapers.greenhouse import GreenhouseScraper
from data_collection.scrapers.lever import LeverScraper
from data_collection.scrapers.base import BaseScraper

logger = logging.getLogger(__name__)

is_running: bool = False

SLUG_OVERRIDES: dict[str, str] = {}


def to_board_id(company: str) -> str:
    if company in SLUG_OVERRIDES:
        return SLUG_OVERRIDES[company]
    base_name = company.split("(")[0].strip().lower()
    return re.sub(r"[^a-z0-9]", "", base_name)


def build_scraper(target: CompanyTarget) -> BaseScraper | None:
    board_id = to_board_id(target.company)
    ats = target.ats.strip().lower()

    if ats == "greenhouse":
        return GreenhouseScraper(board_id=board_id, company_name=target.company)
    if ats == "lever":
        return LeverScraper(board_id=board_id, company_name=target.company)

    logger.warning("Unsupported ATS '%s' for %s; skipping.", target.ats, target.company)
    return None


async def run_paced_collection(rate_per_minute: float = 2.0) -> None:
    global is_running
    if is_running:
        logger.warning("Collection run already in progress. Skipping duplicate trigger.")
        return

    is_running = True
    delay_seconds = 60.0 / rate_per_minute  

    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(select(CompanyTarget).order_by(CompanyTarget.id))
            targets = result.scalars().all()

        total = len(targets)
        logger.info("Starting paced collection for %d companies (1 every %.1fs)", total, delay_seconds)

        for idx, target in enumerate(targets, start=1):
            scraper = build_scraper(target)
            if scraper is not None:
                try:
                    logger.info(
                        "[%d/%d] Collecting %s (ats=%s, board_id=%s)",
                        idx,
                        total,
                        target.company,
                        target.ats,
                        scraper.board_id,
                    )
                    summary = await run_collection_pipeline(scrapers=[scraper])
                    logger.info("[%d/%d] %s done -> %s", idx, total, target.company, summary)
                except Exception as exc:
                    logger.error("[%d/%d] Failed collecting %s: %s", idx, total, target.company, exc)

            if idx < total:
                await asyncio.sleep(delay_seconds)

        logger.info("Completed paced collection for %d companies.", total)
    finally:
        is_running = False