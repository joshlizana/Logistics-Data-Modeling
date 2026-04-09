---
title: Customer Detail
---

```sql customer_list
select
    cs.customer_id,
    c.customer_name                     as company_name
from logistics.fct_customers_summary cs
join logistics.dim_customers c on cs.customer_id = c.customer_id
order by c.customer_name
```

<Dropdown name=customer_selector data={customer_list} value=customer_id label=company_name title="Select Customer" />

```sql customer_summary
select
    cs.*,
    c.customer_name                     as company_name,
    c.customer_type,
    c.primary_freight_type,
    c.annual_revenue_potential
from logistics.fct_customers_summary cs
join logistics.dim_customers c on cs.customer_id = c.customer_id
where cs.customer_id = '${inputs.customer_selector.value}'
```

```sql customer_monthly
select
    dispatch_month,
    total_revenue,
    on_time_delivery_pct,
    avg_detention_per_trip,
    annual_revenue_potential / 12.0      as monthly_potential
from logistics.fct_customer_monthly
where customer_id = '${inputs.customer_selector.value}'
order by dispatch_month
```

```sql peer_comparison
select 'This Customer' as label, avg_revenue_per_trip, on_time_delivery_pct, accessorial_pct
from logistics.fct_customers_summary
where customer_id = '${inputs.customer_selector.value}'
union all
select 'Portfolio Average', avg(avg_revenue_per_trip), avg(on_time_delivery_pct), avg(accessorial_pct)
from logistics.fct_customers_summary
```

<BigValue data={customer_summary} value=total_revenue title="Total Revenue" fmt=usd0 />
<BigValue data={customer_summary} value=total_loads title="Total Loads" />
<BigValue data={customer_summary} value=on_time_delivery_pct title="On-Time %" fmt=pct1 />
<BigValue data={customer_summary} value=accessorial_pct title="Accessorial %" fmt=pct1 />
<BigValue data={customer_summary} value=revenue_vs_potential_pct title="Rev vs Potential" fmt=pct1 />
<BigValue data={customer_summary} value=avg_revenue_per_trip title="Avg Rev/Trip" fmt=usd0 />

## Monthly Revenue

<LineChart
    data={customer_monthly}
    x=dispatch_month
    y=total_revenue
    yFmt=usd0
    title="Monthly Revenue"
/>

## Monthly On-Time % & Detention

<LineChart
    data={customer_monthly}
    x=dispatch_month
    y=on_time_delivery_pct
    y2=avg_detention_per_trip
    yFmt=pct1
    y2Fmt=num0
    title="Monthly On-Time % & Avg Detention per Trip"
/>

## Monthly Revenue vs Potential

<LineChart
    data={customer_monthly}
    x=dispatch_month
    y={["total_revenue", "monthly_potential"]}
    yFmt=usd0
    title="Monthly Revenue vs Monthly Revenue Potential"
/>

## Peer Comparison

<BarChart
    data={peer_comparison}
    x=label
    y={["avg_revenue_per_trip", "on_time_delivery_pct", "accessorial_pct"]}
    type=grouped
    title="This Customer vs Portfolio Average"
/>
