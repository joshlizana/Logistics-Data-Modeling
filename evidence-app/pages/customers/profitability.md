---
title: Customer Profitability
---

```sql fleet_margin
select
    sum(net_revenue_after_fuel) / nullif(sum(total_revenue), 0)     as fleet_net_margin_pct
from logistics.fct_route_trips
```

```sql customer_profitability
select
    rt.customer_id,
    c.customer_name                                                     as company_name,
    c.customer_type,
    count(*)                                                            as total_trips,
    sum(rt.total_revenue)                                               as total_revenue,
    sum(rt.fuel_cost_total)                                             as total_fuel_cost,
    sum(rt.net_revenue_after_fuel)                                      as net_revenue_after_fuel,
    sum(rt.net_revenue_after_fuel) / nullif(sum(rt.total_revenue), 0)   as net_margin_pct,
    c.annual_revenue_potential,
    cs.revenue_vs_potential_pct
from logistics.fct_route_trips rt
join logistics.dim_customers c on rt.customer_id = c.customer_id
join logistics.fct_customers_summary cs on rt.customer_id = cs.customer_id
group by rt.customer_id, c.customer_name, c.customer_type, c.annual_revenue_potential, cs.revenue_vs_potential_pct
order by net_margin_pct asc
```

```sql profitability_kpis
select
    count(*) filter (where net_margin_pct < (select sum(net_revenue_after_fuel) / nullif(sum(total_revenue), 0) from logistics.fct_route_trips))
                                                                as customers_below_avg,
    min(net_margin_pct)                                         as lowest_margin_pct,
    count(*) filter (where net_margin_pct <= 0.05)              as renegotiation_candidates
from (
    select
        rt.customer_id,
        sum(rt.net_revenue_after_fuel) / nullif(sum(rt.total_revenue), 0) as net_margin_pct
    from logistics.fct_route_trips rt
    group by rt.customer_id
)
```

```sql renegotiation_candidates
select *
from ${customer_profitability}
where net_margin_pct <= 0.05
order by total_revenue desc
```

```sql worst5_monthly
select
    dispatch_month,
    c.customer_name                                                     as company_name,
    sum(rt.net_revenue_after_fuel) / nullif(sum(rt.total_revenue), 0)   as net_margin_pct
from logistics.fct_route_trips rt
join logistics.dim_customers c on rt.customer_id = c.customer_id
where rt.customer_id in (
    select customer_id
    from (
        select customer_id, sum(net_revenue_after_fuel) / nullif(sum(total_revenue), 0) as m
        from logistics.fct_route_trips
        group by customer_id
        order by m asc
        limit 5
    )
)
group by dispatch_month, c.customer_name
order by dispatch_month
```

<BigValue data={fleet_margin} value=fleet_net_margin_pct title="Fleet Net Margin %" fmt=pct1 />
<BigValue data={profitability_kpis} value=customers_below_avg title="Customers Below Avg Margin" />
<BigValue data={profitability_kpis} value=lowest_margin_pct title="Lowest Customer Margin %" fmt=pct1 />
<BigValue data={profitability_kpis} value=renegotiation_candidates title="Renegotiation Candidates" />

## Customer Profitability Rankings

<DataTable data={customer_profitability} search=true>
    <Column id=company_name title="Customer" />
    <Column id=customer_type title="Type" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=total_fuel_cost title="Fuel Cost" fmt=usd0 />
    <Column id=net_revenue_after_fuel title="Net Revenue" fmt=usd0 />
    <Column id=net_margin_pct title="Net Margin %" fmt=pct1 />
</DataTable>

## Margin Distribution

<BarChart
    data={customer_profitability}
    x=company_name
    y=net_margin_pct
    yFmt=pct1
    swapXY=true
    sort=false
    title="Net Margin % by Customer"
/>

## Revenue vs Net Margin

<ScatterPlot
    data={customer_profitability}
    x=total_revenue
    y=net_margin_pct
    xFmt=usd0
    yFmt=pct1
    series=customer_type
    title="Total Revenue vs Net Margin %"
    xAxisTitle="Total Revenue"
    yAxisTitle="Net Margin %"
    tooltipColumns={["company_name"]}
/>

## Monthly Margin Trend (5 Worst-Margin Customers)

<LineChart
    data={worst5_monthly}
    x=dispatch_month
    y=net_margin_pct
    series=company_name
    yFmt=pct1
    title="Monthly Net Margin % — Bottom 5 Customers"
/>

## Renegotiation Candidates (Margin at or Below 5%)

Customers with net margin at or below 5% are flagged for contract renegotiation.

<DataTable data={renegotiation_candidates}>
    <Column id=company_name title="Customer" />
    <Column id=customer_type title="Type" />
    <Column id=total_trips title="Trips" />
    <Column id=total_revenue title="Revenue" fmt=usd0 />
    <Column id=total_fuel_cost title="Fuel Cost" fmt=usd0 />
    <Column id=net_revenue_after_fuel title="Net Revenue" fmt=usd0 />
    <Column id=net_margin_pct title="Net Margin %" fmt=pct1 />
    <Column id=annual_revenue_potential title="Revenue Potential" fmt=usd0 />
    <Column id=revenue_vs_potential_pct title="Capture %" fmt=pct1 />
</DataTable>
