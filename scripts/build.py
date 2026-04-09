"""
Build — Full Database Rebuild
==============================
Single entrypoint to rebuild logistics.duckdb from scratch.
Fully non-interactive — requires data/reference/regions.csv to exist.

Steps:
  1. Drop and recreate data/logistics.duckdb
  2. Load raw operational CSVs from data/raw/
  3. Build reference tables (cities, regions, lanes) and update FKs

To generate data/reference/regions.csv, run scripts/explore/cluster_explore.py first.

Run: python3 scripts/build.py
"""

import os
import sys
import time
import duckdb

sys.path.insert(0, os.path.dirname(__file__))

from logger import BuildLogger
from load_raw import load_raw
from build_reference import build_reference

DB_PATH     = 'data/logistics.duckdb'
REGIONS_CSV = 'data/reference/regions.csv'
RAW_DIR     = 'data/raw'
CITIES_CSV  = 'data/reference/uscities.csv'


def main():
    log = BuildLogger("Build")

    # ── Preflight checks ───────────────────────────────────────────────────────
    if not os.path.exists(REGIONS_CSV):
        print(f"ERROR: {REGIONS_CSV} not found.")
        print("Run scripts/explore/cluster_explore.py first to generate regions.")
        sys.exit(1)

    if not os.path.exists(CITIES_CSV):
        print(f"ERROR: {CITIES_CSV} not found.")
        print("Download uscities.csv from simplemaps.com/data/us-cities and place it in data/reference/")
        sys.exit(1)

    # ── Rebuild database ───────────────────────────────────────────────────────
    for path in [DB_PATH, DB_PATH + '.wal']:
        if os.path.exists(path):
            os.remove(path)
            log(f"Removed existing {path}")

    conn = duckdb.connect(DB_PATH)
    log(f"Created fresh {DB_PATH}\n")

    # ── Step 1: Load raw CSVs ──────────────────────────────────────────────────
    t = time.perf_counter()
    log("Step 1: Loading raw CSVs...")
    load_raw(conn, raw_dir=RAW_DIR, log=log)
    log(f"Step 1 complete ({time.perf_counter()-t:.2f}s)\n")

    # ── Step 2: Build reference tables ────────────────────────────────────────
    t = time.perf_counter()
    log("Step 2: Building reference tables...")
    build_reference(conn, cities_csv=CITIES_CSV, regions_csv=REGIONS_CSV, log=log)
    log(f"Step 2 complete ({time.perf_counter()-t:.2f}s)\n")

    conn.close()
    log("Build complete.")
    log.flush()


if __name__ == '__main__':
    main()
