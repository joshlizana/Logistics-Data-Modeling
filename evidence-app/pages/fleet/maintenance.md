---
title: Maintenance Analysis
---

```sql monthly_cost
select
    maintenance_month,
    count(*)                        as events,
    sum(total_cost)                 as total_cost,
    sum(downtime_hours)             as total_downtime_hours,
    sum(opportunity_cost)           as total_opportunity_cost
from logistics.fct_truck_maintenance
group by maintenance_month
order by maintenance_month
```

```sql cost_by_type
select
    maintenance_type,
    count(*)                        as events,
    sum(total_cost)                 as total_cost,
    avg(downtime_hours)             as avg_downtime_hours
from logistics.fct_truck_maintenance
group by maintenance_type
order by total_cost desc
```

```sql age_maintenance
select
    dt.age_years,
    count(*)                                            as events,
    sum(m.total_cost)                                   as total_cost,
    sum(m.total_cost) / count(distinct m.truck_id)      as cost_per_truck
from logistics.fct_truck_maintenance m
join logistics.dim_trucks dt on m.truck_id = dt.truck_id
group by dt.age_years
order by dt.age_years
```

```sql top_trucks_by_spend
select
    m.unit_number,
    m.make,
    m.model_year,
    count(*)                        as event_count,
    sum(m.total_cost)               as total_cost,
    sum(m.downtime_hours)           as total_downtime_hours
from logistics.fct_truck_maintenance m
group by m.truck_id, m.unit_number, m.make, m.model_year
order by total_cost desc
limit 20
```

## Monthly Cost & Downtime Trend

<LineChart
    data={monthly_cost}
    x=maintenance_month
    y=total_cost
    y2=total_downtime_hours
    yFmt=usd0
    y2Fmt=num0
    title="Monthly Maintenance Cost & Downtime Hours"
/>

## Cost by Maintenance Type

<BarChart
    data={cost_by_type}
    x=maintenance_type
    y=total_cost
    yFmt=usd0
    title="Total Cost by Maintenance Type"
/>

## Avg Downtime by Maintenance Type

<BarChart
    data={cost_by_type}
    x=maintenance_type
    y=avg_downtime_hours
    yFmt=num1
    title="Average Downtime Hours by Maintenance Type"
/>

## Maintenance Cost vs Truck Age

<BarChart
    data={age_maintenance}
    x=age_years
    y=cost_per_truck
    yFmt=usd0
    xAxisTitle="Truck Age (years)"
    title="Maintenance Cost per Truck by Age"
/>

## Opportunity Cost Trend

<LineChart
    data={monthly_cost}
    x=maintenance_month
    y=total_opportunity_cost
    yFmt=usd0
    title="Monthly Opportunity Cost from Downtime"
/>

## Top 20 Trucks by Maintenance Spend

<DataTable data={top_trucks_by_spend} rows=20>
    <Column id=unit_number title="Unit #" />
    <Column id=make title="Make" />
    <Column id=model_year title="Year" />
    <Column id=event_count title="Events" />
    <Column id=total_cost title="Total Cost" fmt=usd0 />
    <Column id=total_downtime_hours title="Downtime (hrs)" fmt=num1 />
</DataTable>
