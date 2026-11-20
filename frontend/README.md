# Job.io — Frontend Web Application

> **Live Production Web App:** [https://job-scraper-1-vuf1.onrender.com](https://job-scraper-1-vuf1.onrender.com)  
> **Backend Service:** [https://job-scraper-z5uo.onrender.com](https://job-scraper-z5uo.onrender.com)  
> *Made by upcoming Event Beeps Engineer*

A clean, responsive, enterprise-grade web application targeting **Flutter Web** (with mobile/tablet responsive breakpoints) built using **Feature-First MVVM**, **GetX state management**, and the **Repository pattern**.

---

## 🏗️ Architecture & Folder Organization

The application strictly separates presentation, business logic, data modeling, and network communication:

```text
frontend/
├── .env                           # Environment variables & swappable API Base URL (git-ignored)
├── pubspec.yaml                   # Flutter dependencies & asset declarations
├── lib/
│   ├── main.dart                  # App bootstrap & EnvConfig initialization
│   ├── core/                      # Global infrastructure & configuration
│   │   ├── config/                # Environment configuration
│   │   │   └── env_config.dart    # Safe .env reader & central Base URL provider
│   │   ├── routes/                # GetX routing table & bindings
│   │   │   ├── app_pages.dart
│   │   │   └── app_routes.dart
│   │   └── theme/                 # Modern SaaS palette (Slate neutrals, Indigo primary)
│   │       └── app_theme.dart
│   ├── data/                      # Data layer & DTOs
│   │   ├── models/                # Strongly-typed data models
│   │   │   ├── admin_models.dart  # Metrics, audit, and pagination DTOs
│   │   │   └── job_model.dart     # JobModel mirroring PostgreSQL schema
│   │   └── repositories/          # Isolated HTTP network communication
│   │       ├── admin_repository.dart # ApiAdminRepository (GetConnect)
│   │       └── job_repository.dart   # ApiJobRepository (GetConnect)
│   └── features/                  # Feature-first modular domains
│       ├── shell/                 # Navigation Shell & Persistent Tab Switcher
│       │   ├── bindings/shell_binding.dart
│       │   ├── viewmodels/shell_viewmodel.dart
│       │   └── views/shell_view.dart # Top bar (Job.io logo) & IndexedStack
│       ├── jobs/                  # Public Job Seeker Domain
│       │   ├── bindings/jobs_binding.dart
│       │   ├── viewmodels/jobs_viewmodel.dart # Reactive multi-facet filters & sorting
│       │   ├── views/jobs_view.dart           # Two-column layout with loading & error states
│       │   └── widgets/
│       │       ├── formatted_job_description.dart # Section & bullet point parser
│       │       ├── job_card.dart                  # Clean listing cards with skill badges
│       │       ├── job_detail_modal.dart          # Detailed modal drawer with direct Apply link
│       │       └── job_filter_sidebar.dart        # Multi-select faceted filter drawer
│       └── admin/                 # Admin Operations Console Domain
│           ├── bindings/admin_binding.dart
│           ├── viewmodels/admin_viewmodel.dart # Pipeline triggers, retry, purge, & auth state
│           ├── views/
│           │   ├── admin_login_view.dart       # Password authentication card
│           │   └── admin_view.dart             # Main operations console & inspector overlay
│           └── widgets/
│               ├── admin_control_bar.dart      # Live telemetry & auto-refresh (15s) toggle
│               ├── admin_danger_zone.dart      # Guardrailed purge & reclassification actions
│               ├── admin_diagnostic_panels.dart # Source, model/prompt, & top error panels
│               ├── admin_job_inspector_dialog.dart # 4-tab job audit modal
│               ├── admin_jobs_table.dart       # Interactive table with status & search filters
│               └── admin_kpi_cards.dart        # 4-grid KPI summary analytics
└── test/                          # Unit, Reactive State, & Widget Tests (34 passing tests)
    ├── admin_viewmodel_test.dart  # Serialization, auth & admin viewmodel tests
    ├── admin_widget_test.dart     # AdminView, login flow & FormattedJobDescription tests
    ├── jobs_viewmodel_test.dart   # Public feed filtering, search & sorting tests
    └── widget_test.dart           # Shell header & navigation tab rendering tests
```

---

## 🌟 Key Application Features

### 1. Public Job Explorer (`Job.io`)
- **Reactive Multi-Filter Engine:** Instant client-side filtering across:
  - Role Category (Backend, Frontend, Full Stack, DevOps, Mobile, etc.)
  - Work Mode (Remote, Hybrid, On-site)
  - Job Type (Full-time, Part-time, Contract, Internship)
  - Experience Level (Junior, Mid, Senior, Lead, Director)
  - City/Location & ATS Source (Greenhouse, Lever)
- **Keyword Search:** Instant debounced search querying title, company, and inferred skills.
- **Sorting:** Toggle between "Newest First" and "Highest Confidence".
- **Intelligent Job Description Formatter:** Automatically parses raw unstructured job text into formatted visual sections (About the Role, Responsibilities, Requirements, Benefits, Compensation) with styled bullet points and icons.
- **Connection Diagnostics:** Shows live backend URL connectivity status (`Connecting to Server...` or `Disconnected from Backend`) with one-click reconnect.

### 2. Admin Operations Console (`/admin`)
- **Password Authentication Gateway:** Access requires admin authentication (`admin` / `admin`) configured in `.env`.
- **Live Sync Controls:** Automatic 15-second polling switch and manual refresh.
- **4-Grid KPI Analytics:**
  - *Pipeline Funnel:* Raw, Filtered/Pending, Classified, and Failed metrics with segmented visual bar.
  - *LLM Economics:* Total spend, 24h spend, and average cost per classified listing.
  - *Token Consumption:* Prompt input tokens, generated output tokens, and total token count.
  - *Extraction Quality:* Average confidence gauge, count of low-confidence listings (<80%), and stale listings (>14 days).
- **Diagnostic Panels:** Breakdown by source ATS, breakdown by model and prompt version, and top recurring errors.
- **Interactive Jobs Table:** Multi-status filters (`ALL`, `RAW`, `FILTERED`, `CLASSIFIED`, `FAILED`), search, low-confidence toggle, pagination, and row actions (Inspect, Retry, Delete).
- **Modal Job Inspector:** 4-tab deep dive:
  1. *Overview & Tags:* Role, work mode, skills chips, and timestamps.
  2. *LLM Audit:* Model name, prompt version, input/output tokens, cost, and attempts.
  3. *Job Description:* Formatted structured text.
  4. *Raw JSON Payload:* Scrollable JSON viewer.
- **Maintenance / Danger Zone:** Guardrailed database purge actions (Purge all failed jobs, purge stale jobs >14 days, and bulk reclassification of low-confidence listings).

---

## ⚙️ Environment Configuration (`.env`)

The frontend contains a centralized `.env` configuration file at `frontend/.env`:

```env
# Administrator Credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin

# --- Central API Base URL ---
# Toggle between local server and web-published backend with one comment swap:
# BASE_URL=http://127.0.0.1:8000
BASE_URL=https://job-scraper-z5uo.onrender.com
```

> [!TIP]
> To switch network calls between your local FastAPI server and the live Render cloud deployment, simply comment/uncomment the `BASE_URL` line. `EnvConfig.apiBaseUrl` automatically trims trailing slashes and supplies the URL to all repositories.

---

## 🚀 Local Development Setup

### 1. Prerequisites
- **Flutter SDK:** 3.24.0 or higher (Channel stable)
- **Browser:** Google Chrome (for Flutter Web debugging)

### 2. Install Dependencies

```bash
# Navigate to frontend directory
cd frontend

# Install Flutter packages
flutter pub get
```

### 3. Run the Web Application

```bash
# Run in Google Chrome on localhost
flutter run -d chrome
```

### 4. Build for Production

```bash
# Build optimized release Web bundle
flutter build web --release
```
The production bundle will be generated in `build/web/`, ready to deploy to Render, Netlify, Vercel, or Firebase Hosting.

---

## 🧪 Testing & Verification

The frontend test suite includes **34 automated unit, reactive state, and widget tests**:

```bash
# Run static analysis
flutter analyze

# Run all test suites
flutter test

# Run specific test suites
flutter test test/admin_widget_test.dart
flutter test test/admin_viewmodel_test.dart
flutter test test/jobs_viewmodel_test.dart
flutter test test/widget_test.dart
```

All tests execute headless and verify:
- `EnvConfig` key-value parsing, trailing slash stripping, and URL swapping
- `AdminViewModel` authentication, login failure alerts, and sign-out logic
- `DashboardMetricsModel` and `AdminJobDetailModel` JSON deserialization
- Reactive multi-facet filtering and search state changes
- `FormattedJobDescription` section detection, bullet parsing, and entity sanitization
- `ShellView` responsive layout and `AdminView` dashboard rendering
