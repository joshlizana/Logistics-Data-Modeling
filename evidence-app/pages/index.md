---
title: Executive Summary
---

```sql kpi_summary
select
    count(*)                                                        as total_trips,
    count(distinct route_id)                                        as unique_routes,
    count(distinct lane_id)                                         as unique_lanes,
    sum(total_revenue)                                              as total_revenue,
    sum(net_revenue_after_fuel)                                     as total_net_revenue,
    sum(net_revenue_after_fuel) / nullif(sum(total_revenue), 0)     as net_margin_pct,
    sum(estimated_detention_cost)                                   as total_detention_cost
from logistics.fct_route_trips
```

<BigValue data={kpi_summary} value=total_trips title="Total Trips" />
<BigValue data={kpi_summary} value=total_revenue title="Total Revenue" fmt=usd0 />
<BigValue data={kpi_summary} value=net_margin_pct title="Net Margin %" fmt=pct1 />
<BigValue data={kpi_summary} value=total_detention_cost title="Total Detention Cost" fmt=usd0 />
<BigValue data={kpi_summary} value=unique_routes title="Unique Routes" />
<BigValue data={kpi_summary} value=unique_lanes title="Unique Lanes" />

```sql monthly_revenue
select
    dispatch_month,
    sum(total_revenue)              as total_revenue,
    sum(net_revenue_after_fuel)     as net_revenue_after_fuel
from logistics.fct_route_trips
group by dispatch_month
order by dispatch_month
```

```sql region_revenue
select
    r.region_name,
    rs.total_revenue,
    rs.total_trips,
    rs.unique_lanes
from logistics.fct_regions_summary rs
join logistics.dim_regions r on rs.region_id = r.region_id
order by rs.total_revenue desc
```

```sql top_lanes
select
    l.origin_region_name,
    l.destination_region_name,
    l.lane_type,
    ls.total_trips,
    ls.total_revenue,
    ls.net_revenue_after_fuel_pct
from logistics.fct_lanes_summary ls
join logistics.dim_lanes l on ls.lane_id = l.lane_id
order by ls.total_revenue desc
limit 10
```

## Revenue Trend

<LineChart
    data={monthly_revenue}
    x=dispatch_month
    y={["total_revenue", "net_revenue_after_fuel"]}
    yFmt=usd0
    title="Monthly Revenue & Net Revenue After Fuel"
/>

## Revenue by Region

<BarChart
    data={region_revenue}
    x=region_name
    y=total_revenue
    yFmt=usd0
    swapXY=true
    title="Total Revenue by Region"
    sort=false
/>

## Top 10 Lanes by Revenue

<DataTable data={top_lanes} rows=10>
    <Column id=origin_region_name title="Origin Region" />
    <Column id=destination_region_name title="Destination Region" />
    <Column id=lane_type title="Lane Type" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=net_revenue_after_fuel_pct title="Net Margin %" fmt=pct1 />
</DataTable>

## Navigation

**Drivers**
- [Driver Performance](/drivers) — Compare all drivers on revenue, efficiency, safety, and on-time delivery
- [Driver Detail](/drivers/detail) — Deep dive on a single driver with monthly trends and peer comparison

**Fleet**
- [Fleet Utilization](/fleet) — Truck and trailer asset performance by make, age, and type
- [Truck Detail](/fleet/detail) — Individual truck revenue, fuel cost, and maintenance history
- [Maintenance Analysis](/fleet/maintenance) — Fleet-wide maintenance cost trends, type breakdown, and age correlation

**Routes**
- [Route & Lane Profitability](/routes) — Lane and route margin analysis across corridors
- [Regional Analysis](/routes/regions) — Origin-destination freight flow and regional revenue splits

**Customers**
- [Customer Analysis](/customers) — Revenue concentration, service quality, and growth opportunities
- [Customer Detail](/customers/detail) — Individual customer monthly trends and peer comparison
- [Customer Profitability](/customers/profitability) — Per-customer margin analysis and renegotiation flags

**Operations**
- [Facility Operations](/facilities) — Detention hotspots, on-time performance, and escalation candidates
- [Operational Efficiency](/operations) — Fleet-wide detention, fuel, safety, and idle trends
