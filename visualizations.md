# Visualizations — Decision Log

Evidence (evidence.dev) dashboards built against the logistics data mart in DuckDB.  
Framework: code-based BI — each page is a markdown file with embedded SQL queries and chart components.  
Output: static HTML site generated via `npm run build`, served from `evidence-app/build/`.  
Data: 85,410 trips across 50 drivers, 100 trucks, 49 lanes, 58 routes, 10 regions, 25 customers, ~200 facilities (2022-2024).

---

## Status

| # | Page | Path | Primary Tables | Status |
|---|---|---|---|---|
| 1 | Executive Summary | `pages/index.md` | fct_route_trips, fct_regions_summary, fct_lanes_summary | planned |
| 2 | Driver Performance | `pages/drivers/index.md` | fct_drivers_summary, fct_driver_monthly, dim_drivers | planned |
| 3 | Driver Detail | `pages/drivers/detail.md` | fct_drivers_summary, fct_driver_monthly, dim_drivers | planned |
| 4 | Fleet Utilization | `pages/fleet/index.md` | fct_trucks_summary, fct_trailers_summary, dim_trucks, dim_trailers | planned |
| 5 | Truck Detail | `pages/fleet/detail.md` | fct_trucks_summary, fct_fleet_monthly, fct_truck_maintenance, dim_trucks | planned |
| 6 | Maintenance Analysis | `pages/fleet/maintenance.md` | fct_truck_maintenance, dim_trucks | planned |
| 7 | Route & Lane Profitability | `pages/routes/index.md` | fct_lanes_summary, fct_routes_summary, fct_lane_monthly, dim_lanes | planned |
| 8 | Regional Analysis | `pages/routes/regions.md` | fct_regions_summary, fct_route_trips, fct_lane_monthly, dim_regions | planned |
| 9 | Customer Analysis | `pages/customers/index.md` | fct_customers_summary, fct_customer_monthly, dim_customers | planned |
| 10 | Customer Detail | `pages/customers/detail.md` | fct_customers_summary, fct_customer_monthly, dim_customers | planned |
| 11 | Customer Profitability | `pages/customers/profitability.md` | fct_route_trips, dim_customers | planned |
| 12 | Facility Operations | `pages/facilities/index.md` | fct_facilities_summary, dim_facilities | planned |
| 13 | Operational Efficiency | `pages/operations/index.md` | fct_driver_monthly, fct_driver_trips, fct_drivers_summary, fct_lanes_summary, dim_drivers | planned |

---

## Static Output

Evidence compiles the markdown pages into static HTML. After `npm run build`, the output is in `evidence-app/build/`:

| Source Page | Static URL Path | Generated Files |
|---|---|---|
| `pages/index.md` | `/` | `build/index.html` |
| `pages/drivers/index.md` | `/drivers` | `build/drivers/index.html` |
| `pages/drivers/detail.md` | `/drivers/detail` | `build/drivers/detail/index.html` — single page, driver selected via dropdown |
| `pages/fleet/index.md` | `/fleet` | `build/fleet/index.html` |
| `pages/fleet/detail.md` | `/fleet/detail` | `build/fleet/detail/index.html` — single page, truck selected via dropdown |
| `pages/fleet/maintenance.md` | `/fleet/maintenance` | `build/fleet/maintenance/index.html` |
| `pages/routes/index.md` | `/routes` | `build/routes/index.html` |
| `pages/routes/regions.md` | `/routes/regions` | `build/routes/regions/index.html` |
| `pages/customers/index.md` | `/customers` | `build/customers/index.html` |
| `pages/customers/detail.md` | `/customers/detail` | `build/customers/detail/index.html` — single page, customer selected via dropdown |
| `pages/customers/profitability.md` | `/customers/profitability` | `build/customers/profitability/index.html` |
| `pages/facilities/index.md` | `/facilities` | `build/facilities/index.html` |
| `pages/operations/index.md` | `/operations` | `build/operations/index.html` |

**Total static pages:** 13 HTML files. Detail pages use client-side `<Dropdown>` components for entity selection — no per-ID page generation.

**Serving requirement:** The build output is a SvelteKit SPA — pages hydrate client-side via JavaScript and require a web server. They cannot be opened directly from the filesystem. To serve the production build locally: `npx serve evidence-app/build`. For deployment, any static hosting provider works (Netlify, Vercel, S3 + CloudFront, etc.).

---

## Page Specifications

---

### 1. Executive Summary

**Path:** `pages/index.md`  
**Static output:** `build/index.html`  
**Purpose:** Fleet-wide KPIs and trend overview at a glance — the landing page for all stakeholders.

**Navigation Tiles:**

