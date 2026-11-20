from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from activation_pipeline.models import CompanyTarget
from activation_pipeline.schemas import CompanySeedItem


async def seed_companies(db: AsyncSession, items: list[CompanySeedItem]) -> dict[str, int]:
    # Deduplicate incoming list by company name
    unique_items: dict[str, str] = {}
    for item in items:
        name = item.company.strip()
        if name and name not in unique_items:
            unique_items[name] = item.ats.strip().lower()

    result = await db.execute(select(CompanyTarget.company))
    existing_names = set(result.scalars().all())

    new_records = [
        CompanyTarget(company=name, ats=ats)
        for name, ats in unique_items.items()
        if name not in existing_names
    ]

    if new_records:
        db.add_all(new_records)
        await db.commit()

    return {
        "inserted": len(new_records),
        "skipped": len(unique_items) - len(new_records),
    }