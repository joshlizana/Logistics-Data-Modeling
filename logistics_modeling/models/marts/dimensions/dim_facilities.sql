{{ config(materialized='table') }}

select
    f.facility_id,
    f.facility_name,
    f.facility_type,
    f.city_id,
    c.city,
    c.state,
    f.latitude,
    f.longitude,
    f.dock_doors,
    f.operating_hours_start,
    f.operating_hours_end,
    f.region_id,
    r.region_name
from {{ ref('stg_facilities') }} f
inner join {{ source('logistics', 'cities') }} c on f.city_id = c.city_id
inner join {{ ref('stg_regions') }}            r on f.region_id = r.region_id