| Tile | Link | Description |
|---|---|---|
| Driver Performance | `/drivers` | Compare all drivers on revenue, efficiency, safety, and on-time delivery |
| Driver Detail | `/drivers/detail` | Deep dive on a single driver — select by name, view monthly trends and peer comparison |
| Fleet Utilization | `/fleet` | Truck and trailer asset performance by make, age, and type |
| Truck Detail | `/fleet/detail` | Individual truck revenue, fuel cost, and maintenance history over time |
| Maintenance Analysis | `/fleet/maintenance` | Fleet-wide maintenance cost trends, type breakdown, and age correlation |
| Route & Lane Profitability | `/routes` | Lane and route margin analysis — identify the most and least profitable corridors |
| Regional Analysis | `/routes/regions` | Origin-destination freight flow, regional revenue splits, and corridor margins |
| Customer Analysis | `/customers` | Customer portfolio — revenue concentration, service quality, and growth opportunities |
| Customer Detail | `/customers/detail` | Individual customer monthly trends, service quality, and peer comparison |
| Customer Profitability | `/customers/profitability` | Per-customer margin analysis — flag accounts at or below 5% for renegotiation |
| Facility Operations | `/facilities` | Detention hotspots, on-time performance, and escalation candidates by facility |
| Operational Efficiency | `/operations` | Fleet-wide detention, fuel, safety, and idle trends across terminals |

Rendered as a grid of clickable cards using Evidence `<LinkCard>` components, giving unfamiliar users a guided overview of all available analytics.

**KPI Cards:**

| Metric | Source | Derivation |
|---|---|---|
| Total Trips | fct_route_trips | `COUNT(*)` |
| Total Revenue | fct_route_trips | `SUM(total_revenue)` |
| Net Margin % | fct_route_trips | `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` |
| Total Detention Cost | fct_route_trips | `SUM(estimated_detention_cost)` |
| Unique Routes | fct_route_trips | `COUNT(DISTINCT route_id)` |
| Unique Lanes | fct_route_trips | `COUNT(DISTINCT lane_id)` |

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Revenue Trend | Line | dispatch_month | total_revenue, net_revenue_after_fuel | Dual series; monthly grain from fct_route_trips grouped by dispatch_month |
| Revenue by Region | Bar (horizontal) | region_name | total_revenue | fct_regions_summary joined to dim_regions; ordered descending |
| Top 10 Lanes | DataTable | — | — | fct_lanes_summary joined to dim_lanes; columns: origin_region_name, destination_region_name, lane_type, total_trips, total_revenue, net_revenue_after_fuel_pct; sorted by total_revenue DESC LIMIT 10 |

**Query sources:**
- `fct_route_trips` — KPIs (single-row aggregate) and monthly trend (GROUP BY dispatch_month)
- `fct_regions_summary` + `dim_regions` — region bar chart
- `fct_lanes_summary` + `dim_lanes` — top lanes table

**Analytical value:** Provides a single entry point for all stakeholders to assess fleet health. The revenue trend with net revenue overlay immediately shows whether margins are stable or compressing over time. The region bar chart identifies geographic concentration, while the top lanes table highlights the corridors driving the most volume and revenue.

---

### 2. Driver Performance

**Path:** `pages/drivers/index.md`  
**Static output:** `build/drivers/index.html`  
**Purpose:** Compare all drivers across revenue, efficiency, safety, and service quality. Identify top performers and terminal-level patterns.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Driver Rankings | DataTable | — | — | fct_drivers_summary + dim_drivers; columns: driver_name, home_terminal, total_trips, total_revenue, revenue_per_mile, on_time_delivery_pct, incident_count, avg_mpg; sortable, searchable |
| Efficiency Scatter | ScatterPlot | revenue_per_mile | on_time_delivery_pct | Same source; bubble size = total_trips, color = home_terminal |
| Revenue by Terminal | Bar | home_terminal | total_revenue | fct_drivers_summary + dim_drivers grouped by home_terminal |
| Monthly On-Time Trend | Line | dispatch_month | on_time_delivery_pct | fct_driver_monthly; fleet-wide weighted: `SUM(deliveries_on_time)::float / NULLIF(SUM(total_deliveries), 0)` |
| Active Driver Count | Line | dispatch_month | active_drivers | fct_driver_monthly; `COUNT(DISTINCT driver_id)` per month |

**Query sources:**
- `fct_drivers_summary` + `dim_drivers` — rankings, scatter, terminal grouping
- `fct_driver_monthly` — monthly trends (GROUP BY dispatch_month)

**Analytical value:** Terminal-level grouping surfaces whether performance differences are structural (terminal assignment, regional lane mix) vs individual. The scatter plot identifies drivers who are both efficient and reliable vs those trading one for the other.

---

### 3. Driver Detail

**Path:** `pages/drivers/detail.md`  
**Static output:** `build/drivers/detail/index.html`  
**Purpose:** Deep dive on a single driver — select by name via dropdown, view monthly trend, peer comparison, and incident history.

**Interaction pattern:** A `<Dropdown>` component at the top of the page lists all drivers by name. Selecting a driver filters all queries and charts on the page to that driver. All driver data is embedded in the static page at build time — the dropdown performs client-side filtering, no server required.

```markdown
<Dropdown name=driver_selector data={driver_list} value=driver_id label=driver_name title="Select Driver" />
```

