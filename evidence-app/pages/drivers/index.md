---
title: Driver Performance
---

```sql driver_rankings
select
    ds.driver_id,
    d.driver_full_name                                                      as driver_name,
    d.home_terminal,
    ds.total_trips,
    ds.total_revenue,
    ds.total_miles,
    ds.revenue_per_mile,
    ds.on_time_delivery_pct,
    ds.incident_count,
    ds.avg_mpg
from logistics.fct_drivers_summary ds
join logistics.dim_drivers d on ds.driver_id = d.driver_id
order by ds.total_revenue desc
```

```sql terminal_comparison
select
    d.home_terminal,
    count(*)                                                                as drivers,
    sum(ds.total_trips)                                                     as total_trips,
    sum(ds.total_revenue)                                                   as total_revenue,
    sum(ds.total_miles)                                                     as total_miles,
    sum(ds.total_revenue) / nullif(sum(ds.total_miles), 0)                  as revenue_per_mile
from logistics.fct_drivers_summary ds
join logistics.dim_drivers d on ds.driver_id = d.driver_id
group by d.home_terminal
order by total_revenue desc
```

```sql monthly_trend
select
    dispatch_month,
    count(distinct driver_id)                                               as active_drivers,
    sum(total_revenue)                                                      as total_revenue,
    sum(actual_distance_miles)                                              as total_miles,
    sum(deliveries_on_time)::float / nullif(sum(total_deliveries), 0)       as on_time_delivery_pct
from logistics.fct_driver_trips
group by dispatch_month
order by dispatch_month
```

## Driver Rankings

<DataTable data={driver_rankings} search=true>
    <Column id=driver_name title="Driver" />
    <Column id=home_terminal title="Terminal" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=revenue_per_mile title="Rev/Mile" fmt=usd2 />
    <Column id=on_time_delivery_pct title="On-Time %" fmt=pct1 />
    <Column id=incident_count title="Incidents" />
    <Column id=avg_mpg title="Avg MPG" fmt=num1 />
</DataTable>

## Efficiency vs Reliability

<ScatterPlot
    data={driver_rankings}
    x=revenue_per_mile
    y=on_time_delivery_pct
    xFmt=usd2
    yFmt=pct1
    size=total_trips
    series=home_terminal
    title="Revenue per Mile vs On-Time Delivery %"
    tooltipColumns={["driver_name"]}
/>

## Revenue by Terminal

<BarChart
    data={terminal_comparison}
    x=home_terminal
    y=total_revenue
    yFmt=usd0
    title="Total Revenue by Home Terminal"
/>

## Monthly Trends

<LineChart
    data={monthly_trend}
    x=dispatch_month
    y=on_time_delivery_pct
    yFmt=pct1
    title="Fleet-Wide On-Time Delivery %"
/>

<LineChart
    data={monthly_trend}
    x=dispatch_month
    y=active_drivers
    title="Active Driver Count by Month"
/>
