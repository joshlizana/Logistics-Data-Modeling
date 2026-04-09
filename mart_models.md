# Mart Models — Decision Log

All mart models live in `logistics_modeling/models/marts/` and `logistics_modeling/models/intermediate/`.  
Conventions: tables, business logic allowed, reference staging via `{{ ref('stg_*') }}`.

---

## Status

| # | Model | Folder | Grain | Status |
|---|---|---|---|---|
| 1 | int_trips_enriched | intermediate/ | trip | ✅ decided |
| 2 | fct_driver_trips | marts/driver_performance/ | trip | ✅ decided |
| 3 | fct_driver_monthly | marts/driver_performance/ | driver + month | ✅ decided |
| 4 | fct_route_trips | marts/route_profitability/ | trip | ✅ decided |
| 5 | fct_lane_monthly | marts/route_profitability/ | lane + month | ✅ decided |
| 6 | fct_fleet_trips | marts/fleet_utilization/ | trip | ✅ decided |
| 7 | fct_truck_maintenance | marts/fleet_utilization/ | maintenance event | ✅ decided |
| 8 | fct_fleet_monthly | marts/fleet_utilization/ | truck + month | ✅ decided |
| 9 | fct_customer_trips | marts/customer_analysis/ | trip | ✅ decided |
| 10 | fct_customer_monthly | marts/customer_analysis/ | customer + month | ✅ decided |
| 11 | dim_drivers | marts/dimensions/ | driver | ✅ decided |
| 12 | dim_trucks | marts/dimensions/ | truck | ✅ decided |
| 13 | dim_trailers | marts/dimensions/ | trailer | ✅ decided |
| 14 | dim_customers | marts/dimensions/ | customer | ✅ decided |
| 15 | dim_facilities | marts/dimensions/ | facility | ✅ decided |
| 16 | dim_routes | marts/dimensions/ | route | ✅ decided |
| 17 | dim_regions | marts/dimensions/ | region | ✅ decided |
| 18 | dim_lanes | marts/dimensions/ | lane | ✅ decided |
| 19 | fct_drivers_summary | marts/driver_performance/ | driver (lifetime) | ✅ decided |
| 20 | fct_trucks_summary | marts/fleet_utilization/ | truck (lifetime) | ✅ decided |
| 21 | fct_trailers_summary | marts/fleet_utilization/ | trailer (lifetime) | ✅ decided |
| 22 | fct_customers_summary | marts/customer_analysis/ | customer (lifetime) | ✅ decided |
| 23 | fct_facilities_summary | marts/dimensions/ | facility (lifetime) | ✅ decided |
| 24 | fct_routes_summary | marts/route_profitability/ | route (lifetime) | ✅ decided |
| 25 | fct_lanes_summary | marts/route_profitability/ | lane (lifetime) | ✅ decided |
| 26 | fct_regions_summary | marts/dimensions/ | region (lifetime) | ✅ decided |

---

## Model Decisions

---

### 1. `int_trips_enriched`

Grain: one row per trip. Shared spine — all mart trip-level models build from this.

**Sources:** stg_trips, stg_loads, stg_routes, stg_lanes, stg_drivers, stg_trucks, stg_trailers, stg_customers

**Columns:**

| Source | Columns |
|---|---|
| stg_trips | trip_id, load_id, driver_id, truck_id, trailer_id, dispatch_date, actual_distance_miles, actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, trip_status |
| stg_loads | customer_id, route_id, load_date, load_type, weight_lbs, pieces, revenue, fuel_surcharge, accessorial_charges, load_status, booking_type |
| stg_routes | lane_id, origin_city_id, destination_city_id, typical_distance_miles, base_rate_per_mile, fuel_surcharge_rate, typical_transit_days |
| stg_lanes | origin_region_id, destination_region_id, lane_type |
| stg_drivers | driver_full_name, cdl_class, years_experience, home_terminal, is_terminated |
| stg_trucks | unit_number, make, model_year, fuel_type, home_terminal as truck_home_terminal |
| stg_trailers | trailer_type, length_feet |
| stg_customers | customer_name, customer_type, credit_terms_days, primary_freight_type, is_active, annual_revenue_potential |

