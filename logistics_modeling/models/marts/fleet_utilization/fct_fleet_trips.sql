{{ config(materialized='table') }}

with fuel_purchases as (
    select
        trip_id,
        SUM(total_cost) as fuel_cost_total
    from {{ ref('stg_fuel_purchases') }}
    group by trip_id
)

select
    t.trip_id,
    t.truck_id,
    t.trailer_id,
    t.driver_id,
    t.dispatch_date,
    t.dispatch_month,
    t.unit_number,
    t.truck_make                  as make,
    t.truck_model_year            as model_year,
    t.fuel_type,
    t.truck_home_terminal,
    t.trailer_type,
    t.length_feet,
    t.actual_distance_miles,
    t.actual_duration_hours,
    t.fuel_gallons_used,
    t.average_mpg,
    t.idle_time_hours,
    t.typical_distance_miles,
    t.trip_status,
    t.load_type,
    t.weight_lbs,
    t.total_revenue,

    fp.fuel_cost_total,

    t.idle_time_hours / NULLIF(t.actual_duration_hours, 0)                      as idle_pct,

    t.total_revenue
        / NULLIF(COALESCE(t.actual_distance_miles, t.typical_distance_miles), 0) as revenue_per_mile,

    fp.fuel_cost_total
        / NULLIF(COALESCE(t.actual_distance_miles, t.typical_distance_miles), 0) as fuel_cost_per_mile

from {{ ref('int_trips_enriched') }} t
left join fuel_purchases fp on t.trip_id = fp.trip_id
