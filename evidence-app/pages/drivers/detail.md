---
title: Driver Detail
---

```sql driver_list
select
    ds.driver_id,
    d.driver_full_name                  as driver_name
from logistics.fct_drivers_summary ds
join logistics.dim_drivers d on ds.driver_id = d.driver_id
order by d.driver_full_name
```

<Dropdown name=driver_selector data={driver_list} value=driver_id label=driver_name title="Select Driver" />

```sql driver_summary
select
    ds.*,
    d.driver_full_name                  as driver_name,
    d.home_terminal,
    d.hire_date,
    d.cdl_class,
    d.years_experience,
    d.tenure_years
from logistics.fct_drivers_summary ds
join logistics.dim_drivers d on ds.driver_id = d.driver_id
where ds.driver_id = '${inputs.driver_selector.value}'
```

```sql driver_monthly
select *
from logistics.fct_driver_monthly
where driver_id = '${inputs.driver_selector.value}'
order by dispatch_month
```

```sql fleet_averages
select
    avg(total_revenue)          as avg_revenue,
    avg(revenue_per_mile)       as avg_revenue_per_mile,
    avg(on_time_delivery_pct)   as avg_on_time_pct,
    avg(avg_mpg)                as avg_mpg
from logistics.fct_drivers_summary
```

```sql peer_comparison
select 'This Driver' as label, revenue_per_mile, on_time_delivery_pct, avg_mpg
from logistics.fct_drivers_summary
where driver_id = '${inputs.driver_selector.value}'
union all
select 'Fleet Average', avg(revenue_per_mile), avg(on_time_delivery_pct), avg(avg_mpg)
from logistics.fct_drivers_summary
```

<BigValue data={driver_summary} value=total_revenue title="Total Revenue" fmt=usd0 />
<BigValue data={driver_summary} value=total_trips title="Total Trips" />
<BigValue data={driver_summary} value=on_time_delivery_pct title="On-Time %" fmt=pct1 />
<BigValue data={driver_summary} value=avg_mpg title="Avg MPG" fmt=num1 />
<BigValue data={driver_summary} value=incident_count title="Incidents" />
<BigValue data={driver_summary} value=revenue_per_mile title="Revenue/Mile" fmt=usd2 />

## Monthly Performance

<LineChart
    data={driver_monthly}
    x=dispatch_month
    y={["total_revenue", "total_miles"]}
    y2=total_miles
    yFmt=usd0
    y2Fmt=num0
    title="Monthly Revenue & Miles"
/>

## Monthly MPG & Idle %

<LineChart
    data={driver_monthly}
    x=dispatch_month
    y=avg_mpg
    y2=avg_idle_pct
    yFmt=num1
    y2Fmt=pct1
    title="Monthly MPG & Idle %"
/>

## Peer Comparison

<BarChart
    data={peer_comparison}
    x=label
    y={["revenue_per_mile", "on_time_delivery_pct", "avg_mpg"]}
    type=grouped
    title="This Driver vs Fleet Average"
/>