**Derived columns:**
- `total_revenue = revenue + fuel_surcharge + accessorial_charges`
- `revenue_per_mile = total_revenue / NULLIF(COALESCE(actual_distance_miles, typical_distance_miles), 0)` — falls back to typical_distance_miles if actual is null; NULLIF guards against 0 denominator
- `distance_variance_miles = actual_distance_miles - typical_distance_miles`
- `dispatch_month = DATE_TRUNC('month', dispatch_date)`

---

### 2. `fct_driver_trips`

Grain: one row per trip. Driver performance focus.

**Sources:** int_trips_enriched + 3 CTEs rolled up to trip_id grain from stg_delivery_events, stg_fuel_purchases, stg_safety_incidents

| Source | Columns |
|---|---|
| int_trips_enriched | trip_id, load_id, driver_id, truck_id, trailer_id, dispatch_date, dispatch_month, driver_full_name, cdl_class, years_experience, home_terminal, actual_distance_miles, actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, typical_distance_miles, trip_status, total_revenue, revenue_per_mile |
| delivery_events CTE | deliveries_on_time, total_deliveries, pickups_on_time, total_pickups, total_detention_minutes |
| fuel_purchases CTE | fuel_stops, fuel_cost_total, fuel_cost_per_gallon_avg |
| safety_incidents CTE | incident_count, at_fault_count, preventable_count, injury_count, total_incident_cost |

**Derived:**
- `on_time_delivery_pct = deliveries_on_time / NULLIF(total_deliveries, 0)`
- `fuel_cost_per_mile = fuel_cost_total / NULLIF(COALESCE(actual_distance_miles, typical_distance_miles), 0)`
- `idle_pct = idle_time_hours / NULLIF(actual_duration_hours, 0)`
- `estimated_detention_cost = GREATEST(total_detention_minutes - 120, 0) * 1.25` — $75/hr after 2hr grace period; industry average estimate

---

### 3. `fct_driver_monthly`

Grain: one row per (driver_id, dispatch_month). Source: fct_driver_trips.

**Dimensions:** driver_id, driver_full_name, home_terminal, cdl_class, years_experience, dispatch_month

**Aggregated metrics:**
- `total_trips = COUNT(*)`
- `trips_completed = COUNT(*) FILTER (WHERE trip_status = 'Completed')`
- `total_miles = SUM(actual_distance_miles)`
- `total_revenue = SUM(total_revenue)`
- `total_fuel_cost = SUM(fuel_cost_total)`
- `avg_mpg = SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)` — recomputed from sums, not avg of avgs
- `avg_idle_pct = SUM(idle_time_hours) / NULLIF(SUM(actual_duration_hours), 0)` — recomputed from sums, not avg of ratios
- `on_time_delivery_pct = SUM(deliveries_on_time) / NULLIF(SUM(total_deliveries), 0)` — weighted, not avg of pcts
- `total_detention_minutes = SUM(total_detention_minutes)`
- `total_estimated_detention_cost = SUM(estimated_detention_cost)`
- `incident_count = SUM(incident_count)`
- `at_fault_incident_count = SUM(at_fault_count)`
- `preventable_incident_count = SUM(preventable_count)`
- `revenue_per_mile = SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)`
- `fuel_cost_per_mile = SUM(fuel_cost_total) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)`

---

### 4. `fct_route_trips`

Grain: one row per trip. Route/lane profitability focus.

**Sources:** int_trips_enriched + fuel_purchases CTE (by trip_id) + delivery_events CTE (by trip_id)

| Source | Columns |
|---|---|
| int_trips_enriched | trip_id, load_id, route_id, lane_id, origin_city_id, destination_city_id, origin_region_id, destination_region_id, lane_type, dispatch_date, dispatch_month, load_type, weight_lbs, pieces, booking_type, load_status, revenue, fuel_surcharge, accessorial_charges, total_revenue, typical_distance_miles, base_rate_per_mile, fuel_surcharge_rate, typical_transit_days, actual_distance_miles, actual_duration_hours, customer_id, customer_name, customer_type |
| fuel_purchases CTE | fuel_cost_total |
| delivery_events CTE | total_detention_minutes |

