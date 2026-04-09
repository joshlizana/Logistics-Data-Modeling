---
title: Customer Analysis
---

```sql customer_rankings
select
    cs.customer_id,
    c.customer_name                     as company_name,
    c.customer_type,
    c.primary_freight_type,
    cs.total_loads,
    cs.total_trips,
    cs.total_revenue,
    cs.avg_revenue_per_trip,
    cs.on_time_delivery_pct,
    cs.accessorial_pct,
    cs.revenue_vs_potential_pct,
    c.annual_revenue_potential
from logistics.fct_customers_summary cs
join logistics.dim_customers c on cs.customer_id = c.customer_id
order by cs.total_revenue desc
```

```sql type_segmentation
select
    c.customer_type,
    count(*)                                        as customers,
    sum(cs.total_revenue)                           as total_revenue,
    sum(cs.total_trips)                             as total_trips
from logistics.fct_customers_summary cs
join logistics.dim_customers c on cs.customer_id = c.customer_id
group by c.customer_type
order by total_revenue desc
```

```sql under_potential
select
    c.customer_name                                 as company_name,
    c.customer_type,
    cs.total_revenue,
    c.annual_revenue_potential,
    cs.revenue_vs_potential_pct
from logistics.fct_customers_summary cs
join logistics.dim_customers c on cs.customer_id = c.customer_id
where cs.revenue_vs_potential_pct < 0.5
order by c.annual_revenue_potential desc
```

## Customer Rankings

<DataTable data={customer_rankings} search=true>
    <Column id=company_name title="Customer" />
    <Column id=customer_type title="Type" />
    <Column id=primary_freight_type title="Freight Type" />
    <Column id=total_loads title="Loads" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=avg_revenue_per_trip title="Rev/Trip" fmt=usd0 />
    <Column id=on_time_delivery_pct title="On-Time %" fmt=pct1 />
    <Column id=accessorial_pct title="Accessorial %" fmt=pct1 />
    <Column id=revenue_vs_potential_pct title="Rev vs Potential" fmt=pct1 />
</DataTable>

## Revenue by Customer Type

<BarChart
    data={type_segmentation}
    x=customer_type
    y=total_revenue
    yFmt=usd0
    title="Total Revenue by Customer Type"
/>

## Revenue vs Potential

<ScatterPlot
    data={customer_rankings}
    x=annual_revenue_potential
    y=total_revenue
    xFmt=usd0
    yFmt=usd0
    series=customer_type
    title="Actual Revenue vs Annual Revenue Potential"
    xAxisTitle="Annual Revenue Potential"
    yAxisTitle="Total Revenue"
    tooltipColumns={["company_name"]}
/>

## Revenue Concentration

<BarChart
    data={customer_rankings}
    x=company_name
    y=total_revenue
    yFmt=usd0
    swapXY=true
    sort=false
    title="Revenue by Customer"
/>

## Under-Potential Customers (Below 50% Capture)

<DataTable data={under_potential}>
    <Column id=company_name title="Customer" />
    <Column id=customer_type title="Type" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=annual_revenue_potential title="Potential" fmt=usd0 />
    <Column id=revenue_vs_potential_pct title="Capture %" fmt=pct1 />
</DataTable>
