---
title: Regional Analysis
---

```sql region_summary
select
    r.region_name,
    rs.total_trips_as_origin,
    rs.total_trips_as_destination,
    rs.total_trips,
    rs.total_revenue,
    rs.total_revenue_as_origin,
    rs.total_revenue_as_destination,
    rs.net_revenue_after_fuel_pct,
    rs.unique_routes,
    rs.unique_lanes
from logistics.fct_regions_summary rs
join logistics.dim_regions r on rs.region_id = r.region_id
order by rs.total_revenue desc
```

```sql od_matrix
select
    ro.region_name                                                      as origin_region,
    rd.region_name                                                      as dest_region,
    count(*)                                                            as trips,
    sum(rt.total_revenue)                                               as revenue,
    sum(rt.net_revenue_after_fuel) / nullif(sum(rt.total_revenue), 0)   as margin_pct
from logistics.fct_route_trips rt
join logistics.dim_regions ro on rt.origin_region_id = ro.region_id
join logistics.dim_regions rd on rt.destination_region_id = rd.region_id
group by ro.region_name, rd.region_name
order by revenue desc
```

```sql od_margins
select
    ro.region_name                                                      as origin_region,
    rd.region_name                                                      as dest_region,
    count(*)                                                            as trips,
    sum(rt.net_revenue_after_fuel) / nullif(sum(rt.total_revenue), 0)   as margin_pct
from logistics.fct_route_trips rt
join logistics.dim_regions ro on rt.origin_region_id = ro.region_id
join logistics.dim_regions rd on rt.destination_region_id = rd.region_id
group by ro.region_name, rd.region_name
order by margin_pct asc
```

```sql region_monthly
select
    dispatch_month,
    r.region_name,
    sum(total_revenue)              as total_revenue
from logistics.fct_lane_monthly lm
join logistics.dim_regions r on lm.origin_region_id = r.region_id
group by dispatch_month, r.region_name
order by dispatch_month
```

## Region Summary

<DataTable data={region_summary} search=true>
    <Column id=region_name title="Region" />
    <Column id=total_trips_as_origin title="Trips (Origin)" />
    <Column id=total_trips_as_destination title="Trips (Dest)" />
    <Column id=total_trips title="Total Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=net_revenue_after_fuel_pct title="Net Margin %" fmt=pct1 />
    <Column id=unique_routes title="Routes" />
    <Column id=unique_lanes title="Lanes" />
</DataTable>

## Revenue by Direction

<BarChart
    data={region_summary}
    x=region_name
    y={["total_revenue_as_origin", "total_revenue_as_destination"]}
    type=stacked
    yFmt=usd0
    swapXY=true
    sort=false
    title="Revenue by Region (Origin vs Destination)"
/>

## Origin-Destination Matrix (Revenue)

<DataTable data={od_matrix} rows=all>
    <Column id=origin_region title="Origin" />
    <Column id=dest_region title="Destination" />
    <Column id=trips title="Trips" />
    <Column id=revenue title="Revenue" fmt=usd0 />
    <Column id=margin_pct title="Margin %" fmt=pct1 />
</DataTable>

## Origin-Destination Margin Comparison

<DataTable data={od_margins} rows=all>
    <Column id=origin_region title="Origin" />
    <Column id=dest_region title="Destination" />
    <Column id=trips title="Trips" />
    <Column id=margin_pct title="Margin %" fmt=pct1 />
</DataTable>

## Monthly Revenue by Region (Top 5)

<LineChart
    data={region_monthly}
    x=dispatch_month
    y=total_revenue
    series=region_name
    yFmt=usd0
    title="Monthly Revenue by Origin Region"
/>
