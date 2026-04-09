{{ config(materialized='table') }}

with fuel_purchases as (
    select
        trip_id,
        SUM(total_cost) as fuel_cost_total
    from {{ ref('stg_fuel_purchases') }}
    group by trip_id
),

delivery_events as (
    select
        trip_id,
        SUM(detention_minutes) as total_detention_minutes
    from {{ ref('stg_delivery_events') }}
    group by trip_id
)

select
    t.trip_id,
    t.load_id,
    t.route_id,
    t.lane_id,
    t.origin_city_id,
    t.destination_city_id,
    t.origin_region_id,
    t.destination_region_id,
    t.lane_type,
    t.dispatch_date,
    t.dispatch_month,
    t.customer_id,
    t.customer_name,
    t.customer_type,
    t.load_type,
    t.weight_lbs,
    t.pieces,
    t.booking_type,
    t.load_status,
    t.revenue,
    t.fuel_surcharge,
    t.accessorial_charges,
    t.total_revenue,
    t.typical_distance_miles,
    t.base_rate_per_mile,
    t.fuel_surcharge_rate,
    t.typical_transit_days,
    t.actual_distance_miles,
    t.actual_duration_hours,

    fp.fuel_cost_total,
    de.total_detention_minutes,

    t.distance_variance_miles,

    t.total_revenue - COALESCE(fp.fuel_cost_total, 0)                           as net_revenue_after_fuel,

    (t.total_revenue - COALESCE(fp.fuel_cost_total, 0))
        / NULLIF(t.total_revenue, 0)                                            as net_revenue_after_fuel_pct,

    t.distance_variance_miles / NULLIF(t.typical_distance_miles, 0)             as distance_variance_pct,

    t.total_revenue
        / NULLIF(COALESCE(t.actual_distance_miles, t.typical_distance_miles), 0)
                                                                                as revenue_per_mile,

    t.actual_distance_miles / NULLIF(t.actual_duration_hours, 0)                as mph_avg,

    GREATEST(COALESCE(de.total_detention_minutes, 0) - 120, 0) * 1.25          as estimated_detention_cost

from {{ ref('int_trips_enriched') }} t
left join fuel_purchases    fp on t.trip_id = fp.trip_id
left join delivery_events   de on t.trip_id = de.trip_id
