# Logistics Data Analytics Platform

A logistics analytics platform built with DuckDB, dbt, and Evidence. The project transforms raw operational data into a modeled data mart and presents it through 13 interactive dashboard pages.

## Architecture

```
Raw Data (CSV) → DuckDB → dbt (staging + marts) → Evidence (dashboards)
```

- **Database:** DuckDB (`data/logistics.duckdb`)
- **Transformation:** dbt with 25 SQL models across staging, intermediate, and mart layers
- **Dashboards:** Evidence (evidence.dev) — code-based BI generating a static site from markdown + SQL + chart components

## Data

85,410 trips across 50 drivers, 100 trucks, 49 lanes, 58 routes, 10 regions, 25 customers, and ~200 facilities (2022–2024).

## Dashboard Pages

| # | Page | URL Path |
|---|---|---|
| 1 | Executive Summary | `/` |
| 2 | Driver Performance | `/drivers` |
| 3 | Driver Detail | `/drivers/detail` |
| 4 | Fleet Utilization | `/fleet` |
| 5 | Truck Detail | `/fleet/detail` |
| 6 | Maintenance Analysis | `/fleet/maintenance` |
| 7 | Route & Lane Profitability | `/routes` |
| 8 | Regional Analysis | `/routes/regions` |
| 9 | Customer Analysis | `/customers` |
| 10 | Customer Detail | `/customers/detail` |
| 11 | Customer Profitability | `/customers/profitability` |
| 12 | Facility Operations | `/facilities` |
| 13 | Operational Efficiency | `/operations` |

Detail pages (3, 5, 10) use client-side dropdown selectors — all data is embedded at build time, no server-side rendering required.

## Prerequisites

### Node.js (>= 18) and npm (>= 7)

**macOS:**

```bash
# Using Homebrew
brew install node
```

**Windows:**

Download and run the Node.js installer from https://nodejs.org (LTS version recommended). The installer includes npm. After installation, restart your terminal.

**Linux (Ubuntu/Debian):**

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

**Linux (Fedora/RHEL):**

```bash
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs
```

Verify installation on any platform:

```bash
node --version   # should show v18+ 
npm --version    # should show 7+
```

## Install

```bash
cd evidence-app
npm install
```

## Build

Evidence compiles the dashboard pages against the DuckDB database and generates a static site.

**macOS / Linux:**

```bash
cd evidence-app
npm run sources
npm run build
```

**Windows (Command Prompt):**

```cmd
cd evidence-app
npm run sources
npm run build
```

**Windows (PowerShell):**

```powershell
cd evidence-app
npm run sources
npm run build
```

The build commands are identical across platforms — npm handles the differences.

## Viewing the Production Site

The build output is a SvelteKit SPA. Pages require a web server and cannot be opened directly from the filesystem as local files.

After building, serve the static site:

```bash
cd evidence-app
npx serve build
```

Then open your browser to **http://localhost:3000**.

To specify a different port:

```bash
npx serve build -l 4000
```

To allow access from other machines on your network:

```bash
npx serve build -l tcp://0.0.0.0:3000
```

## Development

To run the Evidence dev server with hot reload:

```bash
cd evidence-app
npm run dev
```

This opens the site at `http://localhost:3000` with live reloading as you edit the markdown pages. The dev server shows query viewers alongside charts for debugging — these are hidden in the production build. If query viewers persist in your browser after switching to the production build, clear your browser's localStorage or use an incognito window.

## Project Structure

```
dbt-project/
├── config/
│   └── clustering.json               ← Data clustering configuration
├── data/
│   ├── logistics.duckdb              ← DuckDB database
│   ├── raw/                          ← Raw CSV source files
│   └── reference/                    ← Reference data files
├── scripts/
│   ├── build.py                      ← Database build script
│   ├── load_raw.py                   ← Raw data loader
│   └── logger.py                     ← Logging utility
├── logistics_modeling/                ← dbt project
│   └── models/
│       ├── staging/                   ← Raw table staging
│       ├── intermediate/              ← Enriched trip grain
│       └── marts/                     ← Analytical models
│           ├── customer_analysis/
│           ├── dimensions/
│           ├── driver_performance/
│           ├── fleet_utilization/
│           └── route_profitability/
├── evidence-app/                      ← Evidence dashboard project
│   ├── sources/logistics/             ← DuckDB connection + source queries
│   ├── pages/                         ← Dashboard markdown pages
│   │   ├── index.md                   ← Executive Summary
│   │   ├── customers/                 ← Customer dashboards
│   │   ├── drivers/                   ← Driver dashboards
│   │   ├── facilities/                ← Facility dashboards
│   │   ├── fleet/                     ← Fleet dashboards
│   │   ├── operations/                ← Operations dashboards
│   │   └── routes/                    ← Route dashboards
│   └── build/                         ← Static site output (after build)
├── visualizations.md                  ← Dashboard specification & decision log
├── mart_models.md                     ← Data mart design document
├── staging_tables.md                  ← Staging layer design document
└── DATABASE_SCHEMA.txt                ← Database schema reference
```

## Documentation

- `visualizations.md` — Full specification for all 13 dashboard pages including queries, charts, and design decisions
- `mart_models.md` — Data mart layer design and model documentation
- `staging_tables.md` — Staging table definitions and source mappings
# Logistics-Data-Modeling
