"""
Load Raw CSVs
=============
Loads all operational CSVs from data/raw/ into DuckDB as tables.
Table names are derived from the CSV filename (stem).

Called by build.py — not intended to be run standalone.
"""

import time
import duckdb
from pathlib import Path


def load_raw(conn: duckdb.DuckDBPyConnection,
             raw_dir: str = 'data/raw',
             log=print) -> None:
    t0 = time.perf_counter()
    csv_dir = Path(raw_dir)
    tables = []
    for csv_file in sorted(csv_dir.glob('*.csv')):
        t = time.perf_counter()
        table_name = csv_file.stem
        conn.execute(f"""
            CREATE OR REPLACE TABLE {table_name} AS
            SELECT * FROM read_csv_auto('{csv_file}')
        """)
        count = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
        elapsed = time.perf_counter() - t
        tables.append((table_name, count, elapsed))
        log(f"  ✓ {table_name:<35} {count:>7} rows  ({elapsed:.2f}s)")

    total_rows = sum(c for _, c, _ in tables)
    total_time = time.perf_counter() - t0
    log(f"\n  {len(tables)} tables, {total_rows:,} total rows loaded in {total_time:.2f}s")


if __name__ == '__main__':
    import os, sys
    sys.path.insert(0, os.path.dirname(__file__))
    from logger import BuildLogger
    log = BuildLogger("load_raw")
    conn = duckdb.connect('data/logistics.duckdb')
    log("Loading raw CSVs...")
    load_raw(conn, log=log)
    conn.close()
    log.flush()