The driver list query provides the dropdown options:
```sql
-- driver_list
SELECT ds.driver_id, d.driver_full_name as driver_name
FROM main.fct_drivers_summary ds
JOIN main.dim_drivers d ON ds.driver_id = d.driver_id
ORDER BY d.driver_full_name
```

All downstream queries filter via `WHERE driver_id = '${inputs.driver_selector.value}'`.

**KPI Cards:**

| Metric | Source | Derivation |
|---|---|---|
| Total Revenue | fct_drivers_summary | total_revenue |
| Total Trips | fct_drivers_summary | total_trips |
| On-Time % | fct_drivers_summary | on_time_delivery_pct |
| Avg MPG | fct_drivers_summary | avg_mpg |
| Incidents | fct_drivers_summary | incident_count |
| Revenue/Mile | fct_drivers_summary | revenue_per_mile |

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Monthly Performance | Line | dispatch_month | total_revenue, total_miles | fct_driver_monthly filtered by selected driver |
| Monthly MPG & Idle | Line | dispatch_month | avg_mpg, avg_idle_pct | Same source; dual axis |
| Peer Comparison | Bar (grouped) | metric | this_driver vs fleet_avg | Compares: revenue_per_mile, on_time_delivery_pct, avg_mpg; fleet average from `AVG()` over fct_drivers_summary |

**Query sources:**
- `fct_drivers_summary` + `dim_drivers` — KPIs, profile info, and dropdown options
- `fct_driver_monthly` — monthly trend, filtered by selected driver
- `fct_drivers_summary` (unfiltered) — fleet averages for peer comparison

**Analytical value:** Enables managers to investigate a specific driver's performance trajectory without navigating away from the page. The peer comparison bars immediately show whether a driver is above or below fleet norms across key metrics. Monthly MPG and idle trends can reveal behavioral changes — a sudden MPG drop may indicate a mechanical issue or route change, not a driver problem.

**Navigation:** Linked from Driver Performance ranking table.

---

### 4. Fleet Utilization

**Path:** `pages/fleet/index.md`  
**Static output:** `build/fleet/index.html`  
**Purpose:** Truck and trailer asset performance — revenue generation, fuel efficiency, and utilization patterns by make, age, and type.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Truck Rankings | DataTable | — | — | fct_trucks_summary + dim_trucks; columns: unit_number, make, model_year, age_years, total_trips, total_revenue, total_miles, avg_mpg, avg_daily_revenue; sortable |
| Revenue by Make | Bar | make | total_revenue | Grouped from fct_trucks_summary + dim_trucks |
| MPG by Truck Age | Scatter | age_years | avg_mpg | fct_trucks_summary + dim_trucks; excludes trucks with 0 trips; reveals age-efficiency degradation |
| Trailer Utilization | DataTable | — | — | fct_trailers_summary + dim_trailers; columns: trailer_number, trailer_type, length_feet, total_trips, total_revenue, total_weight_lbs, revenue_per_mile |
| Revenue by Trailer Type | Bar | trailer_type | total_revenue | Grouped from fct_trailers_summary + dim_trailers |

**Query sources:**
- `fct_trucks_summary` + `dim_trucks` — truck rankings, make grouping, age scatter
- `fct_trailers_summary` + `dim_trailers` — trailer table and type grouping

**Analytical value:** The age vs MPG scatter identifies whether older trucks are disproportionately expensive to operate. Make-level groupings inform procurement decisions. The 28 trucks with zero trips (included via LEFT JOIN in fct_trucks_summary) surface idle assets.

---

### 5. Truck Detail

**Path:** `pages/fleet/detail.md`  
**Static output:** `build/fleet/detail/index.html`  
**Purpose:** Individual truck deep dive — select by unit number via dropdown, view operating performance over time alongside maintenance history.

**Interaction pattern:** A `<Dropdown>` component at the top of the page lists all trucks by unit number (with make and model year for context). All truck data is embedded at build time; the dropdown performs client-side filtering.

```markdown
<Dropdown name=truck_selector data={truck_list} value=truck_id label=truck_label title="Select Truck" />
```

The truck list query provides the dropdown options:
```sql
-- truck_list
SELECT ts.truck_id, t.unit_number || ' — ' || t.make || ' ' || t.model_year as truck_label
FROM main.fct_trucks_summary ts
JOIN main.dim_trucks t ON ts.truck_id = t.truck_id
ORDER BY t.unit_number
```

All downstream queries filter via `WHERE truck_id = '${inputs.truck_selector.value}'`.

**KPI Cards:**

| Metric | Source | Derivation |
|---|---|---|
| Total Revenue | fct_trucks_summary | total_revenue |
| Total Miles | fct_trucks_summary | total_miles |
| Avg MPG | fct_trucks_summary | avg_mpg |
| Days in Service | fct_trucks_summary | days_in_service |
| Avg Daily Revenue | fct_trucks_summary | avg_daily_revenue |

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Monthly Revenue & Cost | Line | month | total_revenue, total_fuel_cost, total_maintenance_cost | fct_fleet_monthly filtered by selected truck; shows revenue minus cost convergence |
| Monthly Operating Cost | Stacked Bar | month | total_fuel_cost, total_maintenance_cost | Same source; decomposes total_operating_cost |
| Maintenance Log | DataTable | — | — | fct_truck_maintenance filtered by selected truck; columns: maintenance_date, maintenance_type, service_description, total_cost, downtime_hours, opportunity_cost |

