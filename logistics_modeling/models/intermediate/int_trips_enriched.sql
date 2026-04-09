{{ config(materialized='table') }}

select
    t.trip_id,
    t.load_id,
    t.driver_id,
    t.truck_id,
    t.trailer_id,

    lo.customer_id,
    lo.route_id,
    r.lane_id,
    r.origin_city_id,
    r.destination_city_id,
    l.origin_region_id,
    l.destination_region_id,
    l.lane_type,

    d.driver_full_name,
    d.cdl_class,
    d.years_experience,
    d.home_terminal           as driver_home_terminal,
    d.is_terminated,

    tk.unit_number,
    tk.make                   as truck_make,
    tk.model_year             as truck_model_year,
    tk.fuel_type,
    tk.home_terminal          as truck_home_terminal,

    tr.trailer_type,
    tr.length_feet,

    cu.customer_name,
    cu.customer_type,
    cu.credit_terms_days,
    cu.primary_freight_type,
    cu.is_active,
    cu.annual_revenue_potential,

    lo.load_date,
    lo.load_type,
    lo.weight_lbs,
    lo.pieces,
    lo.booking_type,
    lo.load_status,
    lo.revenue,
    lo.fuel_surcharge,
    lo.accessorial_charges,

    r.typical_distance_miles,
    r.base_rate_per_mile,
    r.fuel_surcharge_rate,
    r.typical_transit_days,

    t.dispatch_date,
    DATE_TRUNC('month', t.dispatch_date)                            as dispatch_month,
    t.actual_distance_miles,
    t.actual_duration_hours,
    t.fuel_gallons_used,
    t.average_mpg,
    t.idle_time_hours,
    t.trip_status,

    lo.revenue + lo.fuel_surcharge + lo.accessorial_charges         as total_revenue,

    (lo.revenue + lo.fuel_surcharge + lo.accessorial_charges)
        / NULLIF(COALESCE(t.actual_distance_miles, r.typical_distance_miles), 0)
                                                                    as revenue_per_mile,

    t.actual_distance_miles - r.typical_distance_miles               as distance_variance_miles

from {{ ref('stg_trips') }} t
inner join {{ ref('stg_loads') }}     lo on t.load_id    = lo.load_id
inner join {{ ref('stg_routes') }}    r  on lo.route_id  = r.route_id
inner join {{ ref('stg_lanes') }}     l  on r.lane_id    = l.lane_id
left  join {{ ref('stg_drivers') }}   d  on t.driver_id  = d.driver_id
left  join {{ ref('stg_trucks') }}    tk on t.truck_id   = tk.truck_id
left  join {{ ref('stg_trailers') }}  tr on t.trailer_id = tr.trailer_id
left  join {{ ref('stg_customers') }} cu on lo.customer_id = cu.customer_id
