-- Phase 1 read RPCs. All security invoker, so masjids/jamat_times RLS applies.
-- Privacy: lat/lng are query parameters only. Never insert, log or
-- `raise notice` them.

-- Next instant (timestamptz) a jamat at local `p_time` happens in `p_tz`.
-- Jummah only on Fridays; Zuhr skips Fridays when the masjid has a Jummah time.
create function app.next_occurrence(
  p_prayer public.prayer,
  p_time time,
  p_tz text,
  p_has_jummah boolean
)
returns timestamptz
language plpgsql
stable
set search_path = ''
as $$
declare
  v_today date := (now() at time zone p_tz)::date;
  v_day date;
  v_at timestamptz;
begin
  for i in 0..8 loop
    v_day := v_today + i;
    continue when p_prayer = 'jummah' and extract(isodow from v_day) <> 5;
    continue when p_prayer = 'zuhr' and p_has_jummah and extract(isodow from v_day) = 5;
    v_at := (v_day + p_time) at time zone p_tz;
    if v_at > now() then
      return v_at;
    end if;
  end loop;
  return null;
end;
$$;

grant execute on function app.next_occurrence(public.prayer, time, text, boolean)
  to anon, authenticated;

-- What the UI shows per namaz. Phase 1: the current verified time only
-- (latest valid_from on or before the masjid's local today). Phase 2 replaces
-- this with the full trust rules (community fallback, conflicts).
create function public.masjid_times(masjid_id uuid)
returns table (
  prayer public.prayer,
  azaan_time time,
  jamat_time time,
  source text,
  updated_at timestamptz,
  next_at timestamptz
)
language sql
stable
set search_path = ''
as $$
  with m as (
    select x.id, x.timezone
    from public.masjids x
    where x.id = masjid_times.masjid_id
  ),
  cur as (
    select distinct on (t.prayer) t.prayer, t.azaan_time, t.jamat_time, t.updated_at
    from public.jamat_times t
    join m on m.id = t.masjid_id
    where t.valid_from <= (now() at time zone m.timezone)::date
    order by t.prayer, t.valid_from desc
  )
  select
    c.prayer,
    c.azaan_time,
    c.jamat_time,
    'verified',
    c.updated_at,
    app.next_occurrence(
      c.prayer,
      c.jamat_time,
      m.timezone,
      exists (select 1 from cur j where j.prayer = 'jummah')
    )
  from cur c
  cross join m
  order by c.prayer
$$;

-- Every active masjid within the radius plus its soonest jamat. Radius is
-- clamped server side to 100 m .. 20 km.
create function app.masjids_within(lat double precision, lng double precision, radius_m integer)
returns table (
  id uuid,
  slug text,
  name text,
  name_local text,
  name_script text,
  address text,
  timezone text,
  latitude double precision,
  longitude double precision,
  distance_m double precision,
  next_prayer public.prayer,
  next_jamat_time time,
  next_source text,
  next_updated_at timestamptz,
  next_at timestamptz
)
language sql
stable
set search_path = ''
as $$
  with origin as (
    select extensions.st_setsrid(
      extensions.st_makepoint(masjids_within.lng, masjids_within.lat),
      4326
    )::extensions.geography as g
  )
  select
    m.id,
    m.slug,
    m.name,
    m.name_local,
    m.name_script,
    m.address,
    m.timezone,
    extensions.st_y(m.location::extensions.geometry),
    extensions.st_x(m.location::extensions.geometry),
    extensions.st_distance(m.location, o.g),
    n.prayer,
    n.jamat_time,
    n.source,
    n.updated_at,
    n.next_at
  from public.masjids m
  cross join origin o
  left join lateral (
    select t.prayer, t.jamat_time, t.source, t.updated_at, t.next_at
    from public.masjid_times(m.id) t
    order by t.next_at nulls last
    limit 1
  ) n on true
  where m.status = 'active'
    and extensions.st_dwithin(
      m.location,
      o.g,
      least(greatest(masjids_within.radius_m, 100), 20000)
    )
$$;

grant execute on function app.masjids_within(double precision, double precision, integer)
  to anon, authenticated;

-- Nearby list: nearest first, capped at 50.
create function public.nearby_masjids(
  lat double precision,
  lng double precision,
  radius_m integer default 3000
)
returns table (
  id uuid,
  slug text,
  name text,
  name_local text,
  name_script text,
  address text,
  timezone text,
  latitude double precision,
  longitude double precision,
  distance_m double precision,
  next_prayer public.prayer,
  next_jamat_time time,
  next_source text,
  next_updated_at timestamptz,
  next_at timestamptz
)
language sql
stable
set search_path = ''
as $$
  select w.*
  from app.masjids_within(nearby_masjids.lat, nearby_masjids.lng, nearby_masjids.radius_m) w
  order by w.distance_m
  limit 50
$$;

-- Banner: the soonest upcoming jamat anywhere in the radius (not just the
-- 50 nearest).
create function public.next_jamat_nearby(
  lat double precision,
  lng double precision,
  radius_m integer default 3000
)
returns table (
  id uuid,
  slug text,
  name text,
  name_local text,
  name_script text,
  address text,
  timezone text,
  latitude double precision,
  longitude double precision,
  distance_m double precision,
  next_prayer public.prayer,
  next_jamat_time time,
  next_source text,
  next_updated_at timestamptz,
  next_at timestamptz
)
language sql
stable
set search_path = ''
as $$
  select w.*
  from app.masjids_within(next_jamat_nearby.lat, next_jamat_nearby.lng, next_jamat_nearby.radius_m) w
  where w.next_at is not null
  order by w.next_at, w.distance_m
  limit 1
$$;

-- Detail page (`/m/:slug`).
create function public.masjid_by_slug(masjid_slug text)
returns table (
  id uuid,
  slug text,
  name text,
  name_local text,
  name_script text,
  address text,
  timezone text,
  latitude double precision,
  longitude double precision
)
language sql
stable
set search_path = ''
as $$
  select
    m.id,
    m.slug,
    m.name,
    m.name_local,
    m.name_script,
    m.address,
    m.timezone,
    extensions.st_y(m.location::extensions.geometry),
    extensions.st_x(m.location::extensions.geometry)
  from public.masjids m
  where m.slug = masjid_by_slug.masjid_slug
$$;
