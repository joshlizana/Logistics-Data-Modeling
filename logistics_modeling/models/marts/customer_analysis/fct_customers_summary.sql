{{ config(materialized='table') }}

select
    customer_id,

    MIN(dispatch_date)                                                          as first_trip_date,
    MAX(dispatch_date)                                                          as last_trip_date,
    COUNT(DISTINCT load_id)                                                     as total_loads,
    COUNT(*)                                                                    as total_trips,
    COUNT(*) FILTER (WHERE trip_status = 'Completed')                           as trips_completed,
    SUM(total_revenue)                                                          as total_revenue,
    SUM(accessorial_charges)                                                    as total_accessorial_charges,
    SUM(accessorial_charges) / NULLIF(SUM(total_revenue), 0)                    as accessorial_pct,
    SUM(weight_lbs)                                                             as total_weight_lbs,
    SUM(deliveries_on_time)::float / NULLIF(SUM(total_deliveries), 0)           as on_time_delivery_pct,
    SUM(total_detention_minutes)                                                as total_detention_minutes,
    SUM(estimated_detention_cost)                                               as total_estimated_detention_cost,
    SUM(total_revenue) / NULLIF(COUNT(*), 0)                                    as avg_revenue_per_trip,
    SUM(total_revenue)
        / NULLIF(DATEDIFF('day', MIN(dispatch_date), MAX(dispatch_date)), 0)    as avg_daily_revenue,
    SUM(total_revenue) / NULLIF(MAX(annual_revenue_potential), 0)               as revenue_vs_potential_pct

from {{ ref('fct_customer_trips') }}
group by customer_id