**Derived:**
- `net_revenue_after_fuel = total_revenue - fuel_cost_total` — partial net; fuel is the only variable cost available
- `net_revenue_after_fuel_pct = net_revenue_after_fuel / NULLIF(total_revenue, 0)`
- `distance_variance_miles = actual_distance_miles - typical_distance_miles`
- `distance_variance_pct = distance_variance_miles / NULLIF(typical_distance_miles, 0)`
- `revenue_per_mile = total_revenue / NULLIF(COALESCE(actual_distance_miles, typical_distance_miles), 0)`
- `mph_avg = actual_distance_miles / NULLIF(actual_duration_hours, 0)`
- `estimated_detention_cost = GREATEST(total_detention_minutes - 120, 0) * 1.25` — $75/hr after 2hr grace period; industry average estimate

---

### 5. `fct_lane_monthly`

Grain: one row per (lane_id, dispatch_month). Source: fct_route_trips. Lane is the right profitability grain — 58 routes span 49 unique lanes.

**Dimensions:** lane_id, origin_region_id, destination_region_id, lane_type, dispatch_month

**Aggregated metrics:**
- `trip_count = COUNT(*)`
- `trips_completed = COUNT(*) FILTER (WHERE load_status = 'Completed')`
- `route_count = COUNT(DISTINCT route_id)`
- `total_revenue = SUM(total_revenue)`
- `total_fuel_cost = SUM(fuel_cost_total)`
- `total_net_revenue_after_fuel = SUM(net_revenue_after_fuel)`
- `net_revenue_after_fuel_pct = SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` — weighted
- `revenue_per_mile = SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)` — weighted
- `distance_variance_pct = SUM(distance_variance_miles) / NULLIF(SUM(typical_distance_miles), 0)` — recomputed from sums, not avg of pcts
- `avg_mph = SUM(actual_distance_miles) / NULLIF(SUM(actual_duration_hours), 0)` — recomputed from sums, not avg of avgs
- `total_weight_lbs = SUM(weight_lbs)`
- `total_detention_minutes = SUM(total_detention_minutes)`
- `total_estimated_detention_cost = SUM(estimated_detention_cost)`

---

### 6. `fct_fleet_trips`

Grain: one row per trip. Truck/trailer asset focus.

**Sources:** int_trips_enriched + fuel_purchases CTE (by trip_id)

| Source | Columns |
|---|---|
| int_trips_enriched | trip_id, truck_id, trailer_id, driver_id, dispatch_date, dispatch_month, unit_number, make, model_year, fuel_type, truck_home_terminal, trailer_type, length_feet, actual_distance_miles, actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, typical_distance_miles, trip_status, load_type, weight_lbs, total_revenue |
| fuel_purchases CTE | fuel_cost_total |

**Derived:**
- `idle_pct = idle_time_hours / NULLIF(actual_duration_hours, 0)`
- `revenue_per_mile = total_revenue / NULLIF(COALESCE(actual_distance_miles, typical_distance_miles), 0)`
- `fuel_cost_per_mile = fuel_cost_total / NULLIF(COALESCE(actual_distance_miles, typical_distance_miles), 0)`

---

### 7. `fct_truck_maintenance`

Grain: one row per maintenance event.

**Sources:** stg_maintenance_records + stg_trucks + fct_trucks_summary (for avg_daily_revenue)

| Source | Columns |
|---|---|
| stg_maintenance_records | maintenance_id, truck_id, maintenance_date, maintenance_type, odometer_reading, labor_hours, labor_cost, parts_cost, total_cost, downtime_hours, service_description |
| stg_trucks | unit_number, make, model_year, fuel_type, home_terminal |
| fct_trucks_summary | avg_daily_revenue |

