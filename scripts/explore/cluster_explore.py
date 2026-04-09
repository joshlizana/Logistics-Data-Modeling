"""
Cluster Explorer — Interactive
================================
Run once to explore k-means clustering of US cities into geographic regions.
Writes the chosen clustering to data/reference/regions.csv — the static
reference used by build_reference.py on every rebuild.

This script is vestigial after the initial clustering is done. Re-run only
if reclustering is desired (e.g. after major facility changes).

Weighting:
  weight = log(population) × (1 + log(1 + facility_count)) × (1 + 1/ranking)
  facility_count is transient — loaded from the current logistics.duckdb, not stored.

Output:
  - data/reference/regions.csv  ← region_id, region_name, centroid_latitude, centroid_longitude
  - project_log.md              ← run output appended under a timestamped header

Run from project root: python3 scripts/explore/cluster_explore.py
"""

import os
import datetime
import duckdb
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.cluster import KMeans

# Allow running from project root
ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)

DB_PATH     = 'data/logistics.duckdb'
CITIES_CSV  = 'data/reference/uscities.csv'
REGIONS_OUT = 'data/reference/regions.csv'
LOG_PATH    = 'project_log.md'
K_VALUES    = [12, 13, 14, 15]

# ── Logging ────────────────────────────────────────────────────────────────────
_log_lines = []

def log(msg=''):
    print(msg)
    _log_lines.append(str(msg))

def flush_log():
    run_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
    with open(LOG_PATH, 'a') as f:
        f.write(f"\n---\n\n## Cluster Explore Run: {run_time}\n\n")
        f.write('\n'.join(_log_lines) + '\n')

# ── Step 1: Load cities ────────────────────────────────────────────────────────
log(f"Loading cities from {CITIES_CSV}...")
cities_raw = pd.read_csv(CITIES_CSV)
log(f"  {len(cities_raw)} cities loaded\n")

cities = cities_raw[[
    'city', 'state_id', 'lat', 'lng', 'population', 'ranking'
]].copy()

cities.columns = ['city', 'state', 'latitude', 'longitude', 'population', 'ranking']

# Exclude non-continental US territories
EXCLUDE_STATES = {'AK', 'HI', 'PR', 'VI', 'GU', 'MP', 'AS'}
cities = cities[~cities['state'].isin(EXCLUDE_STATES)]
cities = cities.dropna(subset=['latitude', 'longitude', 'population', 'ranking'])
cities['population'] = cities['population'].astype(int)
cities['ranking']    = cities['ranking'].astype(int)

log(f"After cleaning: {len(cities)} continental US cities\n")

# ── Step 2: Transient facility counts ─────────────────────────────────────────
conn = duckdb.connect(DB_PATH, read_only=True)
facility_counts = conn.execute("""
    SELECT city, state, COUNT(*) AS facility_count
    FROM facilities
    GROUP BY city, state
""").fetchdf()
conn.close()

cities = cities.merge(facility_counts, on=['city', 'state'], how='left')
cities['facility_count'] = cities['facility_count'].fillna(0).astype(int)
log(f"Cities with facilities: {(cities['facility_count'] > 0).sum()}\n")

# ── Step 3: Compute weights ────────────────────────────────────────────────────
# weight = log(population) × (1 + log(1 + facility_count)) × (1 + 1/ranking)
#
# facility_multiplier = 1 + log(1 + facility_count)
#   0 facilities  → ×1.00
#   1 facility    → ×1.69
#   5 facilities  → ×2.79
#   12 facilities → ×3.56
#
# ranking_multiplier = 1 + 1/ranking
#   rank 1 (major metro) → ×2.00
#   rank 2 (mid-size)    → ×1.50
#   rank 3 (small)       → ×1.33
cities['weight'] = (
    np.log1p(cities['population']) *
    (1 + np.log1p(cities['facility_count'])) *
    (1 + 1 / cities['ranking'])
)

log("=== Weight distribution — facility cities ===")
log(
    cities[cities['facility_count'] > 0]
    [['city', 'state', 'population', 'ranking', 'facility_count', 'weight']]
    .sort_values('weight', ascending=False)
    .to_string(index=False)
)
log()

# ── Step 4: Run k-means across K_VALUES ───────────────────────────────────────
coords  = cities[['latitude', 'longitude']].values
weights = cities['weight'].values

log("=== k-means inertia by k (lower = tighter clusters) ===")
results = {}
rng = np.random.default_rng()
for k in K_VALUES:
    seed = int(rng.integers(0, 2**31))
    km = KMeans(n_clusters=k, n_init=20, random_state=seed)
    km.fit(coords, sample_weight=weights)
    cities[f'cluster_k{k}'] = km.labels_
    results[k] = km
    log(f"  k={k}: inertia={km.inertia_:.0f}")
log()

for k in K_VALUES:
    km = results[k]
    log(f"=== k={k} cluster membership (top cities by weight) ===")
    for cid in range(k):
        group    = cities[cities[f'cluster_k{k}'] == cid]
        centroid = km.cluster_centers_[cid]
        top_cities = (
            group.nlargest(3, 'weight')[['city', 'state']]
            .apply(lambda r: f"{r['city']}, {r['state']}", axis=1)
            .tolist()
        )
        log(
            f"  Cluster {cid:2d} ({len(group):4d} cities, "
            f"centroid: {centroid[0]:.1f}N {centroid[1]:.1f}W): "
            f"{', '.join(top_cities)}"
        )
    log()

# ── Step 5: Select k ──────────────────────────────────────────────────────────
while True:
    try:
        chosen_k = int(input(f"Select k ({'/'.join(str(k) for k in K_VALUES)}): "))
        if chosen_k in K_VALUES:
            break
        print(f"  Please enter one of {K_VALUES}")
    except ValueError:
        print("  Please enter a number")

km = results[chosen_k]
cities['region_cluster'] = cities[f'cluster_k{chosen_k}']
log(f"Selected k={chosen_k}\n")

# ── Step 6: Write regions.csv (unnamed) ───────────────────────────────────────
log("=== Clusters written to regions.csv (add region_name manually) ===")
regions_rows = []
for cid in range(chosen_k):
    group    = cities[cities['region_cluster'] == cid]
    centroid = km.cluster_centers_[cid]
    top_cities = (
        group.nlargest(5, 'weight')[['city', 'state']]
        .apply(lambda r: f"{r['city']}, {r['state']}", axis=1)
        .tolist()
    )
    regions_rows.append({
        'region_id':          f"RGN{cid:05d}",
        'region_name':        '',
        'centroid_latitude':  round(float(centroid[0]), 4),
        'centroid_longitude': round(float(centroid[1]), 4),
        'top_cities':         ', '.join(top_cities),
    })
    log(f"  RGN{cid:05d}: centroid {centroid[0]:.1f}N {centroid[1]:.1f}W — {', '.join(top_cities)}")
log()

# ── Step 7: Write regions.csv ──────────────────────────────────────────────────
regions_df = pd.DataFrame(regions_rows)
regions_df.to_csv(REGIONS_OUT, index=False)

log(f"Regions written to {REGIONS_OUT}")
log("Edit region_name in that file, then run 'python3 scripts/build.py'.")

# ── Flush log ──────────────────────────────────────────────────────────────────
flush_log()
print(f"\nOutput appended to {LOG_PATH}")
print(f"Edit region_name in {REGIONS_OUT}, then run 'python3 scripts/build.py'.")
print(f"Run 'python3 scripts/build.py' to do a full rebuild.")