**Query sources:**
- `fct_trucks_summary` + `dim_trucks` — KPIs, profile, and dropdown options
- `fct_fleet_monthly` — monthly trend, filtered by selected truck
- `fct_truck_maintenance` — maintenance event log, filtered by selected truck

**Analytical value:** Pairs operating revenue with maintenance history on a single page, making it possible to evaluate whether a specific truck is a net positive or negative asset. The maintenance log provides the detail needed to identify recurring issues — a truck with frequent brake repairs may need replacement rather than continued maintenance spend.

**Navigation:** Linked from Fleet Utilization ranking table.

---

### 6. Maintenance Analysis

**Path:** `pages/fleet/maintenance.md`  
**Static output:** `build/fleet/maintenance/index.html`  
**Purpose:** Fleet-wide maintenance patterns — cost trends, type breakdown, and age-correlated maintenance burden.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Monthly Cost Trend | Line | maintenance_month | total_cost, total_downtime_hours | fct_truck_maintenance grouped by maintenance_month; dual axis (cost + hours) |
| Cost by Type | Bar | maintenance_type | total_cost | fct_truck_maintenance grouped by maintenance_type; ordered descending |
| Avg Downtime by Type | Bar | maintenance_type | avg_downtime_hours | Same grouping; `AVG(downtime_hours)` per type |
| Maintenance Cost vs Truck Age | Bar | age_years | cost_per_truck | fct_truck_maintenance + dim_trucks; `SUM(total_cost) / COUNT(DISTINCT truck_id)` grouped by age_years |
| Opportunity Cost Trend | Line | maintenance_month | total_opportunity_cost | fct_truck_maintenance grouped by maintenance_month; `SUM(opportunity_cost)` |
| Top Trucks by Spend | DataTable | — | — | fct_truck_maintenance grouped by truck_id + dim_trucks; columns: unit_number, make, model_year, event_count, total_cost, total_downtime_hours; top 20 by total_cost |

**Query sources:**
- `fct_truck_maintenance` — monthly trends, type breakdown, truck rankings
- `fct_truck_maintenance` + `dim_trucks` — age correlation and truck context

**Analytical value:** The age-cost correlation answers whether older trucks are economically viable. Opportunity cost (derived from avg_daily_revenue * downtime) quantifies the revenue impact of each maintenance event beyond the direct repair cost.

---

### 7. Route & Lane Profitability

**Path:** `pages/routes/index.md`  
**Static output:** `build/routes/index.html`  
**Purpose:** Compare lanes and routes on profitability, efficiency, and reliability. Identify the most and least profitable corridors.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Lane Rankings | DataTable | — | — | fct_lanes_summary + dim_lanes; columns: origin_region_name, destination_region_name, lane_type, total_trips, total_revenue, net_revenue_after_fuel_pct, revenue_per_mile, distance_variance_pct, total_detention_minutes; sortable, filterable by lane_type |
| Profitability Scatter | ScatterPlot | revenue_per_mile | net_revenue_after_fuel_pct | Same source; color = lane_type; identifies lanes that are high-rate but low-margin (fuel-heavy) vs the reverse |
| Monthly Revenue by Lane Type | Line | dispatch_month | total_revenue | fct_lane_monthly grouped by dispatch_month + lane_type; separate series per lane_type |
| Monthly Net Margin by Lane Type | Line | dispatch_month | net_revenue_after_fuel_pct | Same source; weighted: `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` per lane_type per month |
| Route Summary | DataTable | — | — | fct_routes_summary; columns: route_id, total_trips, total_revenue, net_revenue_after_fuel_pct, revenue_per_mile, avg_mph, distance_variance_pct |

**Query sources:**
- `fct_lanes_summary` + `dim_lanes` — lane rankings and scatter
- `fct_lane_monthly` — monthly trends by lane type
- `fct_routes_summary` — route-level table

**Analytical value:** The scatter plot surfaces lanes where high per-mile rates don't translate to margins (fuel-intensive long hauls). Lane type segmentation (over_the_road vs local/regional) reveals structural profitability differences. Distance variance % flags routes where actual mileage consistently exceeds plan.

---

### 8. Regional Analysis

**Path:** `pages/routes/regions.md`  
**Static output:** `build/routes/regions/index.html`  
**Purpose:** Geographic view of freight flow — which regions generate the most revenue as origins vs destinations, and which origin-destination pairs dominate.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Region Summary | DataTable | — | — | fct_regions_summary + dim_regions; columns: region_name, total_trips_as_origin, total_trips_as_destination, total_trips, total_revenue, net_revenue_after_fuel_pct, unique_routes, unique_lanes |
| Revenue by Direction | Stacked Bar | region_name | total_revenue_as_origin, total_revenue_as_destination | fct_regions_summary + dim_regions; shows each region's contribution as shipper vs receiver |
| Origin-Destination Matrix | DataTable (pivot) | origin_region | destination_region | fct_route_trips grouped by origin_region_id + destination_region_id, joined to dim_regions x2; cells show trip count and total revenue; sorted by revenue DESC |
| OD Margin Comparison | DataTable (pivot) | origin_region | destination_region | Same grouping; cells show `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` — identifies which corridors have strong/weak margins |
| Monthly Regional Revenue | Line | dispatch_month | total_revenue | fct_lane_monthly grouped by dispatch_month + origin_region_id, joined to dim_regions; top 5 regions as separate series |