**Derived:**
- `maintenance_month = DATE_TRUNC('month', maintenance_date)`
- `cost_per_downtime_hour = total_cost / NULLIF(downtime_hours, 0)`
- `opportunity_cost = avg_daily_revenue * (downtime_hours / 24.0)` — lost revenue while truck is out of service

---

### 8. `fct_fleet_monthly`

Grain: one row per (truck_id, month). FULL OUTER JOIN of trip aggregates + maintenance aggregates — captures months with maintenance but no trips.

**Sources:** fct_fleet_trips (grouped by truck_id + dispatch_month) + fct_truck_maintenance (grouped by truck_id + maintenance_month)

**Dimensions:** truck_id, unit_number, make, model_year, fuel_type, home_terminal, month

**From trip aggregates:**
- `total_trips = COUNT(*)`
- `trips_completed = COUNT(*) FILTER (WHERE trip_status = 'Completed')`
- `total_miles = SUM(actual_distance_miles)`
- `total_revenue = SUM(total_revenue)`
- `total_fuel_cost = SUM(fuel_cost_total)`
- `avg_mpg = SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)` — recomputed from sums
- `total_idle_hours = SUM(idle_time_hours)`

**From maintenance aggregates:**
- `maintenance_events = COUNT(*)`
- `total_maintenance_cost = SUM(total_cost)`
- `total_downtime_hours = SUM(downtime_hours)`
- `total_opportunity_cost = SUM(opportunity_cost)`

**Derived:**
- `total_operating_cost = COALESCE(total_fuel_cost, 0) + COALESCE(total_maintenance_cost, 0)`
- `revenue_per_mile = SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)`

Note: `maintenance_cost_per_mile` dropped — misleading at monthly grain when maintenance and miles don't track together (e.g. truck in shop all month).

---

### 9. `fct_customer_trips`

Grain: one row per trip. Customer service and revenue focus.

**Sources:** int_trips_enriched + delivery_events CTE (by trip_id)

| Source | Columns |
|---|---|
| int_trips_enriched | trip_id, load_id, customer_id, dispatch_date, dispatch_month, load_date, customer_name, customer_type, primary_freight_type, is_active, credit_terms_days, annual_revenue_potential, load_type, weight_lbs, pieces, booking_type, load_status, trip_status, route_id, lane_id, lane_type, origin_region_id, destination_region_id, typical_transit_days, actual_duration_hours, revenue, fuel_surcharge, accessorial_charges, total_revenue |
| delivery_events CTE | deliveries_on_time, total_deliveries, pickups_on_time, total_pickups, total_detention_minutes |

**Derived:**
- `on_time_delivery_pct = deliveries_on_time / NULLIF(total_deliveries, 0)`
- `accessorial_pct = accessorial_charges / NULLIF(total_revenue, 0)`
- `vs_typical_transit_hours = actual_duration_hours - (typical_transit_days * 24.0)`
- `estimated_detention_cost = GREATEST(total_detention_minutes - 120, 0) * 1.25` — $75/hr after 2hr grace period; industry average estimate

---

### 10. `fct_customer_monthly`

Grain: one row per (customer_id, dispatch_month). Source: fct_customer_trips.

**Dimensions:** customer_id, customer_name, customer_type, primary_freight_type, is_active, annual_revenue_potential, dispatch_month

**Aggregated metrics:**
- `load_count = COUNT(DISTINCT load_id)`
- `trip_count = COUNT(*)`
- `total_revenue = SUM(total_revenue)`
- `total_accessorial_charges = SUM(accessorial_charges)`
- `accessorial_pct = SUM(accessorial_charges) / NULLIF(SUM(total_revenue), 0)` — weighted
- `total_weight_lbs = SUM(weight_lbs)`
- `total_pieces = SUM(pieces)`
- `on_time_delivery_pct = SUM(deliveries_on_time) / NULLIF(SUM(total_deliveries), 0)` — weighted
- `total_detention_minutes = SUM(total_detention_minutes)`
- `avg_detention_per_trip = SUM(total_detention_minutes) / NULLIF(COUNT(*), 0)`
- `total_estimated_detention_cost = SUM(estimated_detention_cost)`
- `avg_revenue_per_trip = SUM(total_revenue) / NULLIF(COUNT(*), 0)`
- `revenue_vs_potential_pct = SUM(total_revenue) / NULLIF(MAX(annual_revenue_potential) / 12.0, 0)` — monthly revenue as share of annualised potential; MAX() needed in aggregate context (constant per customer)

