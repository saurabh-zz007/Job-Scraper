import os
from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from activation_pipeline import runner
from activation_pipeline.schemas import CompanySeedItem, CompanyTargetRead
from activation_pipeline.seeder import seed_companies
from core.db import get_db  
from core.settings import settings

router = APIRouter(prefix="/activation", tags=["Activation Pipeline"])

TRIGGER_SECRET = settings.ACTIVATION_TRIGGER_SECRET


def verify_trigger_secret(x_trigger_secret: str = Header(...)) -> None:
    if not TRIGGER_SECRET or x_trigger_secret != TRIGGER_SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid trigger secret",
        )


@router.post(
    "/seed",
    response_model=dict,
    dependencies=[Depends(verify_trigger_secret)],
)
async def seed_company_targets(
    items: list[CompanySeedItem],
    db: AsyncSession = Depends(get_db),
):
    summary = await seed_companies(db, items)
    return {"status": "ok", **summary}


@router.post(
    "/trigger",
    status_code=status.HTTP_202_ACCEPTED,
    dependencies=[Depends(verify_trigger_secret)],
)
async def trigger_collection(
    background_tasks: BackgroundTasks,
    rate_per_minute: float = 2.0,
):
    if rate_per_minute <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="rate_per_minute must be greater than 0",
        )

    if runner.is_running:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A collection run is already in progress.",
        )

    background_tasks.add_task(
        runner.run_paced_collection,
        rate_per_minute=rate_per_minute,
    )
    return {
        "status": "started",
        "rate_per_minute": rate_per_minute,
        "message": "Paced data collection started in background.",
    }


@router.get(
    "/status",
    dependencies=[Depends(verify_trigger_secret)],
)
async def get_activation_status():
    return {
        "is_running": runner.is_running,
    }