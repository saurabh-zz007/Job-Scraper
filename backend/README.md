# Job Aggregation Pipeline - Backend

A high-performance, asynchronous FastAPI backend for scraping, text normalizing, deduplicating, and ingesting job postings from public applicant tracking systems (Greenhouse, Lever) into PostgreSQL using SQLAlchemy 2.0 and Pydantic v2.

---

## Architecture & Principles

- **Feature-First Architecture**: Features are organized by domain under `data_collection/` (schemas, scrapers, pipeline, controller, router).
- **Open/Closed Principle (OCP)**: The scraper engine is open for extension via `BaseScraper` and closed for modification. New ATS platforms (e.g., Ashby, Workday) can be integrated by subclassing `BaseScraper` without touching the collection pipeline.
- **Single Responsibility Principle**: The `data_collection` module handles fetching, text normalization, and database ingestion only. Relevance filtering, semantic classification, and LLM processing belong strictly to downstream pipeline stages.
- **Database Deduplication**: Job uniqueness is enforced at the database layer via PostgreSQL `ON CONFLICT (source_url) DO NOTHING`.

---

## File Structure

```text
backend/
├── core/
│   ├── db.py                 # Async SQLAlchemy engine & AsyncSessionLocal dependency
│   ├── dto.py                # Core DTO definitions
│   └── models.py             # Preexisting SQLAlchemy 2.0 models (Job, JobStatus, Base)
├── data_collection/
│   ├── __init__.py
│   ├── controller.py         # Controller wrapper coordinating pipeline execution
│   ├── models.py             # Re-exports core.models.Job
│   ├── pipeline.py           # Concurrent scraper orchestration & bulk DB insertion
│   ├── router.py             # FastAPI APIRouter exposing POST /jobs/collect
│   ├── schemas.py            # Pydantic v2 RawJob & response schemas
│   └── scrapers/
│       ├── __init__.py       # Scraper registry
│       ├── base.py           # Abstract BaseScraper class
│       ├── greenhouse.py     # Greenhouse ATS scraper (httpx async)
│       └── lever.py          # Lever ATS scraper (httpx async)
├── tests/
│   └── test_data_collection.py # Pytest test suite covering all modules
├── main.py                   # FastAPI entrypoint, CORS, routers & lifespan
├── pytest.ini                # Pytest configuration
└── requirements.txt          # Production dependencies
```

---

## Key Components

### 1. `data_collection/schemas.py`
Defines `RawJob`:
- `source_name` (`str`)
- `source_id` (`str | None`)
- `source_url` (`str`)
- `company_name` (`str`)
- `raw_title` (`str`)
- `raw_location` (`str | None`)
- `description` (`str`)
- `posted_at` (`datetime | None`)

Validators:
- `@field_validator("description", mode="before")`: Decodes HTML entities and strips all HTML tags using regex (`<[^>]+>`), then normalizes all whitespace sequences into a single space.
- `@field_validator("source_url", mode="after")`: Strips query parameters and trailing slashes for clean DB-level uniqueness.
- `@field_validator("raw_title", "company_name", mode="after")`: Strips leading and trailing whitespace.

### 2. `data_collection/scrapers/base.py`
Abstract base class defining:
- `__init__(self, board_id: str, company_name: str | None = None)`
- `@abstractmethod async def fetch_and_normalize(self) -> list[RawJob]`

### 3. `data_collection/scrapers/greenhouse.py` & `lever.py`
- Inherits from `BaseScraper`.
- Uses `httpx.AsyncClient(timeout=20.0)`.
- Greenhouse endpoint: `https://boards-api.greenhouse.io/v1/boards/{board_id}/jobs?content=true`
- Lever endpoint: `https://api.lever.co/v0/postings/{board_id}?mode=json`
- Maps raw JSON payloads to `RawJob` schemas with direct HTML description mapping for Pydantic normalization.

### 4. `data_collection/pipeline.py`
- `run_collection_pipeline(db_session: AsyncSession, scrapers: list[BaseScraper] | None = None)`
- Runs scrapers concurrently with `asyncio.gather(*tasks, return_exceptions=True)`.
- Flattens validated models into dictionaries (`job.model_dump()`).
- Computes SHA-256 `content_hash` and matches `Job` table columns.
- Performs bulk insert using SQLAlchemy PostgreSQL dialect:
  ```python
  stmt = (
      insert(Job)
      .values(valid_jobs_data)
      .on_conflict_do_nothing(index_elements=["source_url"])
      .returning(Job.id)
  )
  ```
- Commits the transaction and returns:
  ```json
  {
      "status": "success",
      "attempted": 100,
      "inserted": 85,
      "ignored": 15
  }
  ```

### 5. `data_collection/router.py` & `main.py`
- Endpoint: `POST /jobs/collect` (also registered at `POST /api/v1/jobs/collect`).
- Injects `AsyncSession` via `Depends(get_db)`.
- Accepts an optional JSON payload to run custom boards or defaults to standard configured scrapers.

---

## Running the Application

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run Tests
```bash
pytest -v
```

### 3. Start the Server
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Trigger Data Collection
```bash
curl -X POST http://localhost:8000/jobs/collect
```
Or with custom boards:
```bash
curl -X POST http://localhost:8000/jobs/collect \
  -H "Content-Type: application/json" \
  -d '{"greenhouse_boards": ["canonical"], "lever_boards": ["spotify"]}'
```

