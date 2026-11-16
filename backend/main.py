import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.db import engine
from core.models import Base, Job
from data_collection.router import router as data_collection_router

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
    except Exception as exc:
        logger.warning(
            "Could not connect to database on startup (tables not auto-created): %s",
            exc
        )
    yield
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

# Register data collection router under both prefixes for flexible routing
app.include_router(data_collection_router, prefix="/api/v1")

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

