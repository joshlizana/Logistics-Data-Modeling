---
title: Operational Efficiency
---

```sql monthly_detention
select
    dispatch_month,
    sum(total_detention_minutes)                as total_detention_minutes,
    sum(total_estimated_detention_cost)          as total_estimated_detention_cost,
    sum(total_fuel_cost)                        as total_fuel_cost
from logistics.fct_driver_monthly
group by dispatch_month
order by dispatch_month
```

```sql fleet_mpg_trend
select
    dispatch_month,
    sum(actual_distance_miles) / nullif(sum(fuel_gallons_used), 0)       as fleet_avg_mpg
from logistics.fct_driver_trips
group by dispatch_month
order by dispatch_month
```

```sql fleet_idle_trend
select
    dispatch_month,
    sum(idle_time_hours) / nullif(sum(actual_duration_hours), 0)         as fleet_idle_pct
from logistics.fct_driver_trips
group by dispatch_month
order by dispatch_month
```

```sql incident_by_terminal
select
    home_terminal,
    sum(incident_count)                                                 as total_incidents,
    sum(total_trips)                                                    as total_trips,
    sum(incident_count)::float / nullif(sum(total_trips), 0)            as incident_rate
from logistics.fct_driver_monthly
group by home_terminal
order by incident_rate desc
```

```sql mpg_distribution
select
    d.driver_full_name                  as driver_name,
    ds.avg_mpg,
    ds.total_miles,
    ds.total_fuel_cost
from logistics.fct_drivers_summary ds
join logistics.dim_drivers d on ds.driver_id = d.driver_id
where ds.avg_mpg is not null
order by ds.avg_mpg desc
```

```sql top_detention_lanes
select
    l.origin_region_name,
    l.destination_region_name,
    ls.total_trips,
    ls.total_detention_minutes,
    ls.total_estimated_detention_cost
from logistics.fct_lanes_summary ls
join logistics.dim_lanes l on ls.lane_id = l.lane_id
order by ls.total_estimated_detention_cost desc
limit 15
```

## Monthly Detention Trend

<LineChart
    data={monthly_detention}
    x=dispatch_month
    y=total_estimated_detention_cost
    y2=total_detention_minutes
    yFmt=usd0
    y2Fmt=num0
    title="Monthly Detention Cost & Minutes"
/>

## Fleet MPG Trend

<LineChart
    data={fleet_mpg_trend}
    x=dispatch_month
    y=fleet_avg_mpg
    yFmt=num1
    title="Fleet Average MPG (Weighted)"
/>

## Fleet Idle % Trend

<LineChart
    data={fleet_idle_trend}
    x=dispatch_month
    y=fleet_idle_pct
    yFmt=pct1
    title="Fleet Idle % (Weighted)"
/>

## Incident Rate by Terminal

<BarChart
    data={incident_by_terminal}
    x=home_terminal
    y=incident_rate
    yFmt=pct2
    title="Incident Rate by Home Terminal"
/>

## MPG Distribution by Driver

<BarChart
    data={mpg_distribution}
    x=driver_name
    y=avg_mpg
    yFmt=num1
    swapXY=true
    sort=false
    title="Average MPG by Driver"
/>

## Fuel Cost Trend

<LineChart
    data={monthly_detention}
    x=dispatch_month
    y=total_fuel_cost
    yFmt=usd0
    title="Monthly Fleet Fuel Cost"
/>

## Top 15 Detention Lanes

<DataTable data={top_detention_lanes} rows=15>
    <Column id=origin_region_name title="Origin Region" />
    <Column id=destination_region_name title="Dest Region" />
    <Column id=total_trips title="Trips" />
    <Column id=total_detention_minutes title="Detention (min)" fmt=num0 />
    <Column id=total_estimated_detention_cost title="Detention Cost" fmt=usd0 />
</DataTable>