**Query sources:**
- `fct_regions_summary` + `dim_regions` — region-level aggregates with directional splits
- `fct_route_trips` + `dim_regions` (x2) — OD matrix at trip grain
- `fct_lane_monthly` + `dim_regions` — monthly regional trends

**Analytical value:** Reveals the geographic structure of the freight network. The OD matrix identifies which corridors carry the most volume and revenue, while the margin comparison highlights corridors where fuel costs disproportionately erode revenue. The directional revenue split shows whether a region is primarily a shipper (origin-heavy) or receiver (destination-heavy), informing where to focus sales and capacity planning.

**Design note:** The regions summary uses UNION ALL of origin_trips (all lane types) + destination_trips (over_the_road only) to avoid double-counting local deliveries where origin and destination share the same region. Two regions (Northwest2, MidAtlantic) have zero trips — no lanes reference them; they will appear as zero rows in the summary.

---

### 9. Customer Analysis

**Path:** `pages/customers/index.md`  
**Static output:** `build/customers/index.html`  
**Purpose:** Customer portfolio view — revenue concentration, service quality, and growth opportunity identification.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Customer Rankings | DataTable | — | — | fct_customers_summary + dim_customers; columns: company_name, customer_type, primary_freight_type, total_loads, total_trips, total_revenue, avg_revenue_per_trip, on_time_delivery_pct, accessorial_pct, revenue_vs_potential_pct; sortable |
| Revenue by Customer Type | Bar | customer_type | total_revenue | Grouped from fct_customers_summary + dim_customers |
| Revenue vs Potential | ScatterPlot | annual_revenue_potential | total_revenue | dim_customers (x) + fct_customers_summary (y); color = customer_type; diagonal line = 100% capture; points below line are growth opportunities |
| Under-Potential Customers | DataTable | — | — | fct_customers_summary + dim_customers WHERE revenue_vs_potential_pct < 0.5; columns: company_name, customer_type, total_revenue, annual_revenue_potential, revenue_vs_potential_pct; ordered by annual_revenue_potential DESC |
| Revenue Concentration | Bar | company_name | total_revenue | fct_customers_summary + dim_customers; all 25 customers; illustrates concentration risk |

**Query sources:**
- `fct_customers_summary` + `dim_customers` — rankings, scatter, under-potential filter
- `dim_customers` — annual_revenue_potential for scatter x-axis

**Analytical value:** The revenue vs potential scatter directly identifies where sales effort should focus. Accessorial % by customer flags accounts generating disproportionate extra charges. Revenue concentration shows dependency risk.

---

### 10. Customer Detail

**Path:** `pages/customers/detail.md`  
**Static output:** `build/customers/detail/index.html`  
**Purpose:** Individual customer deep dive — select by company name via dropdown, view monthly trends, service quality, and comparison to peer group.

**Interaction pattern:** A `<Dropdown>` component at the top of the page lists all customers by company name. All customer data is embedded at build time; the dropdown performs client-side filtering.

```markdown
<Dropdown name=customer_selector data={customer_list} value=customer_id label=company_name title="Select Customer" />
```

The customer list query provides the dropdown options:
```sql
-- customer_list
SELECT cs.customer_id, c.customer_name as company_name
FROM main.fct_customers_summary cs
JOIN main.dim_customers c ON cs.customer_id = c.customer_id
ORDER BY c.customer_name
```

All downstream queries filter via `WHERE customer_id = '${inputs.customer_selector.value}'`.

**KPI Cards:**

| Metric | Source | Derivation |
|---|---|---|
| Total Revenue | fct_customers_summary | total_revenue |
| Total Loads | fct_customers_summary | total_loads |
| On-Time % | fct_customers_summary | on_time_delivery_pct |
| Accessorial % | fct_customers_summary | accessorial_pct |
| Revenue vs Potential | fct_customers_summary | revenue_vs_potential_pct |
| Avg Revenue/Trip | fct_customers_summary | avg_revenue_per_trip |

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Monthly Revenue | Line | dispatch_month | total_revenue | fct_customer_monthly filtered by selected customer |
| Monthly On-Time & Detention | Line | dispatch_month | on_time_delivery_pct, avg_detention_per_trip | Same source; dual axis |
| Monthly Revenue vs Potential | Line | dispatch_month | total_revenue, monthly_potential | revenue_vs_potential_pct context; monthly_potential = annual_revenue_potential / 12 as reference line |
| Peer Comparison | Bar (grouped) | metric | this_customer vs avg | Compares: avg_revenue_per_trip, on_time_delivery_pct, accessorial_pct against fleet-wide averages from fct_customers_summary |

