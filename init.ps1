#
# init.ps1 — Rebuild the logistics DuckDB database, run dbt models,
#             and prepare Evidence sources. After this script completes,
#             cd into evidence-app and run: npm run sources; npm run build
#
# Usage: .\init.ps1
#

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host ""
Write-Host "==> Project directory: $ProjectDir"

# ── 0. Check prerequisites ───────────────────────────────────────────────────
Write-Host ""
Write-Host "==> Checking prerequisites..."

$Missing = @()
if (-not (Get-Command git -ErrorAction SilentlyContinue))     { $Missing += "git" }
if (-not (Get-Command python -ErrorAction SilentlyContinue))   { $Missing += "python" }
if (-not (Get-Command node -ErrorAction SilentlyContinue))     { $Missing += "node" }
if (-not (Get-Command npm -ErrorAction SilentlyContinue))      { $Missing += "npm" }

if ($Missing.Count -gt 0) {
    Write-Host "ERROR: The following required tools are not installed: $($Missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install them for your platform, then re-run this script."
    Write-Host "See the README for platform-specific install instructions."
    Write-Host ""
    Write-Host "NOTE: Windows users also need Microsoft Visual C++ Redistributable:"
    Write-Host "      https://aka.ms/vs/17/release/vc_redist.x64.exe"
    exit 1
}

Write-Host "    git     $(git --version)"
Write-Host "    python  $(python --version)"
Write-Host "    node    $(node --version)"
Write-Host "    npm     $(npm --version)"

# ── 1. Python virtual environment ─────────────────────────────────────────────
Write-Host ""
Write-Host "==> Setting up Python virtual environment..."

if (-not (Test-Path "venv")) {
    python -m venv venv
    Write-Host "    Created venv\"
} else {
    Write-Host "    venv\ already exists, reusing"
}

& "$ProjectDir\venv\Scripts\Activate.ps1"

Write-Host "    Installing Python dependencies..."
python -m pip install --quiet --upgrade pip
python -m pip install --quiet dbt-core dbt-duckdb duckdb

# ── 2. Rebuild DuckDB database ────────────────────────────────────────────────
Write-Host ""
Write-Host "==> Rebuilding DuckDB database..."
python scripts/build.py

# ── 3. Configure dbt profile ─────────────────────────────────────────────────
Write-Host ""
Write-Host "==> Configuring dbt profile..."

$ProfileContent = @"
logistics_modeling:
  outputs:
    dev:
      type: duckdb
      path: '../data/logistics.duckdb'
      threads: 4
  target: dev
"@

Set-Content -Path "$ProjectDir\logistics_modeling\profiles.yml" -Value $ProfileContent -Encoding UTF8
Write-Host "    Wrote logistics_modeling\profiles.yml"

# ── 4. Run dbt ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==> Running dbt models..."
Set-Location "$ProjectDir\logistics_modeling"
dbt run --profiles-dir .
Set-Location $ProjectDir

# ── 5. Copy DuckDB into Evidence sources ──────────────────────────────────────
Write-Host ""
Write-Host "==> Copying DuckDB into Evidence sources..."

$SourcesDir = "$ProjectDir\evidence-app\sources\logistics"
$CopyPath   = "$SourcesDir\logistics.duckdb"
$DbPath     = "$ProjectDir\data\logistics.duckdb"

if (-not (Test-Path $SourcesDir)) {
    New-Item -ItemType Directory -Path $SourcesDir -Force | Out-Null
}

Copy-Item -Path $DbPath -Destination $CopyPath -Force
Write-Host "    Copied $DbPath -> $CopyPath"

# ── 6. Install Evidence dependencies ─────────────────────────────────────────
Write-Host ""
Write-Host "==> Installing Evidence dependencies..."
Set-Location "$ProjectDir\evidence-app"
npm install --silent

# ── 7. Build Evidence dashboard ──────────────────────────────────────────────
Write-Host ""
Write-Host "==> Building Evidence dashboard..."
npm run sources
npm run build

# ── 8. Launch ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==> Init complete! Launching dashboard at http://localhost:3000" -ForegroundColor Green
Write-Host "    Press Ctrl+C to stop the server."
Write-Host ""
npx serve build
