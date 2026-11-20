import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.db import engine
from core.models import Base, Job
from api.router import api_router
from admin.router import router as admin_router
from data_collection.router import router as data_collection_router
from activation_pipeline.router import router as activation_router
from data_filtering.synthetic_router import start_synthetic_workers, stop_synthetic_workers
from llm_tagging.synthetic_router import (
    start_synthetic_LLM_workers, 
    stop_synthetic_LLM_workers,
    recover_pending_llm_jobs
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("job_scraper")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables initialized successfully.")
        start_synthetic_workers(num_workers=2)
        start_synthetic_LLM_workers(num_workers=3)

        recovered_count = await recover_pending_llm_jobs()
        if recovered_count > 0:
            logger.info("Successfully recovered %d orphaned RAW jobs into the LLM queue.", recovered_count)
        else:
            logger.info("No orphaned RAW jobs found in database.")
            
    except Exception as exc:
        logger.warning(
            "Could not connect to database on startup (tables not auto-created): %s",
            exc
        )
    yield
    await stop_synthetic_workers()
    await stop_synthetic_LLM_workers()
    try:
        await engine.dispose()
        logger.info("Database connection pool disposed.")
    except Exception as exc:
        logger.warning("Error disposing database connection pool: %s", exc)

app = FastAPI(
    title="Job Aggregation Pipeline API",
    description="Feature-first FastAPI backend for scraping, text normalization, and PostgreSQL ingestion.",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API routes under /api/v1 and /api/admin
app.include_router(api_router, prefix="/api/v1")
app.include_router(data_collection_router, prefix="/api/collection")
app.include_router(admin_router, prefix="/api/admin")
app.include_router(activation_router, prefix="/api/collection")

@app.get("/", tags=["Health"])
async def root():
    return {
        "service": "Job Aggregation Pipeline",
        "status": "online",
        "documentation": "/docs"
    }

@app.get("/health", tags=["Health"])
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