---

### 11. `dim_drivers`

Grain: one row per driver. Descriptive attributes only — no lifetime stats (those go in fct_drivers_summary).

**Source:** stg_drivers

| Column | Notes |
|---|---|
| driver_id | PK |
| driver_full_name | |
| first_name | |
| last_name | |
| hire_date | |
| termination_date | nullable |
| date_of_birth | |
| license_number | |
| license_state | |
| home_terminal | |
| is_terminated | boolean |
| cdl_class | |
| years_experience | |
| age | derived: `DATE_DIFF('year', date_of_birth, CURRENT_DATE)` |
| tenure_years | derived: `DATE_DIFF('year', hire_date, COALESCE(termination_date, CURRENT_DATE))` |

---

### 12. `dim_trucks`

Grain: one row per truck. Descriptive attributes only — no lifetime stats (those go in fct_trucks_summary).

**Source:** stg_trucks

| Column | Notes |
|---|---|
| truck_id | PK |
| unit_number | |
| make | |
| model_year | |
| vin | |
| acquisition_date | |
| acquisition_mileage | |
| fuel_type | |
| tank_capacity_gallons | |
| status | `Active`, `Maintenance`, `Inactive` |
| home_terminal | |
| age_years | derived: `YEAR(CURRENT_DATE) - model_year` |

---

### 13. `dim_trailers`

Grain: one row per trailer. Descriptive attributes only — no lifetime stats (those go in fct_trailers_summary).

**Source:** stg_trailers

| Column | Notes |
|---|---|
| trailer_id | PK |
| trailer_number | |
| trailer_type | `Dry Van`, `Refrigerated` |
| length_feet | |
| model_year | |
| vin | |
| acquisition_date | |
| status | |
| current_location | free-text city name, no FK — keep as-is |
| age_years | derived: `YEAR(CURRENT_DATE) - model_year` |

---

### 14. `dim_customers`

Grain: one row per customer. Descriptive attributes only — no lifetime stats (those go in fct_customers_summary).

**Source:** stg_customers

| Column | Notes |
|---|---|
| customer_id | PK |
| customer_name | |
| customer_type | `Dedicated`, `Contract`, `Spot` |
| credit_terms_days | |
| primary_freight_type | |
| is_active | boolean |
| contract_start_date | |
| annual_revenue_potential | |
| contract_tenure_years | derived: `DATE_DIFF('year', contract_start_date, CURRENT_DATE)` |

---

### 15. `dim_facilities`

Grain: one row per facility. Descriptive attributes only — no lifetime stats (those go in fct_facilities_summary).

**Sources:** stg_facilities + stg_regions (for region_name) + cities (for city, state)

| Column | Notes |
|---|---|
| facility_id | PK |
| facility_name | |
| facility_type | `Cross-Dock`, `Distribution Center`, `Terminal`, `Warehouse` |
| city_id | FK to cities |
| city | joined from cities |
| state | joined from cities |
| latitude | |
| longitude | |
| dock_doors | |
| operating_hours_start | |
| operating_hours_end | |
| region_id | FK to regions |
| region_name | joined from stg_regions |

---

### 16. `dim_routes`

Grain: one row per route. Descriptive attributes only — no lifetime stats (those go in fct_routes_summary).

**Sources:** stg_routes + stg_lanes + stg_regions (x2 for origin/destination) + cities (x2 for origin/destination)

| Column | Notes |
|---|---|
| route_id | PK |
| lane_id | FK |
| lane_type | joined from stg_lanes |
| origin_city_id | FK |
| origin_city | joined from cities |
| origin_state | joined from cities |
| origin_region_id | joined from stg_lanes |
| origin_region_name | joined from stg_regions |
| destination_city_id | FK |
| destination_city | joined from cities |
| destination_state | joined from cities |
| destination_region_id | joined from stg_lanes |
| destination_region_name | joined from stg_regions |
| typical_distance_miles | |
| base_rate_per_mile | |
| fuel_surcharge_rate | |
| typical_transit_days | |

