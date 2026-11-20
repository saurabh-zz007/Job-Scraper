# Job.io — Automated Tech Job Ingestion & Intelligence Platform

> **Live Deployments:**
> - 🌐 **Frontend Web App:** [https://job-scraper-1-vuf1.onrender.com](https://job-scraper-1-vuf1.onrender.com)
> - ⚙️ **Backend API & Swagger Docs:** [https://job-scraper-z5uo.onrender.com/docs](https://job-scraper-z5uo.onrender.com/docs)
>
> *Made by upcoming Event Beeps Engineer*

---

## 📌 Executive Overview

**Job.io** is an end-to-end, full-stack automated job aggregation, normalization, and semantic intelligence system. It continuously extracts tech job postings from applicant tracking systems (Greenhouse, Lever, etc.), filters and normalizes raw text, enriches listings using structured LLM classification pipelines (tagging role categories, experience levels, tech stacks, and work modes with confidence scoring), and surfaces them through a responsive, high-performance web dashboard.

The platform provides two distinct, cohesive experiences:
1. **Public Job Explorer:** Fast, multi-facet reactive filtering, instant keyword search, intelligent job description formatting, and direct application routing.
2. **Admin Operations Console:** Password-protected, real-time command center monitoring ETL funnel progression, LLM token unit economics (spend per job, prompt versions), ATS source quality metrics, interactive job inspector, and database maintenance controls.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph DataSources["Public ATS Job Boards"]
        GH["Greenhouse API"]
        LV["Lever API"]
        WD["Workday / Direct"]
    end

    subgraph Backend["FastAPI Ingestion & Processing Backend"]
        SC["Async Scrapers (BaseScraper)"]
        NORM["Pydantic Text Normalizer & Entity Sanitizer"]
        HASH["Content Hash & Source URL Deduplicator"]
        QUEUE["Background Synthetic Ingestion Queues"]
        LLM["LLM Semantic Tagging & Economics Tracker"]
        DB[(Supabase PostgreSQL 15)]
        API["Public REST API (/api/v1)"]
        ADMIN["Admin Console API (/api/admin)"]
    end

    subgraph Frontend["Flutter Web Application (Job.io)"]
        ENV["Central .env Base URL Configuration"]
        REPO["Repository Layer (JobRepository & AdminRepository)"]
        JOBS_VM["JobsViewModel (Reactive State & Multi-Filter)"]
        ADMIN_VM["AdminViewModel & Auth Gateway"]
        UI_JOBS["Public Job Search & Detail Views"]
        UI_ADMIN["Admin Operations Console (KPIs & Diagnostics)"]
    end

    DataSources -->|Async HTTP| SC
    SC --> NORM
    NORM --> HASH
    HASH --> QUEUE
    QUEUE --> LLM
    LLM --> DB
    DB --> API
    DB --> ADMIN

    ENV --> REPO
    API -->|JSON REST| REPO
    ADMIN -->|JSON REST| REPO
    REPO --> JOBS_VM
    REPO --> ADMIN_VM
    JOBS_VM --> UI_JOBS
    ADMIN_VM --> UI_ADMIN
```

---

## 🌟 Key Platform Capabilities

### 1. Robust Asynchronous Data Collection
- Concurrent scraping using `httpx.AsyncClient` and `asyncio.gather`.
- Extensible via an **Open/Closed Principle (OCP)** architecture: subclassing `BaseScraper` allows new ATS platforms to be added without touching the ingestion orchestrator.
- Normalization strips messy HTML tags, decodes encoded entities (`&amp;`, `&rsquo;`), cleans URL tracking parameters, and trims excess whitespace.
- Collision avoidance using SHA-256 content hashing and database-level `ON CONFLICT (source_url) DO NOTHING`.

### 2. LLM Tagging & Token Economics
- Intelligent extraction of:
  - **Role Category** (Backend, Frontend, Full Stack, DevOps, Mobile, Data/AI, etc.)
  - **Work Mode** (Remote, Hybrid, On-site)
  - **Job Type** (Full-time, Part-time, Contract, Internship)
  - **Experience Level** (Junior, Mid, Senior, Lead, Director)
  - **Tech Stack & Skills** (Extracted array of technical competencies)
  - **Classification Confidence Score** (0.0 to 1.0)
- Full financial and audit tracking per job: prompt version, LLM model used, input tokens, output tokens, processing attempts, and USD cost.

### 3. Public Job Seeker Portal (`/`)
- Responsive two-column desktop / collapsible mobile drawer layout built with Flutter Web.
- Instant, client-reactive multi-facet filtering (Role, Work Mode, Job Type, Experience, City, ATS Source) and keyword search across title, company, and inferred skills.
- Sorting by newest or AI classification confidence.
- **Smart Job Description Formatter:** Automatically parses unstructured job description walls into visual sections (About the Role, Responsibilities, Requirements, Benefits, Compensation) with styled bullet points and icons.
- Direct external routing to the official application board.

### 4. Full-Stack Admin Operations Console (`/admin`)
- **Password Authentication Gateway:** Protected with username/password authentication configured via `frontend/.env`.
- **Live Pipeline Telemetry:** Auto-refresh toggle (15s) and manual refresh controls.
- **4-Grid KPI Analytics:**
  - *Pipeline Funnel:* Raw, Filtered/Pending, Classified, and Failed counts with a segmented visual distribution bar.
  - *LLM Economics:* Total spend, 24-hour spend, and average cost per classified listing.
  - *Token Consumption:* Prompt input tokens, generated output tokens, and total volume.
  - *Quality Metrics:* Average classification confidence gauge, count of low-confidence listings (<80%), and stale jobs (>14 days).
- **Diagnostic Panels:** Breakdown by ATS source, breakdown by model and prompt version, and top recurring ingestion errors.
- **Interactive Jobs Table:** Multi-status filtering (`ALL`, `RAW`, `FILTERED`, `CLASSIFIED`, `FAILED`), company search, low-confidence filter, per-row inspection, retry, and delete actions.
- **Modal Job Inspector:** 4-tab audit view (Overview & Inferred Tags, LLM Financial Audit, Formatted Description, and Raw JSON payload).
- **Maintenance / Danger Zone:** Guardrailed database purge actions (Purge all failed jobs, purge stale jobs >14 days, and bulk reclassification of low-confidence listings).

---

## 📂 Repository Structure

```text
Job Scraper/
├── README.md                      # Global project documentation (this file)
├── .gitignore                     # Root gitignore (protects .env files & virtual environments)
│
├── backend/                       # Python FastAPI Backend
│   ├── README.md                  # Dedicated backend architecture & setup guide
│   ├── main.py                    # Application entrypoint, CORS, lifecycle & router mounting
│   ├── pytest.ini                 # Pytest async test runner configuration
│   ├── requirements.txt           # Python production dependencies
│   ├── core/                      # Database engine, base models & DTOs
│   │   ├── db.py                  # Async SQLAlchemy sessionmaker
│   │   └── models.py              # PostgreSQL Job model & JobStatus enum
│   ├── data_collection/           # Scrapers & ingestion orchestrator
│   │   ├── pipeline.py            # Concurrent fetcher & queue enqueuer
│   │   ├── schemas.py             # Pydantic v2 RawJob schemas & validators
│   │   └── scrapers/              # BaseScraper, GreenhouseScraper, LeverScraper
│   ├── data_filtering/            # Queue workers & deduplication
│   ├── llm_tagging/               # Synthetic LLM enrichment workers
│   ├── admin/                     # Admin Operations Console feature module
│   │   ├── router.py              # /api/admin REST endpoints
│   │   ├── schemas.py             # Dashboard metrics & pagination schemas
│   │   └── service.py             # Pure SQLAlchemy dynamic aggregations
│   ├── api/                       # Public job search & filter REST API (/api/v1)
│   └── tests/                     # Comprehensive pytest test suite (27 passing tests)
│
└── frontend/                      # Flutter Web Application
    ├── README.md                  # Dedicated frontend architecture & setup guide
    ├── pubspec.yaml               # Flutter package configuration & asset registry
    ├── .env                       # Local & production environment variables (git-ignored)
    ├── lib/
    │   ├── main.dart              # App bootstrap & EnvConfig initialization
    │   ├── core/                  # Routes, theming, and environment config
    │   │   ├── config/env_config.dart # Dynamic .env loader & base URL provider
    │   │   ├── routes/            # GetX routing table & bindings
    │   │   └── theme/             # Modern SaaS design palette (Inter font, slate colors)
    │   ├── data/                  # Models & repositories
    │   │   ├── models/            # JobModel, Admin models (DTOs)
    │   │   └── repositories/      # ApiJobRepository & ApiAdminRepository (GetConnect)
    │   └── features/              # Feature-first modular UI & ViewModels
    │       ├── shell/             # Navigation shell (Job.io header & tab switcher)
    │       ├── jobs/              # Public job feed, filters, cards, and detail modal
    │       └── admin/             # Admin console, login gateway, KPI cards, table & inspector
    └── test/                      # Flutter unit, reactive, and widget tests (34 passing tests)
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Backend:** Python 3.12+ and PostgreSQL (or Supabase URL)
- **Frontend:** Flutter SDK 3.24+ (Channel stable, Web enabled) and Google Chrome

---

### Step 1: Run the Backend Locally

```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python -m venv myenv
# Windows:
.\myenv\Scripts\activate
# Linux/macOS:
source myenv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file with your PostgreSQL connection string:
# DATABASE_URL=postgresql+asyncpg://postgres:your_password@localhost:5432/job_scraper

# Run the FastAPI server
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
API Documentation will be accessible at: `http://127.0.0.1:8000/docs`

---

### Step 2: Run the Frontend Locally

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter dependencies
flutter pub get

# Ensure frontend/.env exists:
# ADMIN_USERNAME=admin
# ADMIN_PASSWORD=admin
# BASE_URL=http://127.0.0.1:8000

# Launch Flutter Web application in Chrome
flutter run -d chrome
```

---

## 🔄 Switching Between Local & Cloud Backend

The frontend features a **single-line comment swap** in [frontend/.env](file:///d:/Projects/Job%20Scraper/frontend/.env) to toggle between local development and the live Render cloud backend:

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin

# --- Central API Base URL ---
# Uncomment for Local Development:
# BASE_URL=http://127.0.0.1:8000

# Uncomment for Render Cloud Backend:
BASE_URL=https://job-scraper-z5uo.onrender.com
```

---

## 🧪 Automated Testing & Verification

Both sub-projects maintain strict test coverage:

- **Backend (Pytest):** 27 integration and unit tests covering admin metrics, scrapers, deduplication, search filters, and pipeline triggers.
  ```bash
  cd backend
  pytest -v
  ```
- **Frontend (Flutter Test):** 34 tests covering model serialization, reactive viewmodels, authentication flows, markdown description parsing, and full widget rendering.
  ```bash
  cd frontend
  flutter analyze
  flutter test
  ```

---

## 📄 License
This project is proprietary software developed for high-volume automated job discovery and semantic analytics.

