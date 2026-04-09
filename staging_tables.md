# Staging Tables — Decision Log

All staging models live in `logistics_modeling/models/staging/`.  
Conventions: views, light cleaning only, no business logic, dates cast to `DATE`/`TIMESTAMP`.

---

## Status

| # | Source Table | Staging Model | Status |
|---|---|---|---|
| 1 | drivers | stg_drivers | ✅ decided |
| 2 | trucks | stg_trucks | ✅ decided |
| 3 | trailers | stg_trailers | ✅ decided |
| 4 | customers | stg_customers | ✅ decided |
| 5 | facilities | stg_facilities | ✅ decided |
| 6 | routes | stg_routes | ✅ decided |
| 7 | regions | stg_regions | ✅ decided |
| 8 | lanes | stg_lanes | ✅ decided |
| 9 | loads | stg_loads | ✅ decided |
| 10 | trips | stg_trips | ✅ decided |
| 11 | fuel_purchases | stg_fuel_purchases | ✅ decided |
| 12 | delivery_events | stg_delivery_events | ✅ decided |
| 13 | maintenance_records | stg_maintenance_records | ✅ decided |
| 14 | safety_incidents | stg_safety_incidents | ✅ decided |
| 15 | driver_monthly_metrics | stg_driver_monthly_metrics | ✅ decided |
| 16 | truck_utilization_metrics | stg_truck_utilization_metrics | ✅ decided |

---

## Table Decisions

---

### 1. `stg_drivers` ← `drivers`

**Source columns:** driver_id, first_name, last_name, hire_date, termination_date, license_number, license_state, date_of_birth, home_terminal, employment_status, cdl_class, years_experience

**Decisions:**
- Cast `hire_date`, `date_of_birth` → `DATE` (no nulls)
- Cast `termination_date` → `DATE` via `NULLIF(termination_date, '')` — empty for 124 active drivers
- Derive `driver_full_name` = `first_name || ' ' || last_name`
- Replace `employment_status` (only ever `'Active'` / `'Terminated'`) with boolean `is_terminated`
- Keep all remaining columns as-is

**Tests:** `driver_id` unique + not_null; `is_terminated` not_null

---

### 2. `stg_trucks` ← `trucks`

**Source columns:** truck_id, unit_number, make, model_year, vin, acquisition_date, acquisition_mileage, fuel_type, tank_capacity_gallons, status, home_terminal

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| truck_id | VARCHAR | VARCHAR | PK — not_null, unique |
| unit_number | VARCHAR | VARCHAR | numeric string, keep as VARCHAR |
| make | VARCHAR | VARCHAR | |
| model_year | VARCHAR | INTEGER | cast from string |
| vin | VARCHAR | VARCHAR | |
| acquisition_date | VARCHAR | DATE | cast from string, no nulls |
| acquisition_mileage | VARCHAR | INTEGER | cast from string, no nulls |
| fuel_type | VARCHAR | VARCHAR | keep — may expand beyond `'Diesel'` |
| tank_capacity_gallons | VARCHAR | FLOAT | cast from string, no nulls |
| status | VARCHAR | VARCHAR | 3 values: `Active`, `Maintenance`, `Inactive` |
| home_terminal | VARCHAR | VARCHAR | city name |

**Tests:** `truck_id` unique + not_null; `status` accepted_values

---

### 3. `stg_trailers` ← `trailers`

**Source columns:** trailer_id, trailer_number, trailer_type, length_feet, model_year, vin, acquisition_date, status, current_location

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| trailer_id | VARCHAR | VARCHAR | PK — not_null, unique |
| trailer_number | VARCHAR | VARCHAR | numeric string, keep as VARCHAR |
| trailer_type | VARCHAR | VARCHAR | 2 values: `Dry Van`, `Refrigerated` |
| length_feet | VARCHAR | INTEGER | cast from string, no nulls |
| model_year | VARCHAR | INTEGER | cast from string, no nulls |
| vin | VARCHAR | VARCHAR | |
| acquisition_date | VARCHAR | DATE | cast from string, no nulls |
| status | VARCHAR | VARCHAR | always `'Active'` currently — keep for future states |
| current_location | VARCHAR | VARCHAR | city name |

