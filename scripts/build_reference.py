"""
Build Reference Tables
=======================
Builds all reference and enrichment tables in DuckDB using the cities CSV
and the static regions reference. Fully non-interactive and deterministic —
no k-means fitting, no random seeds.

Region assignment: cities are assigned to the nearest region centroid using
KMeans.predict() with the stored centroids from data/reference/regions.csv.

Tables created/updated:
  - cities          : all US cities with city_id PK and region_id FK
  - city_zips_map   : normalized ZIP codes — city_id, zip
  - regions         : one row per region — region_id, region_name, centroid lat/lon
  - lanes           : cartesian product of regions × regions
  - facilities      : region_id FK updated
  - routes          : lane_id FK updated

Called by build.py — not intended to be run standalone.
"""

import time
import duckdb
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans


def build_reference(conn: duckdb.DuckDBPyConnection,
                    cities_csv: str = 'data/reference/uscities.csv',
                    regions_csv: str = 'data/reference/regions.csv',
                    log=print) -> None:

    t_total = time.perf_counter()

    # ── Load regions reference ─────────────────────────────────────────────────
    regions_df = pd.read_csv(regions_csv)
    k = len(regions_df)
    regions_df = regions_df.sort_values('region_id').reset_index(drop=True)
    centers = regions_df[['centroid_latitude', 'centroid_longitude']].values
    log(f"  Loaded {k} regions from {regions_csv}")

    # ── Load and clean cities CSV ──────────────────────────────────────────────
    t = time.perf_counter()
    cities_raw = pd.read_csv(cities_csv)
    log(f"  {len(cities_raw)} cities loaded from {cities_csv}")

    cities = cities_raw[[
        'city', 'city_ascii', 'state_id', 'state_name',
        'county_fips', 'county_name', 'lat', 'lng',
        'population', 'density', 'military', 'incorporated',
        'timezone', 'ranking', 'zips'
    ]].copy()
    cities.columns = [
        'city', 'city_ascii', 'state', 'state_name',
        'county_fips', 'county_name', 'latitude', 'longitude',
        'population', 'density', 'military', 'incorporated',
        'timezone', 'ranking', 'zips'
    ]

    EXCLUDE_STATES = {'AK', 'HI', 'PR', 'VI', 'GU', 'MP', 'AS'}
    cities = cities[~cities['state'].isin(EXCLUDE_STATES)]
    cities = cities.dropna(subset=['latitude', 'longitude', 'population', 'ranking'])
    cities['population']   = cities['population'].astype(int)
    cities['ranking']      = cities['ranking'].astype(int)
    cities['density']      = pd.to_numeric(cities['density'], errors='coerce')
    cities['military']     = cities['military'].astype(str).str.upper() == 'TRUE'
    cities['incorporated'] = cities['incorporated'].astype(str).str.upper() == 'TRUE'
    log(f"  {len(cities)} continental US cities after cleaning  ({time.perf_counter()-t:.2f}s)")

    # ── Assign region_id via nearest centroid ──────────────────────────────────
    t = time.perf_counter()
    km = KMeans(n_clusters=k, init=centers, n_init=1, max_iter=1)
    km.fit(centers)
    cluster_ids = km.predict(cities[['latitude', 'longitude']].values)
    cities['region_id'] = regions_df.loc[cluster_ids, 'region_id'].values
    cities['city_id']   = [f"CTY{i:05d}" for i in range(len(cities))]
    log(f"  Region assignment complete  ({time.perf_counter()-t:.2f}s)")

    # ── Write cities ───────────────────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("DROP TABLE IF EXISTS cities")
    conn.execute("""
        CREATE TABLE cities (
            city_id      VARCHAR,
            city         VARCHAR,
            city_ascii   VARCHAR,
            state        VARCHAR,
            state_name   VARCHAR,
            county_fips  VARCHAR,
            county_name  VARCHAR,
            latitude     DOUBLE,
            longitude    DOUBLE,
            population   INTEGER,
            density      DOUBLE,
            military     BOOLEAN,
            incorporated BOOLEAN,
            timezone     VARCHAR,
            ranking      INTEGER,
            region_id    VARCHAR
        )
    """)
    cities_out = cities[[
        'city_id', 'city', 'city_ascii', 'state', 'state_name',
        'county_fips', 'county_name', 'latitude', 'longitude',
        'population', 'density', 'military', 'incorporated',
        'timezone', 'ranking', 'region_id'
    ]].copy()
    cities_out['city_id']      = cities_out['city_id'].astype('string')
    cities_out['city']         = cities_out['city'].astype('string')
    cities_out['city_ascii']   = cities_out['city_ascii'].astype('string')
    cities_out['state']        = cities_out['state'].astype('string')
    cities_out['state_name']   = cities_out['state_name'].astype('string')
    cities_out['county_fips']  = cities_out['county_fips'].astype('string')
    cities_out['county_name']  = cities_out['county_name'].astype('string')
    cities_out['latitude']     = cities_out['latitude'].astype('float64')
    cities_out['longitude']    = cities_out['longitude'].astype('float64')
    cities_out['population']   = cities_out['population'].astype('int32')
    cities_out['density']      = cities_out['density'].astype('float64')
    cities_out['military']     = cities_out['military'].astype('boolean')
    cities_out['incorporated'] = cities_out['incorporated'].astype('boolean')
    cities_out['timezone']     = cities_out['timezone'].astype('string')
    cities_out['ranking']      = cities_out['ranking'].astype('int32')
    cities_out['region_id']    = cities_out['region_id'].astype('string')
    conn.register("cities_out", cities_out)
    conn.execute("INSERT INTO cities SELECT * FROM cities_out")
    conn.unregister("cities_out")
    log(f"  ✓ cities          {len(cities_out):>7} rows  ({time.perf_counter()-t:.2f}s)")

    # ── Write city_zips_map ────────────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("DROP TABLE IF EXISTS city_zips_map")
    conn.execute("""
        CREATE TABLE city_zips_map (
            city_id VARCHAR,
            zip     VARCHAR
        )
    """)
    zips_df = cities[['city_id', 'zips']].dropna(subset=['zips']).copy()
    zips_df['zips'] = zips_df['zips'].astype(str).str.split()
    zips_df = zips_df.explode('zips').rename(columns={'zips': 'zip'})
    zips_df['city_id'] = zips_df['city_id'].astype('string')
    zips_df['zip']     = zips_df['zip'].astype('string')
    conn.execute("INSERT INTO city_zips_map SELECT city_id, zip FROM zips_df")
    log(f"  ✓ city_zips_map   {len(zips_df):>7} rows  ({time.perf_counter()-t:.2f}s)")

    # ── Write regions ──────────────────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("DROP TABLE IF EXISTS regions")
    conn.execute("""
        CREATE TABLE regions (
            region_id          VARCHAR,
            region_name        VARCHAR,
            centroid_latitude  DOUBLE,
            centroid_longitude DOUBLE
        )
    """)
    conn.executemany(
        "INSERT INTO regions VALUES (?, ?, ?, ?)",
        regions_df[['region_id', 'region_name', 'centroid_latitude', 'centroid_longitude']].values.tolist()
    )
    log(f"  ✓ regions         {len(regions_df):>7} rows  ({time.perf_counter()-t:.2f}s)")

    # ── Write lanes ────────────────────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("DROP TABLE IF EXISTS lanes")
    conn.execute("""
        CREATE TABLE lanes AS
        WITH cartesian AS (
            SELECT
                r1.region_id AS origin_region_id,
                r2.region_id AS destination_region_id,
                CASE WHEN r1.region_id = r2.region_id
                     THEN 'local' ELSE 'over_the_road' END AS lane_type
            FROM regions r1 CROSS JOIN regions r2
        )
        SELECT
            printf('LNE%05d', ROW_NUMBER() OVER (
                ORDER BY origin_region_id, destination_region_id
            ) - 1) AS lane_id,
            origin_region_id,
            destination_region_id,
            lane_type
        FROM cartesian
        ORDER BY origin_region_id, destination_region_id
    """)
    lane_count = conn.execute("SELECT COUNT(*) FROM lanes").fetchone()[0]
    log(f"  ✓ lanes           {lane_count:>7} rows  ({time.perf_counter()-t:.2f}s)  [{k}×{k}]")

    # ── Update facilities.region_id ────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("ALTER TABLE facilities DROP COLUMN IF EXISTS region_id")
    conn.execute("ALTER TABLE facilities ADD COLUMN region_id VARCHAR")
    conn.execute("""
        UPDATE facilities
        SET region_id = c.region_id
        FROM cities c
        WHERE facilities.city = c.city
          AND facilities.state = c.state
    """)
    f_assigned = conn.execute("SELECT COUNT(*) FROM facilities WHERE region_id IS NOT NULL").fetchone()[0]
    f_total    = conn.execute("SELECT COUNT(*) FROM facilities").fetchone()[0]
    log(f"  ✓ facilities.region_id  {f_assigned}/{f_total} assigned  ({time.perf_counter()-t:.2f}s)")

    # ── Update routes.lane_id ──────────────────────────────────────────────────
    t = time.perf_counter()
    conn.execute("ALTER TABLE routes DROP COLUMN IF EXISTS lane_id")
    conn.execute("ALTER TABLE routes ADD COLUMN lane_id VARCHAR")
    conn.execute("""
        UPDATE routes
        SET lane_id = l.lane_id
        FROM cities c_orig
        JOIN cities c_dest ON TRUE
        JOIN lanes l
          ON l.origin_region_id      = c_orig.region_id
         AND l.destination_region_id = c_dest.region_id
        WHERE routes.origin_city       = c_orig.city
          AND routes.origin_state      = c_orig.state
          AND routes.destination_city  = c_dest.city
          AND routes.destination_state = c_dest.state
    """)
    r_assigned = conn.execute("SELECT COUNT(*) FROM routes WHERE lane_id IS NOT NULL").fetchone()[0]
    r_total    = conn.execute("SELECT COUNT(*) FROM routes").fetchone()[0]
    log(f"  ✓ routes.lane_id        {r_assigned}/{r_total} assigned  ({time.perf_counter()-t:.2f}s)")

    if r_assigned < r_total:
        unassigned = conn.execute("""
            SELECT route_id, origin_city, origin_state, destination_city, destination_state
            FROM routes WHERE lane_id IS NULL
            ORDER BY origin_state, destination_state
        """).fetchdf()
        log(f"\n  ⚠ {r_total - r_assigned} routes unassigned:")
        log(unassigned.to_string(index=False))

    log(f"\n  Reference build complete  ({time.perf_counter()-t_total:.2f}s total)")


if __name__ == '__main__':
    import os, sys
    sys.path.insert(0, os.path.dirname(__file__))
    from logger import BuildLogger
    log = BuildLogger("build_reference")
    conn = duckdb.connect('data/logistics.duckdb')
    log("Building reference tables...")
    build_reference(conn, log=log)
    conn.close()
    log.flush()
