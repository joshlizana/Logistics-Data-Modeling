---
title: Facility Operations
---

```sql facility_rankings
select
    fs.facility_id,
    f.facility_name,
    f.facility_type,
    f.city,
    f.state,
    f.region_name,
    fs.total_events,
    fs.total_pickups,
    fs.total_deliveries,
    fs.on_time_pct,
    fs.avg_detention_per_event,
    fs.estimated_detention_cost,
    fs.revenue_throughput
from logistics.fct_facilities_summary fs
join logistics.dim_facilities f on fs.facility_id = f.facility_id
order by fs.estimated_detention_cost desc
```

```sql detention_hotspots
select
    f.facility_name,
    fs.estimated_detention_cost
from logistics.fct_facilities_summary fs
join logistics.dim_facilities f on fs.facility_id = f.facility_id
order by fs.estimated_detention_cost desc
limit 20
```

```sql detention_by_type
select
    f.facility_type,
    sum(fs.estimated_detention_cost)        as total_detention_cost,
    sum(fs.total_events)                    as total_events
from logistics.fct_facilities_summary fs
join logistics.dim_facilities f on fs.facility_id = f.facility_id
group by f.facility_type
order by total_detention_cost desc
```

```sql throughput_by_region
select
    f.region_name,
    sum(fs.revenue_throughput)              as revenue_throughput,
    count(*)                                as facilities
from logistics.fct_facilities_summary fs
join logistics.dim_facilities f on fs.facility_id = f.facility_id
group by f.region_name
order by revenue_throughput desc
```

```sql escalation_candidates
select
    f.facility_name,
    f.facility_type,
    f.city,
    f.state,
    f.region_name,
    fs.total_events,
    fs.avg_detention_per_event,
    fs.estimated_detention_cost,
    fs.on_time_pct
from logistics.fct_facilities_summary fs
join logistics.dim_facilities f on fs.facility_id = f.facility_id
where fs.estimated_detention_cost > 0
order by fs.estimated_detention_cost desc
limit 20
```

## Facility Rankings

<DataTable data={facility_rankings} search=true>
    <Column id=facility_name title="Facility" />
    <Column id=facility_type title="Type" />
    <Column id=city title="City" />
    <Column id=state title="State" />
    <Column id=region_name title="Region" />
    <Column id=total_events title="Events" />
    <Column id=total_pickups title="Pickups" />
    <Column id=total_deliveries title="Deliveries" />
    <Column id=on_time_pct title="On-Time %" fmt=pct1 />
    <Column id=avg_detention_per_event title="Avg Detention (min)" fmt=num0 />
    <Column id=estimated_detention_cost title="Detention Cost" fmt=usd0 />
    <Column id=revenue_throughput title="Revenue Throughput" fmt=usd0 />
</DataTable>

## Top 20 Detention Hotspots

<BarChart
    data={detention_hotspots}
    x=facility_name
    y=estimated_detention_cost
    yFmt=usd0
    swapXY=true
    sort=false
    title="Top 20 Facilities by Detention Cost"
/>

## Detention Cost by Facility Type

<BarChart
    data={detention_by_type}
    x=facility_type
    y=total_detention_cost
    yFmt=usd0
    title="Total Detention Cost by Facility Type"
/>

## On-Time % vs Detention Cost

<ScatterPlot
    data={facility_rankings}
    x=on_time_pct
    y=estimated_detention_cost
    xFmt=pct1
    yFmt=usd0
    series=region_name
    title="On-Time % vs Detention Cost by Facility"
    xAxisTitle="On-Time %"
    yAxisTitle="Estimated Detention Cost"
    tooltipColumns={["facility_name"]}
/>

## Revenue Throughput by Region

<BarChart
    data={throughput_by_region}
    x=region_name
    y=revenue_throughput
    yFmt=usd0
    title="Revenue Throughput by Region"
/>

## Escalation Candidates

Facilities with the highest detention costs are flagged for complaint escalation through customers that pick up or deliver at the location.

<DataTable data={escalation_candidates}>
    <Column id=facility_name title="Facility" />
    <Column id=facility_type title="Type" />
    <Column id=city title="City" />
    <Column id=state title="State" />
    <Column id=region_name title="Region" />
    <Column id=total_events title="Events" />
    <Column id=avg_detention_per_event title="Avg Detention (min)" fmt=num0 />
    <Column id=estimated_detention_cost title="Detention Cost" fmt=usd0 />
    <Column id=on_time_pct title="On-Time %" fmt=pct1 />
</DataTable>