**Tests:** `trailer_id` unique + not_null; `trailer_type` accepted_values

---

### 4. `stg_customers` ← `customers`

**Source columns:** customer_id, customer_name, customer_type, credit_terms_days, primary_freight_type, account_status, contract_start_date, annual_revenue_potential

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| customer_id | VARCHAR | VARCHAR | PK — not_null, unique |
| customer_name | VARCHAR | VARCHAR | |
| customer_type | VARCHAR | VARCHAR | 3 values: `Dedicated`, `Contract`, `Spot` |
| credit_terms_days | VARCHAR | INTEGER | cast from string, no nulls |
| primary_freight_type | VARCHAR | VARCHAR | 6 values |
| account_status | VARCHAR | BOOLEAN | only `'Active'`/`'Inactive'` — rename `is_active` |
| contract_start_date | VARCHAR | DATE | cast from string, no nulls |
| annual_revenue_potential | VARCHAR | NUMERIC | cast from string, no nulls |

**Tests:** `customer_id` unique + not_null; `customer_type` accepted_values; `is_active` not_null

---

### 5. `stg_facilities` ← `facilities`

**Source columns:** facility_id, facility_name, facility_type, city, state, latitude, longitude, dock_doors, operating_hours, region_id

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| facility_id | VARCHAR | VARCHAR | PK — not_null, unique |
| facility_name | VARCHAR | VARCHAR | |
| facility_type | VARCHAR | VARCHAR | 4 values: `Cross-Dock`, `Distribution Center`, `Terminal`, `Warehouse` |
| city | VARCHAR | — | **drop** — replaced by `city_id` |
| state | VARCHAR | — | **drop** — replaced by `city_id` |
| city_id | — | VARCHAR | FK to `cities`, joined on city+state, 50/50 match |
| latitude | VARCHAR | FLOAT | cast from string, no nulls |
| longitude | VARCHAR | FLOAT | cast from string, no nulls |
| dock_doors | VARCHAR | INTEGER | cast from string, no nulls |
| operating_hours | VARCHAR | — | **drop** — replaced by parsed columns |
| operating_hours_start | — | TIME | parsed via `strptime`; `24/7` → `00:00` |
| operating_hours_end | — | TIME | parsed via `strptime`; `24/7` → `00:00` |
| region_id | VARCHAR | VARCHAR | FK to `regions`, assigned by build script |

**Tests:** `facility_id` unique + not_null; `facility_type` accepted_values; `city_id` not_null; `region_id` not_null

---

### 6. `stg_routes` ← `routes`

**Source columns:** route_id, origin_city, origin_state, destination_city, destination_state, typical_distance_miles, base_rate_per_mile, fuel_surcharge_rate, typical_transit_days, lane_id

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| route_id | VARCHAR | VARCHAR | PK — not_null, unique |
| origin_city | VARCHAR | — | **drop** — replaced by `origin_city_id` |
| origin_state | VARCHAR | — | **drop** — replaced by `origin_city_id` |
| origin_city_id | — | VARCHAR | FK to `cities`, joined on city+state, 58/58 match |
| destination_city | VARCHAR | — | **drop** — replaced by `destination_city_id` |
| destination_state | VARCHAR | — | **drop** — replaced by `destination_city_id` |
| destination_city_id | — | VARCHAR | FK to `cities`, joined on city+state, 58/58 match |
| typical_distance_miles | INTEGER | INTEGER | already typed correctly |
| base_rate_per_mile | FLOAT | FLOAT | already typed correctly |
| fuel_surcharge_rate | FLOAT | FLOAT | already typed correctly |
| typical_transit_days | INTEGER | INTEGER | already typed correctly |
| lane_id | VARCHAR | VARCHAR | FK to `lanes`, assigned by build script |

