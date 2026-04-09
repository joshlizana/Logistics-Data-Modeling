{{ config(materialized='table') }}

select
    customer_id,
    customer_name,
    customer_type,
    primary_freight_type,
    is_active,
    annual_revenue_potential,
    dispatch_month,

    COUNT(DISTINCT load_id)                                                     as load_count,
    COUNT(*)                                                                    as trip_count,
    SUM(total_revenue)                                                          as total_revenue,
    SUM(accessorial_charges)                                                    as total_accessorial_charges,
    SUM(accessorial_charges) / NULLIF(SUM(total_revenue), 0)                    as accessorial_pct,
    SUM(weight_lbs)                                                             as total_weight_lbs,
    SUM(pieces)                                                                 as total_pieces,
    SUM(deliveries_on_time)::float / NULLIF(SUM(total_deliveries), 0)           as on_time_delivery_pct,
    SUM(total_detention_minutes)                                                as total_detention_minutes,
    SUM(total_detention_minutes)::float / NULLIF(COUNT(*), 0)                   as avg_detention_per_trip,
    SUM(estimated_detention_cost)                                               as total_estimated_detention_cost,
    SUM(total_revenue) / NULLIF(COUNT(*), 0)                                    as avg_revenue_per_trip,
    SUM(total_revenue) / NULLIF(MAX(annual_revenue_potential) / 12.0, 0)        as revenue_vs_potential_pct

from {{ ref('fct_customer_trips') }}
group by
    customer_id,
    customer_name,
    customer_type,
    primary_freight_type,
    is_active,
    annual_revenue_potential,
    dispatch_month
