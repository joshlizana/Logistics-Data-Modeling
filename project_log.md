# Logistics Analytics Project Log

## Summary

A logistics analytics platform built on DuckDB and dbt, modeling a trucking/freight company's operations. The project ingests 14 raw operational CSVs, enriches them with geographic reference data, and will expose business-ready analytical models via a dbt staging + marts architecture.

### Data sources
- **14 operational CSVs** (`data/raw/`) — drivers, trucks, trailers, customers, facilities, routes, loads, trips, fuel purchases, maintenance records, delivery events, safety incidents, and pre-aggregated monthly metrics (549,706 rows total)
- **SimpleMaps US cities** (`data/reference/uscities.csv`) — ~31k US cities with population, coordinates, county, timezone, density, ranking

### Reference tables
- **`cities`** — 30,463 continental US cities with `city_id` PK and `region_id` FK; authoritative city→region lookup
- **`city_zips_map`** — normalized ZIP codes, one row per city/zip pair (47,365 rows)
- **`regions`** — 15 geographic clusters derived from weighted k-means on all US cities; centroids stored statically in `data/reference/regions.csv`
- **`lanes`** — cartesian product of `regions × regions` (225 lanes); classifies origin→destination pairs as `local` or `over_the_road`

### Regions (k=15 weighted k-means)

Clustering uses all ~30k continental US cities, weighted by `log(population) × (1 + log(1 + facility_count)) × (1 + 1/ranking)` — anchors clusters around the operational footprint while covering every city. `cluster_explore.py` runs k-means interactively and writes centroids to `regions.csv`; `build_reference.py` assigns cities deterministically via `KMeans.predict()` on those stored centroids.

| region_id | region_name | Top cities |
|-----------|-------------|------------|
| RGN00000 | Northwest1 | Portland, Seattle, Spokane |
| RGN00001 | Southeast1 | Atlanta, Charlotte, Raleigh |
| RGN00002 | Southwest1 | Houston, Dallas, San Antonio |
| RGN00003 | Midwest1 | Milwaukee, Chicago, St. Louis |
| RGN00004 | West | Las Vegas, Los Angeles, San Francisco |
| RGN00005 | Midwest2 | Kansas City, Oklahoma City, Tulsa |
| RGN00006 | Northeast | Philadelphia, New York, Boston |
| RGN00007 | Mountain | Denver, Colorado Springs, Aurora |
| RGN00008 | South | Nashville, Memphis, New Orleans |
| RGN00009 | Southeast2 | Miami, Tampa, Orlando |
| RGN00010 | Northwest2 | Salt Lake City, Provo, Boise |
| RGN00011 | Midwest3 | Omaha, Minneapolis, Des Moines |
| RGN00012 | MidAtlantic | Washington DC, Baltimore, Pittsburgh |
| RGN00013 | Southwest2 | Phoenix, Tucson, Albuquerque |
| RGN00014 | Midwest4 | Detroit, Indianapolis, Cincinnati |

### Enrichment applied to operational tables
- **`facilities.region_id`** — FK to `regions`, assigned via city/state match to `cities`; 50/50 assigned
- **`routes.lane_id`** — FK to `lanes`, assigned by matching origin/destination city→region→lane; 58/58 assigned

### Project structure
```
data/
  raw/                   ← operational logistics CSVs
  reference/
    uscities.csv         ← SimpleMaps US cities (downloaded)
    regions.csv          ← cluster centroids + names, written by cluster_explore.py
  logistics.duckdb

scripts/
  build.py               ← full non-interactive rebuild (~2s)
  load_raw.py            ← loads data/raw/*.csv into DuckDB
  build_reference.py     ← builds cities, regions, lanes; assigns region_id via KMeans.predict()
  explore/
    cluster_explore.py   ← run once interactively; writes data/reference/regions.csv (no names)
                            manually fill region_name, then run build.py
```

### Build pipeline
```
python3 scripts/explore/cluster_explore.py   # one-time — outputs regions.csv, fill in region_name manually
python3 scripts/build.py                     # full rebuild from scratch
```

### dbt models (next)
Two-layer architecture: `staging/` (views, light cleaning) → `marts/` (tables, aggregations).
Four analytical areas: driver performance, route profitability, fleet utilization, customer analysis.

---

## Log

---

## Explore Run: 2026-04-07 03:21

Loading cities from data/reference/uscities.csv...
  31257 cities loaded

After cleaning: 30463 cities
  Military installations: 87
  Incorporated municipalities: 20078

Cities with facilities: 21

=== Weight distribution — facility cities ===
          city state  population  ranking  facility_count    weight
       Atlanta    GA     5298788        1               4 80.803796
       Detroit    MI     3773725        1               4 79.032429
     Nashville    TN     1201962        1               5 78.166287
  Indianapolis    IN     1767321        1               4 75.073403
         Miami    FL     6391670        1               3 74.788882
       Houston    TX     6227666        1               3 74.664823
     Las Vegas    NV     2299189        1               3 69.909201
   Los Angeles    CA    11984083        1               2 68.410941
     Charlotte    NC     1488249        1               3 67.833336
        Dallas    TX     5968322        1               2 65.484999
  Philadelphia    PA     5782653        1               2 65.352354
       Phoenix    AZ     4121103        1               2 63.930579
      Portland    OR     2115140        1               2 61.131032
     Milwaukee    WI     1291752        1               2 59.061291
Salt Lake City    UT     1183003        1               2 58.692173
      New York    NY    19268388        1               1 56.801622
       Chicago    IL     8609571        1               1 54.073653
        Denver    CO     2714768        1               1 50.165301
   Kansas City    MO     1714910        1               1 48.609821
 Oklahoma City    OK     1017828        1               1 46.843228
         Omaha    NE      836740        2               2 42.929013

=== k-means inertia by k (lower = tighter clusters) ===
  k=12: inertia=2764059, random_state=1090976415
  k=13: inertia=2484311, random_state=1770047926
  k=14: inertia=2284994, random_state=556253356
  k=15: inertia=2102044, random_state=687767813