**Query sources:**
- `fct_customers_summary` + `dim_customers` — KPIs, profile, and dropdown options
- `fct_customer_monthly` — monthly trend, filtered by selected customer
- `fct_customers_summary` (unfiltered) — peer averages

**Analytical value:** Enables account managers to review a specific customer's trajectory over time. The revenue vs potential reference line shows whether the relationship is growing toward its ceiling or plateauing. Monthly on-time and detention trends can flag service quality deterioration before it leads to customer churn. The peer comparison highlights where a customer sits relative to the portfolio on key service metrics.

**Navigation:** Linked from Customer Analysis ranking table.

---

### 11. Customer Profitability

**Path:** `pages/customers/profitability.md`  
**Static output:** `build/customers/profitability/index.html`  
**Purpose:** Identify unprofitable or marginally profitable customers to support contract renegotiation decisions. Profitability is measured as net revenue after fuel cost — the carrier's only hard cost available in the data.

**Why this page exists:** fct_customers_summary tracks revenue and service quality but not fuel cost — it is built from fct_customer_trips, which doesn't carry fuel data. To compute customer-level profitability we aggregate from fct_route_trips, which has total_revenue, fuel_cost_total, and net_revenue_after_fuel alongside customer_id.

**KPI Cards:**

| Metric | Source | Derivation |
|---|---|---|
| Fleet Net Margin % | fct_route_trips | `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` — fleet-wide benchmark |
| Customers Below Avg Margin | computed | Count of customers with net_margin_pct < fleet average |
| Lowest Customer Margin % | computed | `MIN(net_margin_pct)` across all customers |
| Renegotiation Candidates | computed | Count of customers with net_margin_pct <= 0.05 |

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Customer Profitability Rankings | DataTable | — | — | fct_route_trips grouped by customer_id + dim_customers; columns: company_name, customer_type, total_trips, total_revenue, total_fuel_cost, net_revenue_after_fuel, net_margin_pct; sorted by net_margin_pct ASC (worst first) |
| Margin Distribution | Bar | company_name | net_margin_pct | All 25 customers; horizontal; color-coded: red <= 5%, green > 5%; reference line at fleet average margin |
| Revenue vs Net Margin | ScatterPlot | total_revenue | net_margin_pct | fct_route_trips grouped by customer_id + dim_customers; color = customer_type; reference line at 5% threshold |
| Monthly Margin Trend | Line | dispatch_month | net_margin_pct | fct_route_trips grouped by customer_id + dispatch_month; top 5 worst-margin customers as separate series; shows whether margins are improving or deteriorating |
| Renegotiation Candidates | DataTable | — | — | Filtered: customers with net_margin_pct <= 0.05; columns: company_name, customer_type, total_trips, total_revenue, total_fuel_cost, net_revenue_after_fuel, net_margin_pct, annual_revenue_potential, revenue_vs_potential_pct; all flagged for contract renegotiation |

**Key derived columns (from fct_route_trips GROUP BY customer_id):**

| Column | Derivation |
|---|---|
| total_revenue | `SUM(total_revenue)` |
| total_fuel_cost | `SUM(fuel_cost_total)` |
| net_revenue_after_fuel | `SUM(net_revenue_after_fuel)` |
| net_margin_pct | `SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)` |

**Query sources:**
- `fct_route_trips` — trip-level grain with customer_id and fuel cost; grouped by customer_id for rankings and margin analysis
- `fct_route_trips` + `dim_customers` — customer context (company_name, customer_type, annual_revenue_potential)
- `fct_customers_summary` — revenue_vs_potential_pct for renegotiation candidates table

**Action logic:**

| Condition | Recommended Action |
|---|---|
| net_margin_pct <= 0.05 | Renegotiate — margin at or below 5% warrants contract review |
| net_margin_pct > 0.05 | No action — margin acceptable |

**Analytical value:** This page answers the direct business question: "Which customers are we making money on?" The margin distribution gives a fleet-wide view of customer profitability. The scatter plot identifies whether low-margin customers are also high-volume (renegotiate) or low-volume (lower priority). The monthly trend shows whether a low-margin customer is getting worse (accelerate renegotiation) or recovering (monitor).

---

### 12. Facility Operations