---

### 17. `dim_regions`

Grain: one row per region. Pure pass-through from stg_regions.

**Source:** stg_regions

| Column | Notes |
|---|---|
| region_id | PK |
| region_name | |
| centroid_latitude | |
| centroid_longitude | |

---

### 18. `dim_lanes`

Grain: one row per lane. Enriched with region names for readability.

**Sources:** stg_lanes + stg_regions (x2 for origin/destination)

| Column | Notes |
|---|---|
| lane_id | PK |
| lane_type | `local`, `over_the_road` |
| origin_region_id | FK |
| origin_region_name | joined from stg_regions |
| destination_region_id | FK |
| destination_region_name | joined from stg_regions |

---

### 19. `fct_drivers_summary`

Grain: one row per driver. Lifetime stats. Source: fct_driver_trips.

| Column | Notes |
|---|---|
| driver_id | PK |
| first_trip_date | `MIN(dispatch_date)` |
| last_trip_date | `MAX(dispatch_date)` |
| total_trips | `COUNT(*)` |
| trips_completed | `COUNT(*) FILTER (WHERE trip_status = 'Completed')` |
| total_miles | `SUM(actual_distance_miles)` |
| total_revenue | `SUM(total_revenue)` |
| total_fuel_cost | `SUM(fuel_cost_total)` |
| avg_mpg | `SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)` |
| total_idle_hours | `SUM(idle_time_hours)` |
| on_time_delivery_pct | `SUM(deliveries_on_time) / NULLIF(SUM(total_deliveries), 0)` |
| total_detention_minutes | `SUM(total_detention_minutes)` |
| total_estimated_detention_cost | `SUM(estimated_detention_cost)` |
| incident_count | `SUM(incident_count)` |
| at_fault_incident_count | `SUM(at_fault_count)` |
| preventable_incident_count | `SUM(preventable_count)` |
| revenue_per_mile | `SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)` |
| avg_daily_revenue | `total_revenue / NULLIF(DATEDIFF('day', first_trip_date, last_trip_date), 0)` — DATEDIFF returns integer days |

---

### 20. `fct_trucks_summary`

Grain: one row per truck. Lifetime aggregated stats. Built before `fct_truck_maintenance` so opportunity cost can be joined in.

**Sources:** stg_trucks + fct_fleet_trips (aggregated by truck_id)

| Source | Columns |
|---|---|
| stg_trucks | truck_id, unit_number, make, model_year, fuel_type, home_terminal, acquisition_date, status |

**Aggregated from fct_fleet_trips:**
- `total_trips = COUNT(*)`
- `trips_completed = COUNT(*) FILTER (WHERE trip_status = 'Completed')`
- `total_miles = SUM(actual_distance_miles)`
- `total_revenue = SUM(total_revenue)`
- `total_fuel_cost = SUM(fuel_cost_total)`
- `avg_mpg = SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)` — recomputed from sums
- `total_idle_hours = SUM(idle_time_hours)`
- `first_trip_date = MIN(dispatch_date)`
- `last_trip_date = MAX(dispatch_date)`

**Derived:**
- `days_in_service = DATEDIFF('day', first_trip_date, last_trip_date)` — integer days
- `avg_daily_revenue = total_revenue / NULLIF(days_in_service, 0)` — used for opportunity cost in fct_truck_maintenance

---

### 21. `fct_trailers_summary`

Grain: one row per trailer. Lifetime stats. Source: fct_fleet_trips grouped by trailer_id.

