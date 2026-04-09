---
title: Fleet Utilization
---

```sql truck_rankings
select
    ts.truck_id,
    ts.unit_number,
    ts.make,
    ts.model_year,
    dt.age_years,
    ts.total_trips,
    ts.total_revenue,
    ts.total_miles,
    ts.avg_mpg,
    ts.avg_daily_revenue
from logistics.fct_trucks_summary ts
join logistics.dim_trucks dt on ts.truck_id = dt.truck_id
order by ts.total_revenue desc
```

```sql make_analysis
select
    ts.make,
    count(*)                                                    as trucks,
    sum(ts.total_trips)                                         as total_trips,
    sum(ts.total_revenue)                                       as total_revenue,
    sum(ts.total_miles)                                         as total_miles
from logistics.fct_trucks_summary ts
group by ts.make
order by total_revenue desc
```

```sql age_mpg
select
    dt.age_years,
    avg(ts.avg_mpg)                                             as avg_mpg,
    count(*)                                                    as truck_count
from logistics.fct_trucks_summary ts
join logistics.dim_trucks dt on ts.truck_id = dt.truck_id
where ts.total_trips > 0
group by dt.age_years
order by dt.age_years
```

```sql trailer_rankings
select
    trs.trailer_id,
    dt.trailer_number,
    dt.trailer_type,
    dt.length_feet,
    trs.total_trips,
    trs.total_revenue,
    trs.total_weight_lbs,
    trs.revenue_per_mile
from logistics.fct_trailers_summary trs
join logistics.dim_trailers dt on trs.trailer_id = dt.trailer_id
order by trs.total_revenue desc
```

```sql trailer_type_revenue
select
    dt.trailer_type,
    sum(trs.total_revenue)                                      as total_revenue,
    sum(trs.total_trips)                                        as total_trips
from logistics.fct_trailers_summary trs
join logistics.dim_trailers dt on trs.trailer_id = dt.trailer_id
group by dt.trailer_type
order by total_revenue desc
```

## Truck Rankings

<DataTable data={truck_rankings} search=true>
    <Column id=unit_number title="Unit #" />
    <Column id=make title="Make" />
    <Column id=model_year title="Year" />
    <Column id=age_years title="Age" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=total_miles title="Miles" fmt=num0 />
    <Column id=avg_mpg title="MPG" fmt=num1 />
    <Column id=avg_daily_revenue title="Daily Rev" fmt=usd0 />
</DataTable>

## Revenue by Make

<BarChart
    data={make_analysis}
    x=make
    y=total_revenue
    yFmt=usd0
    title="Total Revenue by Truck Make"
/>

## MPG by Truck Age

<ScatterPlot
    data={age_mpg}
    x=age_years
    y=avg_mpg
    size=truck_count
    xAxisTitle="Truck Age (years)"
    yAxisTitle="Avg MPG"
    title="Fuel Efficiency vs Truck Age"
/>

## Trailer Utilization

<DataTable data={trailer_rankings} search=true>
    <Column id=trailer_number title="Trailer #" />
    <Column id=trailer_type title="Type" />
    <Column id=length_feet title="Length (ft)" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=total_weight_lbs title="Weight (lbs)" fmt=num0 />
    <Column id=revenue_per_mile title="Rev/Mile" fmt=usd2 />
</DataTable>

## Revenue by Trailer Type

<BarChart
    data={trailer_type_revenue}
    x=trailer_type
    y=total_revenue
    yFmt=usd0
    title="Total Revenue by Trailer Type"
/>
