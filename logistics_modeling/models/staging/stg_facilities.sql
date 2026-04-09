{{ config(materialized='table') }}

select
    f.facility_id,
    f.facility_name,
    f.facility_type,
    c.city_id,
    f.latitude,
    f.longitude,
    f.dock_doors,
    case
        when f.operating_hours = '24/7' then time '00:00'
        else strptime(split_part(f.operating_hours, '-', 1), '%I%p')::time
    end as operating_hours_start,
    case
        when f.operating_hours = '24/7' then time '00:00'
        else strptime(split_part(f.operating_hours, '-', 2), '%I%p')::time
    end as operating_hours_end,
    f.region_id
from {{ source('logistics', 'facilities') }} f
inner join {{ source('logistics', 'cities') }} c
    on lower(f.city) = lower(c.city)
    and lower(f.state) = lower(c.state)
