{{ config(materialized='table') }}

select
    driver_id,
    driver_full_name,
    home_terminal,
    cdl_class,
    years_experience,
    dispatch_month,

    COUNT(*)                                                                    as total_trips,
    COUNT(*) FILTER (WHERE trip_status = 'Completed')                           as trips_completed,
    SUM(actual_distance_miles)                                                  as total_miles,
    SUM(total_revenue)                                                          as total_revenue,
    SUM(fuel_cost_total)                                                        as total_fuel_cost,
    SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)              as avg_mpg,
    SUM(idle_time_hours) / NULLIF(SUM(actual_duration_hours), 0)                as avg_idle_pct,
    SUM(deliveries_on_time)::float / NULLIF(SUM(total_deliveries), 0)           as on_time_delivery_pct,
    SUM(total_detention_minutes)                                                as total_detention_minutes,
    SUM(estimated_detention_cost)                                               as total_estimated_detention_cost,
    SUM(incident_count)                                                         as incident_count,
    SUM(at_fault_count)                                                         as at_fault_incident_count,
    SUM(preventable_count)                                                      as preventable_incident_count,
    SUM(total_revenue)
        / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)
                                                                                as revenue_per_mile,
    SUM(fuel_cost_total)
        / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0)
                                                                                as fuel_cost_per_mile

from {{ ref('fct_driver_trips') }}
group by
    driver_id,
    driver_full_name,
    home_terminal,
    cdl_class,
    years_experience,
    dispatch_month
