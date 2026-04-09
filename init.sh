#!/usr/bin/env bash
#
# init.sh — Rebuild the logistics DuckDB database, run dbt models,
#            and prepare Evidence sources. After this script completes,
#            you can cd into evidence-app and run: npm run sources && npm run build
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "==> Project directory: $PROJECT_DIR"

# ── 0. Check prerequisites ───────────────────────────────────────────────────
echo ""
echo "==> Checking prerequisites..."
MISSING=()
command -v git     &>/dev/null || MISSING+=("git")
command -v python3 &>/dev/null || MISSING+=("python3")
command -v node    &>/dev/null || MISSING+=("node")
command -v npm     &>/dev/null || MISSING+=("npm")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: The following required tools are not installed: ${MISSING[*]}"
    echo ""
    echo "Install them for your platform, then re-run this script."
    echo "See the README for platform-specific install instructions."
    exit 1
fi

# Windows users also need Microsoft Visual C++ Redistributable
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
    echo ""
    echo "    NOTE (Windows): Ensure Microsoft Visual C++ Redistributable is installed."
    echo "    Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe"
fi

echo "    git     $(git --version | awk '{print $3}')"
echo "    python3 $(python3 --version | awk '{print $2}')"
echo "    node    $(node --version)"
echo "    npm     $(npm --version)"

# ── 1. Python virtual environment ─────────────────────────────────────────────
echo ""
echo "==> Setting up Python virtual environment..."

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "    Created venv/"
else
    echo "    venv/ already exists, reusing"
fi

source venv/bin/activate

echo "    Installing Python dependencies..."
pip install --quiet --upgrade pip
pip install --quiet dbt-core dbt-duckdb duckdb

# ── 2. Rebuild DuckDB database ────────────────────────────────────────────────
echo ""
echo "==> Rebuilding DuckDB database..."
python3 scripts/build.py

# ── 3. Configure dbt profile ─────────────────────────────────────────────────
echo ""
echo "==> Configuring dbt profile..."

mkdir -p "$PROJECT_DIR/logistics_modeling"
cat > "$PROJECT_DIR/logistics_modeling/profiles.yml" <<'EOF'
logistics_modeling:
  outputs:
    dev:
      type: duckdb
      path: '../data/logistics.duckdb'
      threads: 4
  target: dev
EOF
echo "    Wrote logistics_modeling/profiles.yml"

# ── 4. Run dbt ───────────────────────────────────────────────────────────────
echo ""
echo "==> Running dbt models..."
cd "$PROJECT_DIR/logistics_modeling"
dbt run --profiles-dir .
cd "$PROJECT_DIR"

# ── 5. Symlink DuckDB into Evidence sources ───────────────────────────────────
echo ""
echo "==> Linking DuckDB into Evidence sources..."

SOURCES_DIR="$PROJECT_DIR/evidence-app/sources/logistics"
LINK_PATH="$SOURCES_DIR/logistics.duckdb"
DB_PATH="$PROJECT_DIR/data/logistics.duckdb"

mkdir -p "$SOURCES_DIR"

if [ -L "$LINK_PATH" ] || [ -e "$LINK_PATH" ]; then
    rm "$LINK_PATH"
fi
ln -s "$DB_PATH" "$LINK_PATH"
echo "    Symlinked $LINK_PATH -> $DB_PATH"

# ── 6. Install Evidence dependencies ─────────────────────────────────────────
echo ""
echo "==> Installing Evidence dependencies..."
cd "$PROJECT_DIR/evidence-app"
npm install --silent

# ── 7. Build Evidence dashboard ──────────────────────────────────────────────
echo ""
echo "==> Building Evidence dashboard..."
npm run sources
npm run build

# ── 8. Launch ────────────────────────────────────────────────────────────────
echo ""
echo "==> Init complete! Launching dashboard at http://localhost:3000"
echo "    Press Ctrl+C to stop the server."
echo ""
npx serve build