| Column | Notes |
|---|---|
| trailer_id | PK |
| first_trip_date | `MIN(dispatch_date)` |
| last_trip_date | `MAX(dispatch_date)` |
| total_trips | `COUNT(*)` |
| trips_completed | `COUNT(*) FILTER (WHERE trip_status = 'Completed')` |
| total_miles | `SUM(actual_distance_miles)` |
| total_revenue | `SUM(total_revenue)` |
| total_weight_lbs | `SUM(weight_lbs)` |
| dry_van_trips | `COUNT(*) FILTER (WHERE trailer_type = 'Dry Van')` |
| refrigerated_trips | `COUNT(*) FILTER (WHERE trailer_type = 'Refrigerated')` |
| revenue_per_mile | `SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)` |
| avg_daily_revenue | `total_revenue / NULLIF(DATEDIFF('day', first_trip_date, last_trip_date), 0)` |

---

### 22. `fct_customers_summary`

Grain: one row per customer. Lifetime stats. Source: fct_customer_trips grouped by customer_id.

| Column | Notes |
|---|---|
| customer_id | PK |
| first_trip_date | `MIN(dispatch_date)` |
| last_trip_date | `MAX(dispatch_date)` |
| total_loads | `COUNT(DISTINCT load_id)` |
| total_trips | `COUNT(*)` |
| trips_completed | `COUNT(*) FILTER (WHERE trip_status = 'Completed')` |
| total_revenue | `SUM(total_revenue)` |
| total_accessorial_charges | `SUM(accessorial_charges)` |
| accessorial_pct | `SUM(accessorial_charges) / NULLIF(SUM(total_revenue), 0)` |
| total_weight_lbs | `SUM(weight_lbs)` |
| on_time_delivery_pct | `SUM(deliveries_on_time) / NULLIF(SUM(total_deliveries), 0)` |
| total_detention_minutes | `SUM(total_detention_minutes)` |
| total_estimated_detention_cost | `SUM(estimated_detention_cost)` |
| avg_revenue_per_trip | `SUM(total_revenue) / NULLIF(COUNT(*), 0)` |
| avg_daily_revenue | `SUM(total_revenue) / NULLIF(DATEDIFF('day', first_trip_date, last_trip_date), 0)` — NULL if only 1 day of activity |
| revenue_vs_potential_pct | `SUM(total_revenue) / NULLIF(MAX(annual_revenue_potential), 0)` — lifetime revenue vs total potential; MAX() needed in aggregate context (constant per customer) |

---

### 23. `fct_facilities_summary`

Grain: one row per facility. Lifetime stats. Sources: stg_delivery_events + fct_route_trips (for revenue).

**Implementation note:** Two CTEs required to avoid fan-out. CTE 1 aggregates stg_delivery_events at facility_id grain (event counts, detention, on-time). CTE 2 aggregates fct_route_trips revenue at facility_id grain via stg_delivery_events (using DISTINCT trip_id to avoid counting revenue multiple times when a trip has multiple events at the same facility). Final SELECT joins both CTEs on facility_id.

| Column | Notes |
|---|---|
| facility_id | PK |
| first_event_date | `MIN(actual_datetime::DATE)` — from events CTE |
| last_event_date | `MAX(actual_datetime::DATE)` — from events CTE |
| total_events | `COUNT(*)` — from events CTE |
| total_pickups | `COUNT(*) FILTER (WHERE event_type = 'Pickup')` — from events CTE |
| total_deliveries | `COUNT(*) FILTER (WHERE event_type = 'Delivery')` — from events CTE |
| on_time_pct | `SUM(on_time_flag::int)::FLOAT / NULLIF(COUNT(*), 0)` — cast to float to avoid integer truncation; from events CTE |
| total_detention_minutes | `SUM(detention_minutes)` — from events CTE |
| avg_detention_per_event | `SUM(detention_minutes) / NULLIF(COUNT(*), 0)` — from events CTE |
| estimated_detention_cost | `SUM(GREATEST(detention_minutes - 120, 0) * 1.25)` — per-event grace period; from events CTE |
| unique_loads | `COUNT(DISTINCT load_id)` — from events CTE |
| unique_trips | `COUNT(DISTINCT trip_id)` — from events CTE |
| revenue_throughput | `SUM(total_revenue)` — from revenue CTE (deduplicated by trip_id per facility) |
| net_revenue_throughput | `SUM(net_revenue_after_fuel)` — from revenue CTE (deduplicated by trip_id per facility) |

