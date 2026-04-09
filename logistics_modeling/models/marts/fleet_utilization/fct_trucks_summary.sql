{{ config(materialized='table') }}

with trip_agg as (
    select
        truck_id,
        COUNT(*)                                                                    as total_trips,
        COUNT(*) FILTER (WHERE trip_status = 'Completed')                           as trips_completed,
        SUM(actual_distance_miles)                                                  as total_miles,
        SUM(total_revenue)                                                          as total_revenue,
        SUM(fuel_cost_total)                                                        as total_fuel_cost,
        SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)              as avg_mpg,
        SUM(idle_time_hours)                                                        as total_idle_hours,
        MIN(dispatch_date)                                                          as first_trip_date,
        MAX(dispatch_date)                                                          as last_trip_date
    from {{ ref('fct_fleet_trips') }}
    group by truck_id
)

select
    tk.truck_id,
    tk.unit_number,
    tk.make,
    tk.model_year,
    tk.fuel_type,
    tk.home_terminal,
    tk.acquisition_date,
    tk.status,

    ta.total_trips,
    ta.trips_completed,
    ta.total_miles,
    ta.total_revenue,
    ta.total_fuel_cost,
    ta.avg_mpg,
    ta.total_idle_hours,
    ta.first_trip_date,
    ta.last_trip_date,

    DATEDIFF('day', ta.first_trip_date, ta.last_trip_date)                      as days_in_service,

    ta.total_revenue
        / NULLIF(DATEDIFF('day', ta.first_trip_date, ta.last_trip_date), 0)     as avg_daily_revenue

from {{ ref('stg_trucks') }} tk
left join trip_agg ta on tk.truck_id = ta.truck_id