=== k=12 cluster membership (facility cities only) ===
  Cluster  0 (1145 cities, centroid: 43.9N -110.4W): Salt Lake City, UT
  Cluster  1 (3933 cities, centroid: 38.1N -80.6W): Charlotte, NC
  Cluster  2 (2623 cities, centroid: 33.8N -88.0W): Atlanta, GA, Nashville, TN
  Cluster  3 (1272 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster  4 (2878 cities, centroid: 44.4N -95.1W): Omaha, NE
  Cluster  5 (1729 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  6 (1632 cities, centroid: 36.1N -107.1W): Denver, CO, Phoenix, AZ
  Cluster  7 (4120 cities, centroid: 40.8N -75.1W): New York, NY, Philadelphia, PA
  Cluster  8 (2874 cities, centroid: 37.9N -95.8W): Kansas City, MO, Oklahoma City, OK
  Cluster  9 (4795 cities, centroid: 41.1N -87.3W): Chicago, IL, Detroit, MI, Indianapolis, IN, Milwaukee, WI
  Cluster 10 (2125 cities, centroid: 31.0N -96.7W): Dallas, TX, Houston, TX
  Cluster 11 (1337 cities, centroid: 29.2N -81.8W): Miami, FL

=== k=13 cluster membership (facility cities only) ===
  Cluster  0 (3359 cities, centroid: 40.5N -82.8W): Detroit, MI
  Cluster  1 (1123 cities, centroid: 44.0N -110.5W): Salt Lake City, UT
  Cluster  2 (2729 cities, centroid: 37.9N -96.1W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  3 (2379 cities, centroid: 35.1N -81.4W): Atlanta, GA, Charlotte, NC
  Cluster  4 (1997 cities, centroid: 31.0N -97.0W): Dallas, TX, Houston, TX
  Cluster  5 (4555 cities, centroid: 40.6N -75.3W): New York, NY, Philadelphia, PA
  Cluster  6 (1724 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  7 (3728 cities, centroid: 41.2N -88.9W): Chicago, IL, Indianapolis, IN, Milwaukee, WI
  Cluster  8 (1603 cities, centroid: 36.2N -107.3W): Denver, CO, Phoenix, AZ
  Cluster  9 (2546 cities, centroid: 44.6N -95.6W): (no facilities)
  Cluster 10 ( 997 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster 11 (1269 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster 12 (2454 cities, centroid: 33.5N -89.0W): Nashville, TN

=== k=14 cluster membership (facility cities only) ===
  Cluster  0 (1238 cities, centroid: 46.0N -121.5W): Portland, OR
  Cluster  1 (2246 cities, centroid: 34.9N -81.7W): Atlanta, GA, Charlotte, NC
  Cluster  2 (3327 cities, centroid: 41.5N -89.6W): Chicago, IL, Milwaukee, WI
  Cluster  3 (1629 cities, centroid: 36.2N -107.1W): Denver, CO, Phoenix, AZ
  Cluster  4 (2635 cities, centroid: 37.7N -96.0W): Kansas City, MO, Oklahoma City, OK
  Cluster  5 (2682 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA
  Cluster  6 (1723 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  7 (2504 cities, centroid: 44.6N -96.2W): Omaha, NE
  Cluster  8 ( 985 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster  9 (3060 cities, centroid: 39.7N -78.2W): (no facilities)
  Cluster 10 (1939 cities, centroid: 30.9N -97.0W): Dallas, TX, Houston, TX
  Cluster 11 (2988 cities, centroid: 40.6N -84.4W): Detroit, MI, Indianapolis, IN
  Cluster 12 (1094 cities, centroid: 43.9N -111.2W): Salt Lake City, UT
  Cluster 13 (2413 cities, centroid: 33.5N -89.0W): Nashville, TN

=== k=15 cluster membership (facility cities only) ===
  Cluster  0 (3042 cities, centroid: 39.6N -78.2W): (no facilities)
  Cluster  1 (1005 cities, centroid: 44.0N -112.1W): Salt Lake City, UT
  Cluster  2 (3230 cities, centroid: 41.3N -89.4W): Chicago, IL, Milwaukee, WI
  Cluster  3 (2229 cities, centroid: 34.9N -81.8W): Atlanta, GA, Charlotte, NC
  Cluster  4 (1175 cities, centroid: 46.0N -121.6W): Portland, OR
  Cluster  5 (1973 cities, centroid: 30.9N -97.2W): Dallas, TX, Houston, TX
  Cluster  6 (2366 cities, centroid: 33.5N -89.0W): Nashville, TN
  Cluster  7 (1159 cities, centroid: 34.7N -109.3W): Phoenix, AZ
  Cluster  8 (2463 cities, centroid: 44.5N -95.3W): Omaha, NE
  Cluster  9 (2507 cities, centroid: 37.5N -95.6W): Kansas City, MO, Oklahoma City, OK
  Cluster 10 (2917 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN
  Cluster 11 (2701 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA
  Cluster 12 ( 983 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster 13 (1632 cities, centroid: 36.5N -119.8W): Las Vegas, NV, Los Angeles, CA
  Cluster 14 (1081 cities, centroid: 41.0N -103.5W): Denver, CO

Selected k=15, random_state=687767813 (verified reproducible)

=== Region naming ===
  Cluster 0 → Southwest1 (centroid: 43.9N -111.4W, facility cities: Salt Lake City, UT)
  Cluster 1 → Florida (centroid: 33.5N -89.1W, facility cities: Nashville, TN)
  Cluster 2 → Northwest (centroid: 38.1N -121.2W, facility cities: none)
  Cluster 3 → MidAtlantic (centroid: 39.6N -78.4W, facility cities: none)
  Cluster 4 → Midwest2 (centroid: 44.7N -95.9W, facility cities: Omaha, NE)
  Cluster 5 → West (centroid: 41.4N -89.6W, facility cities: Chicago, IL, Milwaukee, WI)
  Cluster 6 → Midwest1 (centroid: 37.4N -105.3W, facility cities: Denver, CO)
  Cluster 7 → Midwest3 (centroid: 46.3N -121.4W, facility cities: Portland, OR)
  Cluster 8 → Northwest3 (centroid: 30.9N -97.0W, facility cities: Dallas, TX, Houston, TX)
  Cluster 9 → Southwest2 (centroid: 41.2N -74.2W, facility cities: New York, NY, Philadelphia, PA)
  Cluster 10 → Southeast (centroid: 28.1N -81.8W, facility cities: Miami, FL)
  Cluster 11 → South (centroid: 37.8N -95.8W, facility cities: Kansas City, MO, Oklahoma City, OK)
  Cluster 12 → Midwest4 (centroid: 40.6N -84.4W, facility cities: Detroit, MI, Indianapolis, IN)
  Cluster 13 → Northeast (centroid: 34.8N -81.8W, facility cities: Atlanta, GA, Charlotte, NC)
  Cluster 14 → Northwest2 (centroid: 34.1N -115.2W, facility cities: Las Vegas, NV, Los Angeles, CA, Phoenix, AZ)

Config written to config/clustering.json:
{
    "k": 15,
    "random_state": 687767813,
    "n_init": 1,
    "region_names": {
        "0": "Southwest1",
        "1": "Florida",
        "2": "Northwest",
        "3": "MidAtlantic",
        "4": "Midwest2",
        "5": "West",
        "6": "Midwest1",
        "7": "Midwest3",
        "8": "Northwest3",
        "9": "Southwest2",
        "10": "Southeast",
        "11": "South",
        "12": "Midwest4",
        "13": "Northeast",
        "14": "Northwest2"
    }
}

---

## Explore Run: 2026-04-07 03:23

Loading cities from data/reference/uscities.csv...
  31257 cities loaded

After cleaning: 30463 cities
  Military installations: 87
  Incorporated municipalities: 20078

Cities with facilities: 21

=== Weight distribution — facility cities ===
          city state  population  ranking  facility_count    weight
       Atlanta    GA     5298788        1               4 80.803796
       Detroit    MI     3773725        1               4 79.032429
     Nashville    TN     1201962        1               5 78.166287
  Indianapolis    IN     1767321        1               4 75.073403
         Miami    FL     6391670        1               3 74.788882
       Houston    TX     6227666        1               3 74.664823
     Las Vegas    NV     2299189        1               3 69.909201
   Los Angeles    CA    11984083        1               2 68.410941
     Charlotte    NC     1488249        1               3 67.833336
        Dallas    TX     5968322        1               2 65.484999
  Philadelphia    PA     5782653        1               2 65.352354
       Phoenix    AZ     4121103        1               2 63.930579
      Portland    OR     2115140        1               2 61.131032
     Milwaukee    WI     1291752        1               2 59.061291
Salt Lake City    UT     1183003        1               2 58.692173
      New York    NY    19268388        1               1 56.801622
       Chicago    IL     8609571        1               1 54.073653
        Denver    CO     2714768        1               1 50.165301
   Kansas City    MO     1714910        1               1 48.609821
 Oklahoma City    OK     1017828        1               1 46.843228
         Omaha    NE      836740        2               2 42.929013

=== k-means inertia by k (lower = tighter clusters) ===
  k=12: inertia=2764023, random_state=749002653
  k=13: inertia=2484282, random_state=1991801222
  k=14: inertia=2284507, random_state=132199262
  k=15: inertia=2107515, random_state=738724801

=== k=12 cluster membership (facility cities only) ===
  Cluster  0 (4127 cities, centroid: 40.8N -75.1W): New York, NY, Philadelphia, PA
  Cluster  1 (2877 cities, centroid: 37.9N -95.7W): Kansas City, MO, Oklahoma City, OK
  Cluster  2 (1139 cities, centroid: 43.9N -110.5W): Salt Lake City, UT
  Cluster  3 (4802 cities, centroid: 41.1N -87.3W): Chicago, IL, Detroit, MI, Indianapolis, IN, Milwaukee, WI
  Cluster  4 (1332 cities, centroid: 29.2N -81.8W): Miami, FL
  Cluster  5 (1270 cities, centroid: 45.9N -121.4W): Portland, OR
  Cluster  6 (2137 cities, centroid: 31.0N -96.6W): Dallas, TX, Houston, TX
  Cluster  7 (2623 cities, centroid: 33.8N -88.0W): Atlanta, GA, Nashville, TN
  Cluster  8 (2863 cities, centroid: 44.4N -95.2W): Omaha, NE
  Cluster  9 (3927 cities, centroid: 38.1N -80.7W): Charlotte, NC
  Cluster 10 (1636 cities, centroid: 36.2N -107.1W): Denver, CO, Phoenix, AZ
  Cluster 11 (1730 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA

=== k=13 cluster membership (facility cities only) ===
  Cluster  0 ( 997 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster  1 (2725 cities, centroid: 38.0N -96.1W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  2 (1723 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  3 (2375 cities, centroid: 35.1N -81.4W): Atlanta, GA, Charlotte, NC
  Cluster  4 (3722 cities, centroid: 41.2N -88.9W): Chicago, IL, Indianapolis, IN, Milwaukee, WI
  Cluster  5 (1603 cities, centroid: 36.2N -107.3W): Denver, CO, Phoenix, AZ
  Cluster  6 (4554 cities, centroid: 40.6N -75.3W): New York, NY, Philadelphia, PA
  Cluster  7 (2009 cities, centroid: 31.0N -97.0W): Dallas, TX, Houston, TX
  Cluster  8 (1270 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster  9 (2461 cities, centroid: 33.5N -89.0W): Nashville, TN
  Cluster 10 (3362 cities, centroid: 40.5N -82.8W): Detroit, MI
  Cluster 11 (2541 cities, centroid: 44.7N -95.6W): (no facilities)
  Cluster 12 (1121 cities, centroid: 44.0N -110.5W): Salt Lake City, UT

=== k=14 cluster membership (facility cities only) ===
  Cluster  0 (3089 cities, centroid: 39.5N -78.2W): (no facilities)
  Cluster  1 (1723 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  2 (2684 cities, centroid: 37.9N -96.2W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  3 ( 967 cities, centroid: 28.1N -81.8W): Miami, FL
  Cluster  4 (1111 cities, centroid: 44.0N -110.5W): Salt Lake City, UT
  Cluster  5 (1973 cities, centroid: 30.9N -97.1W): Dallas, TX, Houston, TX
  Cluster  6 (1269 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster  7 (2940 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN
  Cluster  8 (2391 cities, centroid: 33.5N -89.2W): Nashville, TN
  Cluster  9 (2713 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA
  Cluster 10 (1600 cities, centroid: 36.2N -107.3W): Denver, CO, Phoenix, AZ
  Cluster 11 (2448 cities, centroid: 44.7N -95.8W): (no facilities)
  Cluster 12 (3320 cities, centroid: 41.3N -89.5W): Chicago, IL, Milwaukee, WI
  Cluster 13 (2235 cities, centroid: 34.8N -82.0W): Atlanta, GA, Charlotte, NC

=== k=15 cluster membership (facility cities only) ===
  Cluster  0 (1193 cities, centroid: 46.0N -121.6W): Portland, OR
  Cluster  1 (2941 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN
  Cluster  2 (1093 cities, centroid: 39.4N -104.1W): Denver, CO
  Cluster  3 (3068 cities, centroid: 39.6N -78.2W): (no facilities)
  Cluster  4 (2451 cities, centroid: 44.7N -95.7W): Omaha, NE
  Cluster  5 ( 998 cities, centroid: 34.5N -109.9W): Phoenix, AZ
  Cluster  6 ( 970 cities, centroid: 28.1N -81.8W): Miami, FL
  Cluster  7 (2381 cities, centroid: 33.5N -89.1W): Nashville, TN
  Cluster  8 (1990 cities, centroid: 30.9N -97.1W): Dallas, TX, Houston, TX
  Cluster  9 (1629 cities, centroid: 36.5N -119.8W): Las Vegas, NV, Los Angeles, CA
  Cluster 10 (1023 cities, centroid: 44.1N -111.7W): Salt Lake City, UT
  Cluster 11 (3271 cities, centroid: 41.4N -89.5W): Chicago, IL, Milwaukee, WI
  Cluster 12 (2229 cities, centroid: 34.9N -81.9W): Atlanta, GA, Charlotte, NC
  Cluster 13 (2533 cities, centroid: 37.7N -95.7W): Kansas City, MO, Oklahoma City, OK
  Cluster 14 (2693 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA

Selected k=15, random_state=738724801 (verified reproducible via stored centers)

=== Region naming ===
  Cluster 0 → Southwest1 (centroid: 46.0N -121.6W, facility cities: Portland, OR)
  Cluster 1 → Florida (centroid: 40.6N -84.3W, facility cities: Detroit, MI, Indianapolis, IN)
  Cluster 2 → Northwest (centroid: 40.6N -103.7W, facility cities: Denver, CO)
  Cluster 3 → MidAtlantic (centroid: 39.6N -78.2W, facility cities: none)
  Cluster 4 → Midwest2 (centroid: 44.6N -95.4W, facility cities: Omaha, NE)
  Cluster 5 → West (centroid: 34.7N -109.4W, facility cities: Phoenix, AZ)
  Cluster 6 → Midwest1 (centroid: 28.1N -81.8W, facility cities: Miami, FL)
  Cluster 7 → Midwest3 (centroid: 33.5N -89.1W, facility cities: Nashville, TN)
  Cluster 8 → Northwest3 (centroid: 31.0N -97.2W, facility cities: Dallas, TX, Houston, TX)
  Cluster 9 → Southwest2 (centroid: 36.5N -119.8W, facility cities: Las Vegas, NV, Los Angeles, CA)
  Cluster 10 → Southeast (centroid: 44.0N -112.0W, facility cities: Salt Lake City, UT)
  Cluster 11 → South (centroid: 41.3N -89.4W, facility cities: Chicago, IL, Milwaukee, WI)
  Cluster 12 → Midwest4 (centroid: 34.9N -81.9W, facility cities: Atlanta, GA, Charlotte, NC)
  Cluster 13 → Northeast (centroid: 37.6N -95.6W, facility cities: Kansas City, MO, Oklahoma City, OK)
  Cluster 14 → Northwest2 (centroid: 41.2N -74.1W, facility cities: New York, NY, Philadelphia, PA)

Config written to config/clustering.json:
{
    "k": 15,
    "random_state": 738724801,
    "cluster_centers": [
        [
            46.02803802449088,
            -121.56461475515843
        ],
        [
            40.62110035514839,
            -84.30101289710814
        ],
        [
            39.3645816155826,
            -104.09109806782526
        ],
        [
            39.5775593601306,
            -78.18909644844089
        ],
        [
            44.67122426107233,
            -95.66763573704355
        ],
        [
            34.47724859409133,
            -109.94092972406656
        ],
        [
            28.112392015560893,
            -81.77300853933872
        ],
        [
            33.49020905998805,
            -89.06061229523671
        ],
        [
            30.937950128977242,
            -97.130255228949
        ],
        [
            36.530559286894764,
            -119.80363821603589
        ],
        [
            44.09338187108012,
            -111.69247271915418
        ],
        [
            41.37127534030937,
            -89.48261843318616
        ],
        [
            34.88214781324083,
            -81.86407952742621
        ],
        [
            37.713203107165,
            -95.65973073663613
        ],
        [
            41.23921541275294,
            -74.12738591943769
        ]
    ],
    "region_names": {
        "0": "Southwest1",
        "1": "Florida",
        "2": "Northwest",
        "3": "MidAtlantic",
        "4": "Midwest2",
        "5": "West",
        "6": "Midwest1",
        "7": "Midwest3",
        "8": "Northwest3",
        "9": "Southwest2",
        "10": "Southeast",
        "11": "South",
        "12": "Midwest4",
        "13": "Northeast",
        "14": "Northwest2"
    }
}

---

## Cluster Explore Run: 2026-04-07 04:00

Loading cities from data/reference/uscities.csv...
  31257 cities loaded

After cleaning: 30463 continental US cities

Cities with facilities: 21

=== Weight distribution — facility cities ===
          city state  population  ranking  facility_count    weight
       Atlanta    GA     5298788        1               4 80.803796
       Detroit    MI     3773725        1               4 79.032429
     Nashville    TN     1201962        1               5 78.166287
  Indianapolis    IN     1767321        1               4 75.073403
         Miami    FL     6391670        1               3 74.788882
       Houston    TX     6227666        1               3 74.664823
     Las Vegas    NV     2299189        1               3 69.909201
   Los Angeles    CA    11984083        1               2 68.410941
     Charlotte    NC     1488249        1               3 67.833336
        Dallas    TX     5968322        1               2 65.484999
  Philadelphia    PA     5782653        1               2 65.352354
       Phoenix    AZ     4121103        1               2 63.930579
      Portland    OR     2115140        1               2 61.131032
     Milwaukee    WI     1291752        1               2 59.061291
Salt Lake City    UT     1183003        1               2 58.692173
      New York    NY    19268388        1               1 56.801622
       Chicago    IL     8609571        1               1 54.073653
        Denver    CO     2714768        1               1 50.165301
   Kansas City    MO     1714910        1               1 48.609821
 Oklahoma City    OK     1017828        1               1 46.843228
         Omaha    NE      836740        2               2 42.929013

=== k-means inertia by k (lower = tighter clusters) ===
  k=12: inertia=2764087
  k=13: inertia=2513906
  k=14: inertia=2284791
  k=15: inertia=2107748

=== k=12 cluster membership (facility cities only) ===
  Cluster  0 (1729 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  1 (4801 cities, centroid: 41.1N -87.3W): Chicago, IL, Detroit, MI, Indianapolis, IN, Milwaukee, WI
  Cluster  2 (2877 cities, centroid: 37.9N -95.8W): Kansas City, MO, Oklahoma City, OK
  Cluster  3 (1146 cities, centroid: 44.0N -110.3W): Salt Lake City, UT
  Cluster  4 (3919 cities, centroid: 38.1N -80.6W): Charlotte, NC
  Cluster  5 (1327 cities, centroid: 29.2N -81.8W): Miami, FL
  Cluster  6 (1633 cities, centroid: 36.1N -107.2W): Denver, CO, Phoenix, AZ
  Cluster  7 (1273 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster  8 (2884 cities, centroid: 44.4N -95.1W): Omaha, NE
  Cluster  9 (2625 cities, centroid: 33.8N -88.0W): Atlanta, GA, Nashville, TN
  Cluster 10 (2134 cities, centroid: 31.0N -96.6W): Dallas, TX, Houston, TX
  Cluster 11 (4115 cities, centroid: 40.8N -75.1W): New York, NY, Philadelphia, PA

=== k=13 cluster membership (facility cities only) ===
  Cluster  0 (2958 cities, centroid: 40.6N -84.4W): Detroit, MI, Indianapolis, IN
  Cluster  1 (1724 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  2 (2085 cities, centroid: 30.9N -96.6W): Dallas, TX, Houston, TX
  Cluster  3 (2522 cities, centroid: 44.6N -96.1W): Omaha, NE
  Cluster  4 (3638 cities, centroid: 37.9N -79.5W): Charlotte, NC
  Cluster  5 (1331 cities, centroid: 29.2N -81.8W): Miami, FL
  Cluster  6 (1644 cities, centroid: 36.2N -107.1W): Denver, CO, Phoenix, AZ
  Cluster  7 (2672 cities, centroid: 33.8N -87.9W): Atlanta, GA, Nashville, TN
  Cluster  8 (3527 cities, centroid: 41.0N -74.7W): New York, NY, Philadelphia, PA
  Cluster  9 (1099 cities, centroid: 43.9N -111.2W): Salt Lake City, UT
  Cluster 10 (3314 cities, centroid: 41.5N -89.6W): Chicago, IL, Milwaukee, WI
  Cluster 11 (2711 cities, centroid: 37.6N -95.9W): Kansas City, MO, Oklahoma City, OK
  Cluster 12 (1238 cities, centroid: 46.0N -121.5W): Portland, OR

=== k=14 cluster membership (facility cities only) ===
  Cluster  0 (2424 cities, centroid: 44.7N -96.0W): (no facilities)
  Cluster  1 (2209 cities, centroid: 34.8N -81.8W): Atlanta, GA, Charlotte, NC
  Cluster  2 (1719 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  3 (2675 cities, centroid: 37.9N -96.1W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  4 (3064 cities, centroid: 39.6N -78.4W): (no facilities)
  Cluster  5 (3299 cities, centroid: 41.5N -89.6W): Chicago, IL, Milwaukee, WI
  Cluster  6 ( 967 cities, centroid: 28.1N -81.8W): Miami, FL
  Cluster  7 (1598 cities, centroid: 36.2N -107.2W): Denver, CO, Phoenix, AZ
  Cluster  8 (2980 cities, centroid: 40.6N -84.5W): Detroit, MI, Indianapolis, IN
  Cluster  9 (1110 cities, centroid: 43.9N -110.8W): Salt Lake City, UT
  Cluster 10 (2414 cities, centroid: 33.5N -89.1W): Nashville, TN
  Cluster 11 (1979 cities, centroid: 30.9N -97.0W): Dallas, TX, Houston, TX
  Cluster 12 (1259 cities, centroid: 46.0N -121.4W): Portland, OR
  Cluster 13 (2766 cities, centroid: 41.2N -74.2W): New York, NY, Philadelphia, PA

=== k=15 cluster membership (facility cities only) ===
  Cluster  0 (1236 cities, centroid: 38.1N -121.2W): (no facilities)
  Cluster  1 (2394 cities, centroid: 33.5N -88.9W): Nashville, TN
  Cluster  2 (1466 cities, centroid: 37.3N -105.3W): Denver, CO
  Cluster  3 (2673 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA
  Cluster  4 (2493 cities, centroid: 44.6N -95.9W): Omaha, NE
  Cluster  5 (1947 cities, centroid: 30.9N -96.9W): Dallas, TX, Houston, TX
  Cluster  6 ( 985 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster  7 (1069 cities, centroid: 43.9N -111.4W): Salt Lake City, UT
  Cluster  8 (2956 cities, centroid: 40.6N -84.4W): Detroit, MI, Indianapolis, IN
  Cluster  9 (1135 cities, centroid: 46.3N -121.4W): Portland, OR
  Cluster 10 (2589 cities, centroid: 37.7N -95.8W): Kansas City, MO, Oklahoma City, OK
  Cluster 11 ( 958 cities, centroid: 34.1N -115.2W): Las Vegas, NV, Los Angeles, CA, Phoenix, AZ
  Cluster 12 (3049 cities, centroid: 39.7N -78.2W): (no facilities)
  Cluster 13 (3269 cities, centroid: 41.4N -89.5W): Chicago, IL, Milwaukee, WI
  Cluster 14 (2244 cities, centroid: 35.0N -81.7W): Atlanta, GA, Charlotte, NC

Selected k=15

=== Region naming ===
  RGN00000 → Southeast (centroid: 38.1N -121.2W, facility cities: none)
  RGN00001 → Colorado (centroid: 33.5N -88.9W, facility cities: Nashville, TN)
  RGN00002 → Northwest (centroid: 37.3N -105.3W, facility cities: Denver, CO)
  RGN00003 → SouthCentral (centroid: 41.2N -74.1W, facility cities: New York, NY, Philadelphia, PA)
  RGN00004 → Southwest (centroid: 44.6N -95.9W, facility cities: Omaha, NE)
  RGN00005 → MidAtlantic (centroid: 30.9N -96.9W, facility cities: Dallas, TX, Houston, TX)
  RGN00006 → Arizona (centroid: 28.2N -81.8W, facility cities: Miami, FL)
  RGN00007 → South (centroid: 43.9N -111.4W, facility cities: Salt Lake City, UT)
  RGN00008 → Midwest1 (centroid: 40.6N -84.4W, facility cities: Detroit, MI, Indianapolis, IN)
  RGN00009 → West (centroid: 46.3N -121.4W, facility cities: Portland, OR)
  RGN00010 → Northeast (centroid: 37.7N -95.8W, facility cities: Kansas City, MO, Oklahoma City, OK)
  RGN00011 → Utah (centroid: 34.1N -115.2W, facility cities: Las Vegas, NV, Los Angeles, CA, Phoenix, AZ)
  RGN00012 → Midwest2 (centroid: 39.7N -78.2W, facility cities: none)
  RGN00013 → Florida (centroid: 41.4N -89.5W, facility cities: Chicago, IL, Milwaukee, WI)
  RGN00014 → Midwest3 (centroid: 35.0N -81.7W, facility cities: Atlanta, GA, Charlotte, NC)

Regions written to data/reference/regions.csv:
region_id  region_name  centroid_latitude  centroid_longitude
 RGN00000    Southeast            38.0611           -121.1545
 RGN00001     Colorado            33.5312            -88.9340
 RGN00002    Northwest            37.3368           -105.2527
 RGN00003 SouthCentral            41.2347            -74.1144
 RGN00004    Southwest            44.6322            -95.8802
 RGN00005  MidAtlantic            30.8565            -96.9071
 RGN00006      Arizona            28.1560            -81.7929
 RGN00007        South            43.9105           -111.3664
 RGN00008     Midwest1            40.6122            -84.3561
 RGN00009         West            46.3141           -121.3996
 RGN00010    Northeast            37.6901            -95.7649
 RGN00011         Utah            34.1092           -115.2401
 RGN00012     Midwest2            39.6765            -78.1991
 RGN00013      Florida            41.4297            -89.5449
 RGN00014     Midwest3            34.9595            -81.6853

---

## Build: 2026-04-07 04:22 (1.9s)

Removed existing data/logistics.duckdb
Created fresh data/logistics.duckdb

Step 1: Loading raw CSVs...
  ✓ customers                               200 rows  (0.02s)
  ✓ delivery_events                      170820 rows  (0.34s)
  ✓ driver_monthly_metrics                 4464 rows  (0.03s)
  ✓ drivers                                 150 rows  (0.01s)
  ✓ facilities                               50 rows  (0.01s)
  ✓ fuel_purchases                       196442 rows  (0.41s)
  ✓ loads                                 85410 rows  (0.18s)
  ✓ maintenance_records                    2920 rows  (0.03s)
  ✓ routes                                   58 rows  (0.01s)
  ✓ safety_incidents                        170 rows  (0.02s)
  ✓ trailers                                180 rows  (0.01s)
  ✓ trips                                 85410 rows  (0.31s)
  ✓ truck_utilization_metrics              3312 rows  (0.03s)
  ✓ trucks                                  120 rows  (0.01s)

  14 tables, 549,706 total rows loaded in 1.41s
Step 1 complete (1.41s)

Step 2: Building reference tables...
  Loaded 15 regions from data/reference/regions.csv
  31257 cities loaded from data/reference/uscities.csv
  30463 continental US cities after cleaning  (0.10s)
  Region assignment complete  (0.02s)
  ✓ cities            30463 rows  (0.13s)
  ✓ city_zips_map     47365 rows  (0.04s)
  ✓ regions              15 rows  (0.05s)
  ✓ lanes               225 rows  (0.01s)  [15×15]
  ✓ facilities.region_id  50/50 assigned  (0.01s)
  ✓ routes.lane_id        58/58 assigned  (0.01s)

  Reference build complete  (0.37s total)
Step 2 complete (0.37s)

Build complete.

---

## Cluster Explore Run: 2026-04-07 04:33

Loading cities from data/reference/uscities.csv...
  31257 cities loaded

After cleaning: 30463 continental US cities

Cities with facilities: 21

=== Weight distribution — facility cities ===
          city state  population  ranking  facility_count    weight
       Atlanta    GA     5298788        1               4 80.803796
       Detroit    MI     3773725        1               4 79.032429
     Nashville    TN     1201962        1               5 78.166287
  Indianapolis    IN     1767321        1               4 75.073403
         Miami    FL     6391670        1               3 74.788882
       Houston    TX     6227666        1               3 74.664823
     Las Vegas    NV     2299189        1               3 69.909201
   Los Angeles    CA    11984083        1               2 68.410941
     Charlotte    NC     1488249        1               3 67.833336
        Dallas    TX     5968322        1               2 65.484999
  Philadelphia    PA     5782653        1               2 65.352354
       Phoenix    AZ     4121103        1               2 63.930579
      Portland    OR     2115140        1               2 61.131032
     Milwaukee    WI     1291752        1               2 59.061291
Salt Lake City    UT     1183003        1               2 58.692173
      New York    NY    19268388        1               1 56.801622
       Chicago    IL     8609571        1               1 54.073653
        Denver    CO     2714768        1               1 50.165301
   Kansas City    MO     1714910        1               1 48.609821
 Oklahoma City    OK     1017828        1               1 46.843228
         Omaha    NE      836740        2               2 42.929013

=== k-means inertia by k (lower = tighter clusters) ===
  k=12: inertia=2764524
  k=13: inertia=2488380
  k=14: inertia=2284847
  k=15: inertia=2101924

=== k=12 cluster membership (facility cities only) ===
  Cluster  0 (4825 cities, centroid: 41.1N -87.3W): Chicago, IL, Detroit, MI, Indianapolis, IN, Milwaukee, WI
  Cluster  1 (1139 cities, centroid: 43.9N -110.5W): Salt Lake City, UT
  Cluster  2 (3923 cities, centroid: 38.1N -80.6W): Charlotte, NC
  Cluster  3 (2123 cities, centroid: 31.0N -96.6W): Dallas, TX, Houston, TX
  Cluster  4 (4110 cities, centroid: 40.8N -75.1W): New York, NY, Philadelphia, PA
  Cluster  5 (2940 cities, centroid: 44.3N -95.2W): Omaha, NE
  Cluster  6 (1649 cities, centroid: 36.2N -107.0W): Denver, CO, Phoenix, AZ
  Cluster  7 (1730 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  8 (2584 cities, centroid: 33.7N -87.8W): Atlanta, GA, Nashville, TN
  Cluster  9 (1271 cities, centroid: 45.9N -121.3W): Portland, OR
  Cluster 10 (2876 cities, centroid: 37.7N -95.5W): Kansas City, MO, Oklahoma City, OK
  Cluster 11 (1293 cities, centroid: 29.1N -81.8W): Miami, FL

=== k=13 cluster membership (facility cities only) ===
  Cluster  0 (2502 cities, centroid: 33.6N -88.1W): Atlanta, GA, Nashville, TN
  Cluster  1 (1239 cities, centroid: 46.0N -121.5W): Portland, OR
  Cluster  2 (2265 cities, centroid: 35.4N -80.8W): Charlotte, NC
  Cluster  3 (2696 cities, centroid: 44.4N -96.0W): Omaha, NE
  Cluster  4 (1650 cities, centroid: 36.2N -107.0W): Denver, CO, Phoenix, AZ
  Cluster  5 (4491 cities, centroid: 40.7N -75.3W): New York, NY, Philadelphia, PA
  Cluster  6 (2015 cities, centroid: 30.8N -96.7W): Dallas, TX, Houston, TX
  Cluster  7 (3689 cities, centroid: 41.3N -89.2W): Chicago, IL, Milwaukee, WI
  Cluster  8 ( 996 cities, centroid: 28.2N -81.7W): Miami, FL
  Cluster  9 (1105 cities, centroid: 43.9N -111.1W): Salt Lake City, UT
  Cluster 10 (3387 cities, centroid: 40.6N -83.0W): Detroit, MI, Indianapolis, IN
  Cluster 11 (1725 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster 12 (2703 cities, centroid: 37.4N -95.7W): Kansas City, MO, Oklahoma City, OK

=== k=14 cluster membership (facility cities only) ===
  Cluster  0 (2429 cities, centroid: 33.5N -89.0W): Nashville, TN
  Cluster  1 (1723 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA
  Cluster  2 (3069 cities, centroid: 39.7N -78.1W): (no facilities)
  Cluster  3 (1105 cities, centroid: 43.9N -111.0W): Salt Lake City, UT
  Cluster  4 (2452 cities, centroid: 44.7N -96.0W): (no facilities)
  Cluster  5 (2670 cities, centroid: 37.9N -96.1W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  6 (1980 cities, centroid: 30.9N -97.0W): Dallas, TX, Houston, TX
  Cluster  7 (3327 cities, centroid: 41.4N -89.6W): Chicago, IL, Milwaukee, WI
  Cluster  8 (2253 cities, centroid: 35.0N -81.7W): Atlanta, GA, Charlotte, NC
  Cluster  9 ( 986 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster 10 (1247 cities, centroid: 46.0N -121.4W): Portland, OR
  Cluster 11 (2970 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN
  Cluster 12 (2629 cities, centroid: 41.3N -74.1W): New York, NY, Philadelphia, PA
  Cluster 13 (1623 cities, centroid: 36.2N -107.1W): Denver, CO, Phoenix, AZ

=== k=15 cluster membership (facility cities only) ===
  Cluster  0 ( 999 cities, centroid: 43.9N -112.1W): Salt Lake City, UT
  Cluster  1 (2248 cities, centroid: 34.9N -81.7W): Atlanta, GA, Charlotte, NC
  Cluster  2 (2525 cities, centroid: 37.7N -95.7W): Kansas City, MO, Oklahoma City, OK
  Cluster  3 (2908 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN
  Cluster  4 (2037 cities, centroid: 31.0N -97.2W): Dallas, TX, Houston, TX
  Cluster  5 ( 985 cities, centroid: 28.2N -81.8W): Miami, FL
  Cluster  6 (1175 cities, centroid: 46.0N -121.6W): Portland, OR
  Cluster  7 (2658 cities, centroid: 41.2N -74.1W): New York, NY, Philadelphia, PA
  Cluster  8 (3225 cities, centroid: 41.3N -89.4W): Chicago, IL, Milwaukee, WI
  Cluster  9 (1633 cities, centroid: 36.5N -119.8W): Las Vegas, NV, Los Angeles, CA
  Cluster 10 (1071 cities, centroid: 41.2N -103.6W): Denver, CO
  Cluster 11 (2390 cities, centroid: 33.5N -89.0W): Nashville, TN
  Cluster 12 (1161 cities, centroid: 34.7N -109.3W): Phoenix, AZ
  Cluster 13 (2398 cities, centroid: 44.6N -95.2W): Omaha, NE
  Cluster 14 (3050 cities, centroid: 39.7N -78.2W): (no facilities)

Selected k=15

=== Region naming ===
  RGN00000 → Appalachian (centroid: 43.9N -112.1W, facility cities: Salt Lake City, UT)
  RGN00001 → Plains (centroid: 34.9N -81.7W, facility cities: Atlanta, GA, Charlotte, NC)
  RGN00002 → Southwest (centroid: 37.7N -95.7W, facility cities: Kansas City, MO, Oklahoma City, OK)
  RGN00003 → GreatLakes (centroid: 40.6N -84.3W, facility cities: Detroit, MI, Indianapolis, IN)
  RGN00004 → Texas (centroid: 31.0N -97.2W, facility cities: Dallas, TX, Houston, TX)
  RGN00005 → Tennessee (centroid: 28.2N -81.8W, facility cities: Miami, FL)
  RGN00006 → Colorado (centroid: 46.0N -121.6W, facility cities: Portland, OR)
  RGN00007 → Midwest (centroid: 41.2N -74.1W, facility cities: New York, NY, Philadelphia, PA)
  RGN00008 → Northwest (centroid: 41.3N -89.4W, facility cities: Chicago, IL, Milwaukee, WI)
  RGN00009 → Florida (centroid: 36.5N -119.8W, facility cities: Las Vegas, NV, Los Angeles, CA)
  RGN00010 → Arizona (centroid: 41.2N -103.6W, facility cities: Denver, CO)
  RGN00011 → Northeast (centroid: 33.5N -89.0W, facility cities: Nashville, TN)
  RGN00012 → Utah (centroid: 34.7N -109.3W, facility cities: Phoenix, AZ)
  RGN00013 → Southeast (centroid: 44.6N -95.2W, facility cities: Omaha, NE)
  RGN00014 → UpperPlains (centroid: 39.7N -78.2W, facility cities: none)

Regions written to data/reference/regions.csv:
region_id region_name  centroid_latitude  centroid_longitude
 RGN00000 Appalachian            43.9495           -112.0876
 RGN00001      Plains            34.9479            -81.7291
 RGN00002   Southwest            37.7474            -95.6578
 RGN00003  GreatLakes            40.6310            -84.2705
 RGN00004       Texas            31.0468            -97.2205
 RGN00005   Tennessee            28.1583            -81.7950
 RGN00006    Colorado            46.0452           -121.6387
 RGN00007     Midwest            41.2411            -74.0964
 RGN00008   Northwest            41.2873            -89.3813
 RGN00009     Florida            36.5243           -119.7898
 RGN00010     Arizona            41.1793           -103.5874
 RGN00011   Northeast            33.4729            -89.0334
 RGN00012        Utah            34.7485           -109.2801
 RGN00013   Southeast            44.5832            -95.2135
 RGN00014 UpperPlains            39.6698            -78.1594

---

## Cluster Explore Run: 2026-04-07 04:39

Loading cities from data/reference/uscities.csv...
  31257 cities loaded

After cleaning: 30463 continental US cities

Cities with facilities: 21

=== Weight distribution — facility cities ===
          city state  population  ranking  facility_count    weight
       Atlanta    GA     5298788        1               4 80.803796
       Detroit    MI     3773725        1               4 79.032429
     Nashville    TN     1201962        1               5 78.166287
  Indianapolis    IN     1767321        1               4 75.073403
         Miami    FL     6391670        1               3 74.788882
       Houston    TX     6227666        1               3 74.664823
     Las Vegas    NV     2299189        1               3 69.909201
   Los Angeles    CA    11984083        1               2 68.410941
     Charlotte    NC     1488249        1               3 67.833336
        Dallas    TX     5968322        1               2 65.484999
  Philadelphia    PA     5782653        1               2 65.352354
       Phoenix    AZ     4121103        1               2 63.930579
      Portland    OR     2115140        1               2 61.131032
     Milwaukee    WI     1291752        1               2 59.061291
Salt Lake City    UT     1183003        1               2 58.692173
      New York    NY    19268388        1               1 56.801622
       Chicago    IL     8609571        1               1 54.073653
        Denver    CO     2714768        1               1 50.165301
   Kansas City    MO     1714910        1               1 48.609821
 Oklahoma City    OK     1017828        1               1 46.843228
         Omaha    NE      836740        2               2 42.929013

=== k-means inertia by k (lower = tighter clusters) ===
  k=12: inertia=2764157
  k=13: inertia=2484003
  k=14: inertia=2298267
  k=15: inertia=2101857

=== k=12 cluster membership (top cities by weight) ===
  Cluster  0 (2624 cities, centroid: 33.8N -88.1W): Atlanta, GA, Nashville, TN, Memphis, TN
  Cluster  1 (2876 cities, centroid: 37.9N -95.8W): Kansas City, MO, Oklahoma City, OK, Tulsa, OK
  Cluster  2 (1729 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA, San Francisco, CA
  Cluster  3 (3927 cities, centroid: 38.1N -80.6W): Charlotte, NC, Pittsburgh, PA, Cleveland, OH
  Cluster  4 (4117 cities, centroid: 40.8N -75.1W): Philadelphia, PA, New York, NY, Washington, DC
  Cluster  5 (1145 cities, centroid: 43.9N -110.4W): Salt Lake City, UT, Provo, UT, Ogden, UT
  Cluster  6 (4797 cities, centroid: 41.1N -87.3W): Detroit, MI, Indianapolis, IN, Milwaukee, WI
  Cluster  7 (1631 cities, centroid: 36.2N -107.1W): Phoenix, AZ, Denver, CO, Tucson, AZ
  Cluster  8 (2130 cities, centroid: 31.0N -96.7W): Houston, TX, Dallas, TX, San Antonio, TX
  Cluster  9 (1341 cities, centroid: 29.2N -81.9W): Miami, FL, Tampa, FL, Orlando, FL
  Cluster 10 (2874 cities, centroid: 44.4N -95.1W): Omaha, NE, Minneapolis, MN, Des Moines, IA
  Cluster 11 (1272 cities, centroid: 45.9N -121.3W): Portland, OR, Seattle, WA, Spokane, WA

=== k=13 cluster membership (top cities by weight) ===
  Cluster  0 (2024 cities, centroid: 31.0N -97.0W): Houston, TX, Dallas, TX, San Antonio, TX
  Cluster  1 (4553 cities, centroid: 40.6N -75.3W): Philadelphia, PA, New York, NY, Washington, DC
  Cluster  2 (1259 cities, centroid: 46.0N -121.4W): Portland, OR, Seattle, WA, Spokane, WA
  Cluster  3 (3691 cities, centroid: 41.3N -89.0W): Indianapolis, IN, Milwaukee, WI, Chicago, IL
  Cluster  4 (2363 cities, centroid: 35.1N -81.3W): Atlanta, GA, Charlotte, NC, Raleigh, NC
  Cluster  5 (2721 cities, centroid: 38.0N -96.0W): Kansas City, MO, Oklahoma City, OK, Omaha, NE
  Cluster  6 (1723 cities, centroid: 36.4N -119.5W): Las Vegas, NV, Los Angeles, CA, San Francisco, CA
  Cluster  7 (3390 cities, centroid: 40.5N -82.9W): Detroit, MI, Pittsburgh, PA, Cincinnati, OH
  Cluster  8 (1610 cities, centroid: 36.2N -107.2W): Phoenix, AZ, Denver, CO, Tucson, AZ
  Cluster  9 (2515 cities, centroid: 44.7N -95.7W): Minneapolis, MN, Des Moines, IA, St. Paul, MN
  Cluster 10 (1132 cities, centroid: 43.9N -110.7W): Salt Lake City, UT, Provo, UT, Ogden, UT
  Cluster 11 (2482 cities, centroid: 33.6N -88.9W): Nashville, TN, Memphis, TN, New Orleans, LA
  Cluster 12 (1000 cities, centroid: 28.2N -81.8W): Miami, FL, Tampa, FL, Orlando, FL

=== k=14 cluster membership (top cities by weight) ===
  Cluster  0 (3636 cities, centroid: 41.2N -88.9W): Indianapolis, IN, Milwaukee, WI, Chicago, IL
  Cluster  1 (1155 cities, centroid: 34.7N -109.3W): Phoenix, AZ, Tucson, AZ, El Paso, TX
  Cluster  2 (4548 cities, centroid: 40.6N -75.3W): Philadelphia, PA, New York, NY, Washington, DC
  Cluster  3 (2020 cities, centroid: 31.0N -97.2W): Houston, TX, Dallas, TX, San Antonio, TX
  Cluster  4 (2355 cities, centroid: 35.1N -81.3W): Atlanta, GA, Charlotte, NC, Raleigh, NC
  Cluster  5 (1176 cities, centroid: 46.0N -121.6W): Portland, OR, Seattle, WA, Spokane, WA
  Cluster  6 (1094 cities, centroid: 40.9N -103.5W): Denver, CO, Colorado Springs, CO, Aurora, CO
  Cluster  7 (2517 cities, centroid: 44.5N -95.2W): Omaha, NE, Minneapolis, MN, Des Moines, IA
  Cluster  8 (3347 cities, centroid: 40.5N -82.9W): Detroit, MI, Pittsburgh, PA, Cincinnati, OH
  Cluster  9 (2430 cities, centroid: 33.5N -88.8W): Nashville, TN, Memphis, TN, New Orleans, LA
  Cluster 10 (1633 cities, centroid: 36.5N -119.8W): Las Vegas, NV, Los Angeles, CA, San Francisco, CA
  Cluster 11 (1000 cities, centroid: 28.2N -81.8W): Miami, FL, Tampa, FL, Orlando, FL
  Cluster 12 (1005 cities, centroid: 44.0N -112.0W): Salt Lake City, UT, Provo, UT, Ogden, UT
  Cluster 13 (2547 cities, centroid: 37.6N -95.5W): Kansas City, MO, Oklahoma City, OK, Tulsa, OK

=== k=15 cluster membership (top cities by weight) ===
  Cluster  0 (1176 cities, centroid: 46.0N -121.6W): Portland, OR, Seattle, WA, Spokane, WA
  Cluster  1 (2228 cities, centroid: 34.9N -81.9W): Atlanta, GA, Charlotte, NC, Raleigh, NC
  Cluster  2 (1980 cities, centroid: 30.9N -97.2W): Houston, TX, Dallas, TX, San Antonio, TX
  Cluster  3 (3229 cities, centroid: 41.3N -89.4W): Milwaukee, WI, Chicago, IL, St. Louis, MO
  Cluster  4 (1633 cities, centroid: 36.5N -119.8W): Las Vegas, NV, Los Angeles, CA, San Francisco, CA
  Cluster  5 (2505 cities, centroid: 37.5N -95.6W): Kansas City, MO, Oklahoma City, OK, Tulsa, OK
  Cluster  6 (2698 cities, centroid: 41.2N -74.1W): Philadelphia, PA, New York, NY, Boston, MA
  Cluster  7 (1087 cities, centroid: 40.9N -103.5W): Denver, CO, Colorado Springs, CO, Aurora, CO
  Cluster  8 (2352 cities, centroid: 33.4N -89.0W): Nashville, TN, Memphis, TN, New Orleans, LA
  Cluster  9 ( 969 cities, centroid: 28.1N -81.8W): Miami, FL, Tampa, FL, Orlando, FL
  Cluster 10 (1005 cities, centroid: 44.0N -112.0W): Salt Lake City, UT, Provo, UT, Ogden, UT
  Cluster 11 (2469 cities, centroid: 44.5N -95.3W): Omaha, NE, Minneapolis, MN, Des Moines, IA
  Cluster 12 (3060 cities, centroid: 39.6N -78.2W): Washington, DC, Baltimore, MD, Pittsburgh, PA
  Cluster 13 (1158 cities, centroid: 34.7N -109.3W): Phoenix, AZ, Tucson, AZ, El Paso, TX
  Cluster 14 (2914 cities, centroid: 40.6N -84.3W): Detroit, MI, Indianapolis, IN, Cincinnati, OH

Selected k=15

=== Clusters written to regions.csv (add region_name manually) ===
  RGN00000: centroid 46.0N -121.6W — Portland, OR, Seattle, WA, Spokane, WA, Eugene, OR, Salem, OR
  RGN00001: centroid 34.9N -81.9W — Atlanta, GA, Charlotte, NC, Raleigh, NC, Charleston, SC, Knoxville, TN
  RGN00002: centroid 30.9N -97.2W — Houston, TX, Dallas, TX, San Antonio, TX, Austin, TX, Fort Worth, TX
  RGN00003: centroid 41.3N -89.4W — Milwaukee, WI, Chicago, IL, St. Louis, MO, Madison, WI, Davenport, IA
  RGN00004: centroid 36.5N -119.8W — Las Vegas, NV, Los Angeles, CA, San Francisco, CA, San Diego, CA, Riverside, CA
  RGN00005: centroid 37.5N -95.6W — Kansas City, MO, Oklahoma City, OK, Tulsa, OK, Wichita, KS, Fayetteville, AR
  RGN00006: centroid 41.2N -74.1W — Philadelphia, PA, New York, NY, Boston, MA, Brooklyn, NY, Queens, NY
  RGN00007: centroid 40.9N -103.5W — Denver, CO, Colorado Springs, CO, Aurora, CO, Fort Collins, CO, Amarillo, TX
  RGN00008: centroid 33.4N -89.0W — Nashville, TN, Memphis, TN, New Orleans, LA, Birmingham, AL, Baton Rouge, LA
  RGN00009: centroid 28.1N -81.8W — Miami, FL, Tampa, FL, Orlando, FL, Jacksonville, FL, Cape Coral, FL
  RGN00010: centroid 44.0N -112.0W — Salt Lake City, UT, Provo, UT, Ogden, UT, Boise, ID, Nampa, ID
  RGN00011: centroid 44.5N -95.3W — Omaha, NE, Minneapolis, MN, Des Moines, IA, St. Paul, MN, Fargo, ND
  RGN00012: centroid 39.6N -78.2W — Washington, DC, Baltimore, MD, Pittsburgh, PA, Virginia Beach, VA, Richmond, VA
  RGN00013: centroid 34.7N -109.3W — Phoenix, AZ, Tucson, AZ, El Paso, TX, Albuquerque, NM, Mesa, AZ
  RGN00014: centroid 40.6N -84.3W — Detroit, MI, Indianapolis, IN, Cincinnati, OH, Cleveland, OH, Columbus, OH

Regions written to data/reference/regions.csv
Edit region_name in that file, then run 'python3 scripts/build.py'.

---

### 2026-04-07 — Region naming finalized

Manually assigned region names to `data/reference/regions.csv` after cluster_explore.py run. Naming convention: standard US geographic region names; singletons have no number, duplicates numbered starting at 1.

| region_id | region_name | Top cities |
|-----------|-------------|------------|
| RGN00000 | Northwest1 | Portland, Seattle, Spokane |
| RGN00001 | Southeast1 | Atlanta, Charlotte, Raleigh |
| RGN00002 | Southwest1 | Houston, Dallas, San Antonio |
| RGN00003 | Midwest1 | Milwaukee, Chicago, St. Louis |
| RGN00004 | West | Las Vegas, Los Angeles, San Francisco |
| RGN00005 | Midwest2 | Kansas City, Oklahoma City, Tulsa |
| RGN00006 | Northeast | Philadelphia, New York, Boston |
| RGN00007 | Mountain | Denver, Colorado Springs, Aurora |
| RGN00008 | South | Nashville, Memphis, New Orleans |
| RGN00009 | Southeast2 | Miami, Tampa, Orlando |
| RGN00010 | Northwest2 | Salt Lake City, Provo, Boise |
| RGN00011 | Midwest3 | Omaha, Minneapolis, Des Moines |
| RGN00012 | MidAtlantic | Washington DC, Baltimore, Pittsburgh |
| RGN00013 | Southwest2 | Phoenix, Tucson, Albuquerque |
| RGN00014 | Midwest4 | Detroit, Indianapolis, Cincinnati |

**Next:** Run `python3 scripts/build.py` to rebuild with the new region names.

---

## Build: 2026-04-07 04:49 (2.0s)

Removed existing data/logistics.duckdb
Created fresh data/logistics.duckdb

Step 1: Loading raw CSVs...
  ✓ customers                               200 rows  (0.03s)
  ✓ delivery_events                      170820 rows  (0.38s)
  ✓ driver_monthly_metrics                 4464 rows  (0.03s)
  ✓ drivers                                 150 rows  (0.01s)
  ✓ facilities                               50 rows  (0.01s)
  ✓ fuel_purchases                       196442 rows  (0.46s)
  ✓ loads                                 85410 rows  (0.18s)
  ✓ maintenance_records                    2920 rows  (0.03s)
  ✓ routes                                   58 rows  (0.01s)
  ✓ safety_incidents                        170 rows  (0.02s)
  ✓ trailers                                180 rows  (0.01s)
  ✓ trips                                 85410 rows  (0.34s)
  ✓ truck_utilization_metrics              3312 rows  (0.03s)
  ✓ trucks                                  120 rows  (0.02s)

  14 tables, 549,706 total rows loaded in 1.55s
Step 1 complete (1.55s)

Step 2: Building reference tables...
  Loaded 15 regions from data/reference/regions.csv
  31257 cities loaded from data/reference/uscities.csv
  30463 continental US cities after cleaning  (0.09s)
  Region assignment complete  (0.02s)
  ✓ cities            30463 rows  (0.10s)
  ✓ city_zips_map     47365 rows  (0.04s)
  ✓ regions              15 rows  (0.05s)
  ✓ lanes               225 rows  (0.02s)  [15×15]
  ✓ facilities.region_id  50/50 assigned  (0.01s)
  ✓ routes.lane_id        58/58 assigned  (0.01s)

  Reference build complete  (0.34s total)
Step 2 complete (0.34s)

Build complete.
