{{ config(materialized='table') }}

select
    driver_id,

    MIN(dispatch_date)                                                            as first_trip_date,
    MAX(dispatch_date)                                                            as last_trip_date,
    COUNT(*)                                                                      as total_trips,
    COUNT(*) FILTER (WHERE trip_status = 'Completed')                             as trips_completed,
    SUM(actual_distance_miles)                                                    as total_miles,
    SUM(total_revenue)                                                            as total_revenue,
    SUM(fuel_cost_total)                                                          as total_fuel_cost,
    SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)                as avg_mpg,
    SUM(idle_time_hours)                                                          as total_idle_hours,
    SUM(deliveries_on_time)::float / NULLIF(SUM(total_deliveries), 0)             as on_time_delivery_pct,
    SUM(total_detention_minutes)                                                  as total_detention_minutes,
    SUM(estimated_detention_cost)                                                 as total_estimated_detention_cost,
    SUM(incident_count)                                                           as incident_count,
    SUM(at_fault_count)                                                           as at_fault_incident_count,
    SUM(preventable_count)                                                        as preventable_incident_count,
    SUM(total_revenue)
        / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0) as revenue_per_mile,
    SUM(total_revenue)
        / NULLIF(DATEDIFF('day', MIN(dispatch_date), MAX(dispatch_date)), 0)      as avg_daily_revenue

from {{ ref('fct_driver_trips') }}
group by driver_id