**Path:** `pages/facilities/index.md`  
**Static output:** `build/facilities/index.html`  
**Purpose:** Facility-level operational quality — detention hotspots, throughput volume, and on-time performance by facility type and region.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Facility Rankings | DataTable | — | — | fct_facilities_summary + dim_facilities; columns: facility_name, facility_type, city, state, region_name, total_events, total_pickups, total_deliveries, on_time_pct, avg_detention_per_event, estimated_detention_cost, revenue_throughput; sortable; default sort by estimated_detention_cost DESC |
| Detention Hotspots | Bar (horizontal) | facility_name | estimated_detention_cost | Top 20 facilities by detention cost; highlights operational bottlenecks |
| Detention by Facility Type | Bar | facility_type | total_detention_cost | fct_facilities_summary + dim_facilities grouped by facility_type |
| On-Time vs Detention Scatter | ScatterPlot | on_time_pct | estimated_detention_cost | fct_facilities_summary + dim_facilities; color = region_name; identifies facilities that are both late and expensive |
| Throughput by Region | Bar | region_name | revenue_throughput | fct_facilities_summary + dim_facilities grouped by region_name |
| Escalation Candidates | DataTable | — | — | Facilities where estimated_detention_cost exceeds threshold; columns: facility_name, facility_type, city, state, region_name, total_events, avg_detention_per_event, estimated_detention_cost, on_time_pct; flagged for complaint escalation through customers that deliver/pickup at the location |

**Query sources:**
- `fct_facilities_summary` + `dim_facilities` — all charts on this page

**Action logic:** Facilities with high detention consume driver hours and tie up assets, creating operational friction across the network. Facilities exceeding the detention cost threshold are flagged for escalation — the recommended action is to escalate complaints through the customers that pick up or deliver at that location, as they hold the commercial relationship to pressure the facility for operational improvements. Identifying the specific customers involved is a separate investigation step performed after a facility is flagged.

**Analytical value:** Detention is an operational metric that affects scheduling, driver utilization, and customer relationships. The scatter plot separates facilities that are merely slow (high detention, reasonable on-time) from those that are both slow and unreliable (high detention, low on-time) — the latter are the highest-priority escalation targets. The facility type and region groupings reveal whether detention is concentrated in specific segments of the network or spread broadly.

**Design note:** fct_facilities_summary uses a two-CTE approach (event_agg + revenue_agg) to prevent fan-out between delivery events and trips. Revenue throughput is deduplicated via `DISTINCT facility_id, trip_id` before joining to fct_route_trips. Detention cost uses the standard formula: `GREATEST(detention_minutes - 120, 0) * 1.25` ($75/hr after 2-hour grace).

---

### 13. Operational Efficiency

**Path:** `pages/operations/index.md`  
**Static output:** `build/operations/index.html`  
**Purpose:** Cross-cutting operational metrics — detention trends, fuel efficiency, safety, and idle time patterns across the fleet.

**Charts:**

| Chart | Type | X | Y | Notes |
|---|---|---|---|---|
| Monthly Detention Trend | Line | dispatch_month | total_detention_minutes, total_estimated_detention_cost | fct_driver_monthly grouped by dispatch_month; dual axis |
| Fleet MPG Trend | Line | dispatch_month | fleet_avg_mpg | fct_driver_trips grouped by dispatch_month; weighted: `SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)` |
| Fleet Idle % Trend | Line | dispatch_month | fleet_idle_pct | fct_driver_trips grouped by dispatch_month; weighted: `SUM(idle_time_hours) / NULLIF(SUM(actual_duration_hours), 0)` |
| Incident Rate by Terminal | Bar | home_terminal | incident_rate | fct_driver_monthly grouped by home_terminal; `SUM(incident_count)::float / NULLIF(SUM(total_trips), 0)` |
| MPG Distribution | Bar | driver_name | avg_mpg | fct_drivers_summary + dim_drivers; all drivers sorted by avg_mpg DESC; histogram-style |
| Top Detention Lanes | DataTable | — | — | fct_lanes_summary + dim_lanes; columns: origin_region_name, destination_region_name, total_trips, total_detention_minutes, total_estimated_detention_cost; top 15 by detention cost |
| Fuel Cost Trend | Line | dispatch_month | total_fuel_cost | fct_driver_monthly grouped by dispatch_month |

**Query sources:**
- `fct_driver_monthly` + `dim_drivers` — detention trend, incident rate by terminal
- `fct_driver_trips` — fleet MPG and idle % trends (trip grain for weighted aggregation)
- `fct_drivers_summary` + `dim_drivers` — MPG distribution
- `fct_lanes_summary` + `dim_lanes` — detention lane hotspots

**Analytical value:** This page provides a single view of the fleet's four key cost levers: detention, fuel, safety incidents, and idle time. Monthly trends reveal whether operational improvements are taking hold. Terminal-level incident rates surface systemic safety issues tied to geography or management.

---

## Data Model Reference

The dashboards consume the following tables from the data mart:

### Fact Tables (trip-level)
| Table | Grain | Row Count | Key Metrics |
|---|---|---|---|
| fct_route_trips | trip | 85,410 | revenue, net_revenue_after_fuel, fuel_cost, detention, distance variance, mph |
| fct_driver_trips | trip | 85,410 | revenue, fuel cost, on-time %, detention, incidents, idle % |
| fct_fleet_trips | trip | 85,410 | revenue, fuel cost, idle %, revenue/mile, fuel cost/mile |
| fct_customer_trips | trip | 85,410 | revenue, on-time %, accessorial %, detention, transit variance |

