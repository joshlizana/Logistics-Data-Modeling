
---

## Build: 2026-04-09 18:32 (2.1s)

Created fresh data/logistics.duckdb

Step 1: Loading raw CSVs...
  ✓ customers                               200 rows  (0.04s)
  ✓ delivery_events                      170820 rows  (0.37s)
  ✓ driver_monthly_metrics                 4464 rows  (0.03s)
  ✓ drivers                                 150 rows  (0.01s)
  ✓ facilities                               50 rows  (0.01s)
  ✓ fuel_purchases                       196442 rows  (0.44s)
  ✓ loads                                 85410 rows  (0.19s)
  ✓ maintenance_records                    2920 rows  (0.03s)
  ✓ routes                                   58 rows  (0.01s)
  ✓ safety_incidents                        170 rows  (0.02s)
  ✓ trailers                                180 rows  (0.01s)
  ✓ trips                                 85410 rows  (0.34s)
  ✓ truck_utilization_metrics              3312 rows  (0.03s)
  ✓ trucks                                  120 rows  (0.01s)

  14 tables, 549,706 total rows loaded in 1.56s
Step 1 complete (1.56s)

Step 2: Building reference tables...
  Loaded 15 regions from data/reference/regions.csv
  31257 cities loaded from data/reference/uscities.csv
  30463 continental US cities after cleaning  (0.09s)
  Region assignment complete  (0.04s)
  ✓ cities            30463 rows  (0.09s)
  ✓ city_zips_map     47365 rows  (0.04s)
  ✓ regions              15 rows  (0.04s)
  ✓ lanes               225 rows  (0.02s)  [15×15]
  ✓ facilities.region_id  50/50 assigned  (0.01s)
  ✓ routes.lane_id        58/58 assigned  (0.01s)

  Reference build complete  (0.35s total)
Step 2 complete (0.36s)

Build complete.
