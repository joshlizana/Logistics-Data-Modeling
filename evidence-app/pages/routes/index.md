---
title: Route & Lane Profitability
---

```sql lane_rankings
select
    ls.lane_id,
    l.origin_region_name,
    l.destination_region_name,
    l.lane_type,
    ls.total_trips,
    ls.total_revenue,
    ls.net_revenue_after_fuel_pct,
    ls.revenue_per_mile,
    ls.distance_variance_pct,
    ls.total_detention_minutes
from logistics.fct_lanes_summary ls
join logistics.dim_lanes l on ls.lane_id = l.lane_id
order by ls.total_revenue desc
```

```sql lane_monthly
select
    dispatch_month,
    lane_type,
    sum(total_revenue)                                                      as total_revenue,
    sum(total_net_revenue_after_fuel)                                        as net_revenue_after_fuel,
    sum(total_net_revenue_after_fuel) / nullif(sum(total_revenue), 0)        as net_revenue_after_fuel_pct,
    sum(trip_count)                                                         as trips
from logistics.fct_lane_monthly
group by dispatch_month, lane_type
order by dispatch_month
```

```sql route_summary
select
    route_id,
    total_trips,
    total_revenue,
    net_revenue_after_fuel_pct,
    revenue_per_mile,
    avg_mph,
    distance_variance_pct
from logistics.fct_routes_summary
order by total_revenue desc
```

## Lane Rankings

<DataTable data={lane_rankings} search=true>
    <Column id=origin_region_name title="Origin Region" />
    <Column id=destination_region_name title="Dest Region" />
    <Column id=lane_type title="Lane Type" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=net_revenue_after_fuel_pct title="Net Margin %" fmt=pct1 />
    <Column id=revenue_per_mile title="Rev/Mile" fmt=usd2 />
    <Column id=distance_variance_pct title="Dist Variance %" fmt=pct1 />
    <Column id=total_detention_minutes title="Detention (min)" fmt=num0 />
</DataTable>

## Profitability Scatter

<ScatterPlot
    data={lane_rankings}
    x=revenue_per_mile
    y=net_revenue_after_fuel_pct
    xFmt=usd2
    yFmt=pct1
    series=lane_type
    title="Revenue per Mile vs Net Margin %"
    xAxisTitle="Revenue per Mile"
    yAxisTitle="Net Margin %"
/>

## Monthly Revenue by Lane Type

<LineChart
    data={lane_monthly}
    x=dispatch_month
    y=total_revenue
    series=lane_type
    yFmt=usd0
    title="Monthly Revenue by Lane Type"
/>

## Monthly Net Margin by Lane Type

<LineChart
    data={lane_monthly}
    x=dispatch_month
    y=net_revenue_after_fuel_pct
    series=lane_type
    yFmt=pct1
    title="Monthly Net Margin % by Lane Type"
/>

## Route Summary

<DataTable data={route_summary} search=true>
    <Column id=route_id title="Route ID" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=net_revenue_after_fuel_pct title="Net Margin %" fmt=pct1 />
    <Column id=revenue_per_mile title="Rev/Mile" fmt=usd2 />
    <Column id=avg_mph title="Avg MPH" fmt=num1 />
    <Column id=distance_variance_pct title="Dist Variance %" fmt=pct1 />
</DataTable>
