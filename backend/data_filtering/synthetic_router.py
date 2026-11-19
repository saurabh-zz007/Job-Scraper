import logging
import asyncio

from typing import Any
from sqlalchemy.dialects.postgresql import insert

from core.db import AsyncSessionLocal
from core.models import Job
from data_filtering.filtering import Filtering
# ISSUE: Breaking modularity: Impliment Celery Workers
from data_collection.schemas import RawJob
from llm_tagging.synthetic_router import llm_tagging

logger = logging.getLogger(__name__)

_filter_queue = asyncio.Queue()
_worker_tasks: list[asyncio.Task] = []

def enqueue_job(job_data: dict[str, Any]):
    _filter_queue.put_nowait(job_data)

async def _synthetic_worker(worker_id: int)-> None:
    logger.info("Synthetic filtering worker-%d ready", worker_id)

    while True:
        job_data = await _filter_queue.get()

        try:
            async with AsyncSessionLocal() as session:
                filter_service = Filtering(db_session=session)
                is_valid = await filter_service.is_valid_job(job_data)

                if not is_valid:
                    continue

                stmt = (
                    insert(Job)
                    .values(job_data)
                    .on_conflict_do_nothing(index_elements=["source_url"])
                    .returning(Job.id)
                )
                result = await session.execute(stmt)
                inserted_id = result.scalar_one_or_none()
                await session.commit()

                if inserted_id is None:
                    logger.info("[DB SKIPPED - CONCURRENT DUPLICATE] %s", job_data.get("source_url"))
                    continue
                logger.info("[DB INSERTED - ID: %s] %s", inserted_id, job_data.get("raw_title"))

            job_data["id"] = inserted_id
            await llm_tagging(job_data)

        except Exception as e:
            logger.error(
                "Worker-%d error processing %s: %s",
                worker_id,
                job_data.get("source_url"),
                e,
                exc_info=True,
            )
        finally:
            _filter_queue.task_done()

def start_synthetic_workers(num_workers: int = 1) -> None:
    for i in range(num_workers):
        task = asyncio.create_task(_synthetic_worker(i + 1))
        _worker_tasks.append(task)


async def stop_synthetic_workers() -> None:
    for task in _worker_tasks:
        task.cancel()
    await asyncio.gather(*_worker_tasks, return_exceptions=True)
    _worker_tasks.clear()