**Tests:** `route_id` unique + not_null; `origin_city_id` not_null; `destination_city_id` not_null; `lane_id` not_null

---

### 7. `stg_regions` ← `regions`

**Source columns:** region_id, region_name, centroid_latitude, centroid_longitude

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| region_id | VARCHAR | VARCHAR | PK — not_null, unique |
| region_name | VARCHAR | VARCHAR | |
| centroid_latitude | FLOAT | FLOAT | already typed correctly |
| centroid_longitude | FLOAT | FLOAT | already typed correctly |

**Tests:** `region_id` unique + not_null

---

### 8. `stg_lanes` ← `lanes`

**Source columns:** lane_id, origin_region_id, destination_region_id, lane_type

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| lane_id | VARCHAR | VARCHAR | PK — not_null, unique |
| origin_region_id | VARCHAR | VARCHAR | FK to `regions` |
| destination_region_id | VARCHAR | VARCHAR | FK to `regions` |
| lane_type | VARCHAR | VARCHAR | 2 values: `local`, `over_the_road` |

**Tests:** `lane_id` unique + not_null; `lane_type` accepted_values

---

### 9. `stg_loads` ← `loads`

**Source columns:** load_id, customer_id, route_id, load_date, load_type, weight_lbs, pieces, revenue, fuel_surcharge, accessorial_charges, load_status, booking_type

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| load_id | VARCHAR | VARCHAR | PK — not_null, unique |
| customer_id | VARCHAR | VARCHAR | FK to `customers` |
| route_id | VARCHAR | VARCHAR | FK to `routes` |
| load_date | DATE | DATE | already typed correctly |
| load_type | VARCHAR | VARCHAR | 2 values: `Dry Van`, `Refrigerated` |
| weight_lbs | INTEGER | INTEGER | already typed correctly |
| pieces | INTEGER | INTEGER | already typed correctly |
| revenue | FLOAT | FLOAT | already typed correctly |
| fuel_surcharge | FLOAT | FLOAT | already typed correctly |
| accessorial_charges | INTEGER | INTEGER | already typed correctly |
| load_status | VARCHAR | VARCHAR | keep — currently always `'Completed'`, may expand |
| booking_type | VARCHAR | VARCHAR | 3 values: `Contract`, `Dedicated`, `Spot` |

**Tests:** `load_id` unique + not_null; `customer_id` not_null; `route_id` not_null; `load_type` accepted_values; `booking_type` accepted_values

---

### 10. `stg_trips` ← `trips`

**Source columns:** trip_id, load_id, driver_id, truck_id, trailer_id, dispatch_date, actual_distance_miles, actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, trip_status

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| trip_id | VARCHAR | VARCHAR | PK — not_null, unique |
| load_id | VARCHAR | VARCHAR | FK to `loads` |
| driver_id | VARCHAR | VARCHAR | FK to `drivers` |
| truck_id | VARCHAR | VARCHAR | FK to `trucks` |
| trailer_id | VARCHAR | VARCHAR | FK to `trailers` |
| dispatch_date | DATE | DATE | already typed correctly |
| actual_distance_miles | INTEGER | INTEGER | already typed correctly |
| actual_duration_hours | FLOAT | FLOAT | already typed correctly |
| fuel_gallons_used | FLOAT | FLOAT | already typed correctly |
| average_mpg | FLOAT | FLOAT | already typed correctly |
| idle_time_hours | FLOAT | FLOAT | already typed correctly |
| trip_status | VARCHAR | VARCHAR | keep — currently always `'Completed'`, may expand |

**Tests:** `trip_id` unique + not_null; `load_id` not_null; `driver_id` not_null (1,714 nulls ~2% — no cross-fill possible from fuel_purchases); `truck_id` not_null; `trailer_id` not_null

---

### 11. `stg_fuel_purchases` ← `fuel_purchases`