---

### 24. `fct_routes_summary`

Grain: one row per route. Lifetime stats. Source: fct_route_trips grouped by route_id.

| Column | Notes |
|---|---|
| route_id | PK |
| first_trip_date | `MIN(dispatch_date)` |
| last_trip_date | `MAX(dispatch_date)` |
| total_trips | `COUNT(*)` |
| trips_completed | `COUNT(*) FILTER (WHERE load_status = 'Completed')` |
| total_revenue | `SUM(total_revenue)` |
| total_fuel_cost | `SUM(fuel_cost_total)` |
| total_net_revenue_after_fuel | `SUM(net_revenue_after_fuel)` |
| net_revenue_after_fuel_pct | `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` |
| total_weight_lbs | `SUM(weight_lbs)` |
| total_detention_minutes | `SUM(total_detention_minutes)` |
| total_estimated_detention_cost | `SUM(estimated_detention_cost)` — pre-computed per trip in fct_route_trips |
| revenue_per_mile | `SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)` |
| avg_mph | `SUM(actual_distance_miles) / NULLIF(SUM(actual_duration_hours), 0)` |
| distance_variance_pct | `SUM(distance_variance_miles) / NULLIF(SUM(typical_distance_miles), 0)` |

---

### 25. `fct_lanes_summary`

Grain: one row per lane. Lifetime stats. Source: fct_route_trips grouped by lane_id.

| Column | Notes |
|---|---|
| lane_id | PK |
| first_trip_date | `MIN(dispatch_date)` |
| last_trip_date | `MAX(dispatch_date)` |
| total_trips | `COUNT(*)` |
| trips_completed | `COUNT(*) FILTER (WHERE load_status = 'Completed')` |
| route_count | `COUNT(DISTINCT route_id)` |
| total_revenue | `SUM(total_revenue)` |
| total_fuel_cost | `SUM(fuel_cost_total)` |
| total_net_revenue_after_fuel | `SUM(net_revenue_after_fuel)` |
| net_revenue_after_fuel_pct | `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` |
| total_weight_lbs | `SUM(weight_lbs)` |
| total_detention_minutes | `SUM(total_detention_minutes)` |
| total_estimated_detention_cost | `SUM(estimated_detention_cost)` — pre-computed per trip in fct_route_trips |
| revenue_per_mile | `SUM(total_revenue) / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)` |
| avg_mph | `SUM(actual_distance_miles) / NULLIF(SUM(actual_duration_hours), 0)` |
| distance_variance_pct | `SUM(distance_variance_miles) / NULLIF(SUM(typical_distance_miles), 0)` |

---

### 26. `fct_regions_summary`

Grain: one row per region. Lifetime stats. Source: fct_route_trips — trips are counted once per region using UNION ALL, with local lanes (origin = destination region) only counted as origin to avoid double-counting.

**Logic:** UNION ALL of origin trips + over_the_road destination trips only (local lanes excluded from destination to prevent double-counting).

| Column | Notes |
|---|---|
| region_id | PK |
| total_trips_as_origin | trips where `origin_region_id = region_id` |
| total_trips_as_destination | trips where `destination_region_id = region_id` and `lane_type = 'over_the_road'` |
| total_trips | `total_trips_as_origin + total_trips_as_destination` — no double-counting |
| total_revenue_as_origin | `SUM(total_revenue)` on origin trips |
| total_revenue_as_destination | `SUM(total_revenue)` on destination trips |
| total_revenue | combined revenue across both directions |
| total_net_revenue_after_fuel | combined net revenue across both directions |
| net_revenue_after_fuel_pct | `total_net_revenue_after_fuel / NULLIF(total_revenue, 0)` |
| total_detention_minutes | combined across both directions |
| total_estimated_detention_cost | `SUM(estimated_detention_cost)` — pre-computed per trip in fct_route_trips |
| unique_routes | `COUNT(DISTINCT route_id)` |
| unique_lanes | `COUNT(DISTINCT lane_id)` |
