# Job Aggregation & Intelligence Pipeline — Backend

> **Live Production API:** [https://job-scraper-z5uo.onrender.com](https://job-scraper-z5uo.onrender.com)  
> **Interactive Swagger Documentation:** [https://job-scraper-z5uo.onrender.com/docs](https://job-scraper-z5uo.onrender.com/docs)

A high-performance, asynchronous Python backend built with **FastAPI**, **SQLAlchemy 2.0 (asyncpg)**, and **Pydantic v2**. The service automates job harvesting from public applicant tracking systems (Greenhouse, Lever), performs deterministic text normalization and deduplication, processes listings through LLM enrichment pipelines with token economics accounting, and exposes dedicated public and administrative REST APIs.

---

## 🏗️ Architecture & Core Principles

```text
backend/
├── core/                         # Infrastructure & Persistence Foundation
│   ├── db.py                     # Async SQLAlchemy engine & AsyncSessionLocal dependency
│   ├── dto.py                    # Shared domain transfer objects
│   └── models.py                 # Core SQLAlchemy 2.0 models (Job, JobStatus, Base)
├── data_collection/              # Ingestion Domain (Scrapers & Text Normalizer)
│   ├── pipeline.py               # Concurrent scraper execution & queue enqueuer
│   ├── schemas.py                # Pydantic v2 RawJob & HTML cleaning validators
│   ├── router.py                 # HTTP endpoints for collection triggers
│   └── scrapers/                 # BaseScraper, GreenhouseScraper, LeverScraper
├── data_filtering/               # Pre-LLM Deduplication & Filtering Queue
│   └── synthetic_router.py       # Asynchronous worker queue & content hash deduplication
├── llm_tagging/                  # LLM Semantic Tagging & Token Economics
│   └── synthetic_router.py       # Worker queue for semantic enrichment & prompt tracking
├── admin/                        # Admin Operations Console Feature Module
│   ├── router.py                 # /api/admin REST endpoints
│   ├── schemas.py                # Dashboard metrics, audit, & pagination DTOs
│   └── service.py                # Pure dynamic SQL aggregations (no counter tables)
├── api/                          # Public-Facing Job Seeker REST API
│   ├── router.py                 # /api/v1/jobs endpoints, filters, & full-text search
│   └── schemas.py                # Public job listings and faceted filter options
├── tests/                        # Comprehensive Pytest Suite
│   ├── test_admin_api.py         # 7 integration tests for /api/admin
│   ├── test_data_collection.py   # Scraper, normalization, & deduplication tests
│   └── test_jobs_api.py          # Public jobs endpoints & filtering tests
├── main.py                       # Application bootstrap, CORS, routers & background workers
├── pytest.ini                    # Pytest async configuration (session loop scope)
└── requirements.txt              # Production Python dependencies
```

### Key Architectural Tenets
1. **Feature-First Organization:** Modules (`admin/`, `api/`, `data_collection/`, `llm_tagging/`) encapsulate their own schemas, services, and routers.
2. **Open/Closed Principle (OCP):** Scrapers inherit from `BaseScraper`. New ATS integrations (e.g. Workday, Ashby) can be added simply by subclassing `BaseScraper` without touching the collection pipeline.
3. **Database Deduplication:** Enforced through unique constraints on `source_url` with PostgreSQL `ON CONFLICT (source_url) DO NOTHING` alongside SHA-256 `content_hash` matching.
4. **Dynamic SQL Aggregations:** All financial spend, funnel metrics, and source-level analytics are computed dynamically on the `Job` model using `func.sum`, `func.count`, `func.avg`, and `case(...)`—avoiding stale summary tables.
5. **Orphan Recovery:** On startup, the lifespan manager queries any unclassified `RAW` records and automatically re-enqueues them into the LLM ingestion queue.

---

## ⚙️ Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# PostgreSQL Database Connection URL (Asyncpg)
DATABASE_URL=postgresql+asyncpg://postgres:your_password@your_host:5432/postgres

# (Optional) Direct Postgres URL for sync tools / migrations
SYNC_DATABASE_URL=postgresql://postgres:your_password@your_host:5432/postgres

# LLM API Keys (for production enrichment)
OPENAI_API_KEY=your-openai-api-key-here
```

---

## 🚀 Local Development Setup

### 1. Prerequisites
- Python 3.12+
- PostgreSQL 15+ (or cloud PostgreSQL instance like Supabase)

### 2. Virtual Environment & Dependencies

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv myenv

# Activate virtual environment
# Windows (PowerShell):
.\myenv\Scripts\activate
# macOS/Linux:
source myenv/bin/activate

# Install required dependencies
pip install -r requirements.txt
```

### 3. Running the Server

```bash
# Start FastAPI with hot-reloading on port 8000
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

The application will initialize database tables automatically on startup via SQLAlchemy `create_all` and launch the background worker queues.
- **Root Health:** `http://127.0.0.1:8000/`
- **Swagger UI:** `http://127.0.0.1:8000/docs`
- **ReDoc:** `http://127.0.0.1:8000/redoc`

---

## 📡 API Reference

### Public Job Seeker API (`/api/v1/jobs`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/jobs` | Paginated listings with search, role category, work mode, and experience filters. |
| `GET` | `/api/v1/jobs/{id}` | Retrieve single detailed job posting by UUID. |
| `GET` | `/api/v1/jobs/filter-options` | Dynamic distinct filter options derived from published listings. |
| `GET` | `/api/v1/jobs/stats` | Aggregated counts of available jobs, companies, and locations. |
| `POST` | `/api/v1/jobs/collect` | Triggers background data collection from Greenhouse and Lever. |

### Admin Operations Console API (`/api/admin` or `/admin`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/dashboard` | Live pipeline state, funnel progression, LLM spend, token economics, and error breakdown. |
| `GET` | `/api/admin/jobs` | Lightweight paginated job list with multi-status, source, search, and confidence filtering. |
| `GET` | `/api/admin/jobs/{job_id}` | Full job record inspection including raw JSON payload, tokens, and errors. |
| `POST` | `/api/admin/jobs/retry-failed` | Resets failed jobs to `PROCESSING` and re-enqueues them into the LLM worker queue. |
| `POST` | `/api/admin/jobs/reclassify` | Re-enqueues listings for fresh tagging by prompt version or max confidence threshold. |
| `DELETE` | `/api/admin/jobs/purge` | Guardrailed bulk deletion requiring `etl_status` or `older_than_days` criteria. |
| `DELETE` | `/api/admin/jobs/{job_id}` | Permanently deletes a single job record. |
| `POST` | `/api/admin/pipeline/trigger` | Manually triggers the scraper harvesting pipeline. |

---

## 🧪 Testing & Quality Assurance

The backend includes a comprehensive async test suite with **27 automated tests** covering all modules:

```bash
# Run pytest across all test suites
pytest -v

# Run admin module integration tests specifically
pytest tests/test_admin_api.py -v

# Run data collection and scraper unit tests
pytest tests/test_data_collection.py -v

# Run public job feed search and filter tests
pytest tests/test_jobs_api.py -v
```

> [!NOTE]
> Pytest is configured via `pytest.ini` with `asyncio_default_fixture_loop_scope = session` and `asyncio_default_test_loop_scope = session` to ensure reliable event loop reuse with `asyncpg` on Windows and Linux.