**Source columns:** fuel_purchase_id, trip_id, truck_id, driver_id, purchase_date, location_city, location_state, gallons, price_per_gallon, total_cost, fuel_card_number

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| fuel_purchase_id | VARCHAR | VARCHAR | PK — not_null, unique |
| trip_id | VARCHAR | VARCHAR | FK to `trips` |
| truck_id | VARCHAR | VARCHAR | FK to `trucks` |
| driver_id | VARCHAR | VARCHAR | FK to `drivers` — nullable (3,988 nulls ~2%); no cross-fill possible from trips |
| purchase_date | TIMESTAMP | TIMESTAMP | already typed correctly |
| location_city | VARCHAR | VARCHAR | free-text, only 17% match to `cities` — keep as-is |
| location_state | VARCHAR | VARCHAR | keep alongside `location_city` |
| gallons | FLOAT | FLOAT | already typed correctly |
| price_per_gallon | FLOAT | FLOAT | already typed correctly |
| total_cost | FLOAT | FLOAT | already typed correctly |
| fuel_card_number | VARCHAR | VARCHAR | internal identifier |

**Tests:** `fuel_purchase_id` unique + not_null; `trip_id` not_null; `truck_id` not_null

---

### 12. `stg_delivery_events` ← `delivery_events`

**Source columns:** event_id, load_id, trip_id, event_type, facility_id, scheduled_datetime, actual_datetime, detention_minutes, on_time_flag, location_city, location_state

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| event_id | VARCHAR | VARCHAR | PK — not_null, unique |
| load_id | VARCHAR | VARCHAR | FK to `loads` |
| trip_id | VARCHAR | VARCHAR | FK to `trips` |
| event_type | VARCHAR | VARCHAR | 2 values: `Pickup`, `Delivery` |
| facility_id | VARCHAR | VARCHAR | FK to `facilities` — no nulls; city derivable via facility |
| scheduled_datetime | TIMESTAMP | TIMESTAMP | already typed correctly |
| actual_datetime | TIMESTAMP | TIMESTAMP | already typed correctly |
| detention_minutes | INTEGER | INTEGER | already typed correctly |
| on_time_flag | BOOLEAN | BOOLEAN | already typed correctly |
| location_city | VARCHAR | — | **drop** — city derivable via `facility_id` → `stg_facilities` |
| location_state | VARCHAR | — | **drop** — city derivable via `facility_id` → `stg_facilities` |

**Tests:** `event_id` unique + not_null; `load_id` not_null; `trip_id` not_null; `facility_id` not_null; `event_type` accepted_values

---

### 13. `stg_maintenance_records` ← `maintenance_records`

**Source columns:** maintenance_id, truck_id, maintenance_date, maintenance_type, odometer_reading, labor_hours, labor_cost, parts_cost, total_cost, facility_location, downtime_hours, service_description

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| maintenance_id | VARCHAR | VARCHAR | PK — not_null, unique |
| truck_id | VARCHAR | VARCHAR | FK to `trucks` |
| maintenance_date | DATE | DATE | already typed correctly |
| maintenance_type | VARCHAR | VARCHAR | 7 values: `Brake`, `Engine`, `Inspection`, `Preventive`, `Repair`, `Tire`, `Transmission` |
| odometer_reading | INTEGER | INTEGER | already typed correctly |
| labor_hours | FLOAT | FLOAT | already typed correctly |
| labor_cost | FLOAT | FLOAT | already typed correctly |
| parts_cost | FLOAT | FLOAT | already typed correctly |
| total_cost | FLOAT | FLOAT | already typed correctly |
| facility_location | VARCHAR | VARCHAR | trash data — keep as-is, no join attempted |
| downtime_hours | FLOAT | FLOAT | already typed correctly |
| service_description | VARCHAR | VARCHAR | free-text |

**Tests:** `maintenance_id` unique + not_null; `truck_id` not_null; `maintenance_type` accepted_values

---

