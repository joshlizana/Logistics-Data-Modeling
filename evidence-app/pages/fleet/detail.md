---
title: Truck Detail
---

```sql truck_list
select
    ts.truck_id,
    ts.unit_number || ' - ' || ts.make || ' ' || ts.model_year     as truck_label
from logistics.fct_trucks_summary ts
order by ts.unit_number
```

<Dropdown name=truck_selector data={truck_list} value=truck_id label=truck_label title="Select Truck" />

```sql truck_summary
select
    ts.*,
    dt.age_years
from logistics.fct_trucks_summary ts
join logistics.dim_trucks dt on ts.truck_id = dt.truck_id
where ts.truck_id = '${inputs.truck_selector.value}'
```

```sql truck_monthly
select *
from logistics.fct_fleet_monthly
where truck_id = '${inputs.truck_selector.value}'
order by month
```

```sql maintenance_log
select
    maintenance_date,
    maintenance_type,
    service_description,
    total_cost,
    downtime_hours,
    opportunity_cost
from logistics.fct_truck_maintenance
where truck_id = '${inputs.truck_selector.value}'
order by maintenance_date desc
```

<BigValue data={truck_summary} value=total_revenue title="Total Revenue" fmt=usd0 />
<BigValue data={truck_summary} value=total_miles title="Total Miles" fmt=num0 />
<BigValue data={truck_summary} value=avg_mpg title="Avg MPG" fmt=num1 />
<BigValue data={truck_summary} value=days_in_service title="Days in Service" />
<BigValue data={truck_summary} value=avg_daily_revenue title="Avg Daily Revenue" fmt=usd0 />

## Monthly Revenue & Cost

<LineChart
    data={truck_monthly}
    x=month
    y={["total_revenue", "total_fuel_cost", "total_maintenance_cost"]}
    yFmt=usd0
    title="Monthly Revenue vs Operating Costs"
/>

## Monthly Operating Cost Breakdown

<BarChart
    data={truck_monthly}
    x=month
    y={["total_fuel_cost", "total_maintenance_cost"]}
    type=stacked
    yFmt=usd0
    title="Monthly Operating Cost (Fuel + Maintenance)"
/>

## Maintenance Log

<DataTable data={maintenance_log}>
    <Column id=maintenance_date title="Date" />
    <Column id=maintenance_type title="Type" />
    <Column id=service_description title="Description" />
    <Column id=total_cost title="Cost" fmt=usd0 />
    <Column id=downtime_hours title="Downtime (hrs)" fmt=num1 />
    <Column id=opportunity_cost title="Opportunity Cost" fmt=usd0 />
</DataTable>