### Fact Tables (monthly rollups)
| Table | Grain | Key Metrics |
|---|---|---|
| fct_driver_monthly | driver + month | trips, miles, revenue, fuel cost, mpg, idle %, on-time %, incidents |
| fct_lane_monthly | lane + month | trips, revenue, fuel cost, net margin %, revenue/mile, detention |
| fct_fleet_monthly | truck + month | trips, miles, revenue, fuel cost, mpg, maintenance cost, downtime |
| fct_customer_monthly | customer + month | loads, trips, revenue, accessorial %, on-time %, detention, revenue vs potential |

### Fact Tables (lifetime summaries)
| Table | Grain | Key Metrics |
|---|---|---|
| fct_drivers_summary | driver | trips, miles, revenue, fuel cost, mpg, on-time %, incidents, revenue/mile |
| fct_trucks_summary | truck | trips, miles, revenue, fuel cost, mpg, days in service, avg daily revenue |
| fct_trailers_summary | trailer | trips, miles, revenue, weight, revenue/mile |
| fct_customers_summary | customer | loads, trips, revenue, on-time %, accessorial %, detention, revenue vs potential |
| fct_routes_summary | route | trips, revenue, fuel cost, net margin %, revenue/mile, mph, distance variance |
| fct_lanes_summary | lane | trips, revenue, fuel cost, net margin %, revenue/mile, mph, distance variance |
| fct_regions_summary | region | trips (as origin/destination), revenue (as origin/destination), detention, routes, lanes |
| fct_facilities_summary | facility | events, pickups, deliveries, on-time %, detention, revenue throughput |

### Other
| Table | Grain | Key Metrics |
|---|---|---|
| fct_truck_maintenance | maintenance event | cost, downtime, opportunity cost, type, odometer |

### Dimension Tables
| Table | Key Attributes |
|---|---|
| dim_drivers | name, hire_date, home_terminal, cdl_class, years_experience, age, tenure_years |
| dim_trucks | unit_number, make, model_year, fuel_type, home_terminal, age_years, status |
| dim_trailers | trailer_number, trailer_type, length_feet, model_year, age_years, status |
| dim_customers | customer_name, customer_type, primary_freight_type, annual_revenue_potential, contract_tenure_years |
| dim_facilities | facility_name, facility_type, city, state, region_name, dock_doors, operating_hours_start, operating_hours_end |
| dim_routes | lane_id, origin/destination city+state+region, typical_distance_miles, base_rate_per_mile |
| dim_lanes | lane_type, origin/destination region_name |
| dim_regions | region_name, centroid_latitude, centroid_longitude |

---

## Key Design Decisions

1. **Weighted averages, not averages of averages.** All ratio metrics (MPG, idle %, on-time %, margin %) are recomputed as SUM/SUM at each aggregation level, never averaged from pre-computed ratios. This prevents distortion from unequal group sizes.

2. **Detention cost formula.** `GREATEST(detention_minutes - 120, 0) * 1.25` consistently applied — $75/hour after a 2-hour grace period. Pre-computed in trip-level fact tables; summaries use `SUM(estimated_detention_cost)`.

3. **Revenue metric: net_revenue_after_fuel.** Defined as `total_revenue - fuel_cost_total`. This is the closest available proxy for gross margin; the data does not include driver labor cost.

4. **Lane as profitability grain.** 58 routes map to 49 unique lanes. Lane-level analysis avoids overfitting to route-specific variation and provides a more actionable corridor-level view.

5. **Region directional counting.** fct_regions_summary uses UNION ALL with a `lane_type = 'over_the_road'` filter on destination trips to prevent double-counting local deliveries where origin and destination share the same region.

6. **Facility fan-out prevention.** fct_facilities_summary uses two CTEs (event_agg + revenue_agg) with `DISTINCT facility_id, trip_id` deduplication to prevent revenue inflation from multiple delivery events per trip at the same facility.

7. **Dropdown-driven detail pages, not parameterized pages.** Detail pages for drivers, trucks, and customers use a single page with a `<Dropdown>` selector (by name/unit number, never by ID). All entity data is embedded at build time; the dropdown filters client-side. This avoids exposing internal IDs to end users, produces only 13 HTML files instead of ~188, and provides instant switching between entities without page navigation.

8. **NULL groups acknowledged.** 1 NULL driver_id (1,714 trips), 1 NULL trailer_id (1,680 trips), 28 trucks with zero trips. These appear in aggregates and are not excluded — dashboards should display them as-is for completeness.

9. **Customer profitability from fct_route_trips, not fct_customer_trips.** fct_customer_trips does not carry fuel cost — it was designed for service quality analysis. For profitability analysis we aggregate from fct_route_trips, which has both fuel_cost_total and customer_id on every row. Profitability is measured as net_revenue_after_fuel (revenue minus fuel cost) — the carrier's only hard cost in the data. Detention is excluded from profitability calculations because it is a pass-through cost billed to the customer, not a direct carrier expense. While detention has indirect opportunity costs (driver hours, asset utilization), these are not quantifiable from the available data.

10. **Renegotiation threshold at 5% net margin.** Customers with net_margin_pct <= 0.05 are flagged for contract renegotiation. The dashboard does not recommend dropping customers — that decision follows after a renegotiation attempt.