### 14. `stg_safety_incidents` ← `safety_incidents`

**Source columns:** incident_id, trip_id, truck_id, driver_id, incident_date, incident_type, location_city, location_state, at_fault_flag, injury_flag, vehicle_damage_cost, cargo_damage_cost, claim_amount, preventable_flag, description

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| incident_id | VARCHAR | VARCHAR | PK — not_null, unique |
| trip_id | VARCHAR | VARCHAR | FK to `trips` — no nulls |
| truck_id | VARCHAR | VARCHAR | FK to `trucks` — 1 null, no cross-fill possible from trips |
| driver_id | VARCHAR | VARCHAR | FK to `drivers` — 1 null, no cross-fill possible from trips |
| incident_date | TIMESTAMP | TIMESTAMP | already typed correctly |
| incident_type | VARCHAR | VARCHAR | 5 values: `Accident`, `Customer Complaint`, `DOT Violation`, `Equipment Damage`, `Moving Violation` |
| location_city | VARCHAR | VARCHAR | **unreliable** — synthetic data with invalid city/state combos (e.g. Seattle, OK); keep as-is |
| location_state | VARCHAR | VARCHAR | **unreliable** — same as above; keep as-is |
| at_fault_flag | BOOLEAN | BOOLEAN | already typed correctly |
| injury_flag | BOOLEAN | BOOLEAN | already typed correctly |
| vehicle_damage_cost | FLOAT | FLOAT | already typed correctly |
| cargo_damage_cost | FLOAT | FLOAT | already typed correctly |
| claim_amount | FLOAT | FLOAT | already typed correctly |
| preventable_flag | BOOLEAN | BOOLEAN | already typed correctly |
| description | VARCHAR | VARCHAR | free-text |

**Tests:** `incident_id` unique + not_null; `trip_id` not_null; `incident_type` accepted_values

---

### 15. `stg_driver_monthly_metrics` ← `driver_monthly_metrics`

**Source columns:** driver_id, month, trips_completed, total_miles, total_revenue, average_mpg, total_fuel_gallons, on_time_delivery_rate, average_idle_hours

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| driver_id | VARCHAR | VARCHAR | composite PK — FK to `drivers`, no nulls |
| month | DATE | DATE | composite PK — first day of month |
| trips_completed | INTEGER | INTEGER | already typed correctly |
| total_miles | INTEGER | INTEGER | already typed correctly |
| total_revenue | FLOAT | FLOAT | already typed correctly |
| average_mpg | FLOAT | FLOAT | already typed correctly |
| total_fuel_gallons | FLOAT | FLOAT | already typed correctly |
| on_time_delivery_rate | FLOAT | FLOAT | already typed correctly |
| average_idle_hours | FLOAT | FLOAT | already typed correctly |

**Tests:** `driver_id` + `month` not_null; `driver_id` not_null

---

### 16. `stg_truck_utilization_metrics` ← `truck_utilization_metrics`

**Source columns:** truck_id, month, trips_completed, total_miles, total_revenue, average_mpg, maintenance_events, maintenance_cost, downtime_hours, utilization_rate

| Column | Current Type | Staging Type | Notes |
|---|---|---|---|
| truck_id | VARCHAR | VARCHAR | composite PK — FK to `trucks`, no nulls |
| month | DATE | DATE | composite PK — first day of month |
| trips_completed | INTEGER | INTEGER | already typed correctly |
| total_miles | INTEGER | INTEGER | already typed correctly |
| total_revenue | FLOAT | FLOAT | already typed correctly |
| average_mpg | FLOAT | FLOAT | already typed correctly |
| maintenance_events | INTEGER | INTEGER | already typed correctly |
| maintenance_cost | FLOAT | FLOAT | already typed correctly |
| downtime_hours | FLOAT | FLOAT | already typed correctly |
| utilization_rate | FLOAT | FLOAT | already typed correctly |

**Tests:** `truck_id` + `month` not_null; `truck_id` not_null
