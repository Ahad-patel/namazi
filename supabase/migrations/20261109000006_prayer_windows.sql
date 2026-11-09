-- Phase 2: a suggested jamat/azaan must fall inside its namaz's time window,
-- computed from the sun at the masjid's lat/lng (the method prayer-time apps
-- use). Only for validating input: the app never displays calculated times
-- (PRD: calculated azaan times are out of scope for v1).

-- Sun-based times for one day, as local `time` in p_tz.
-- Karachi method (Fajr/Isha at 18 degrees below the horizon, standard in
-- India); Asr for both shadow factors (1 = Shafi'i, 2 = Hanafi). Elevation
-- lowers the horizon for sunrise/sunset.
-- ponytail: elevation defaults to 0 (masjids has no elevation column; OSM
-- rarely has one). Near sea level (Mumbai) the error is under a minute; add a
-- masjids.elevation_m column if the app reaches hill towns.
create function app.solar_times(
  p_lat double precision,
  p_lng double precision,
  p_tz text,
  p_day date,
  p_elevation_m double precision default 0
)
returns table (
  fajr time,
  sunrise time,
  dhuhr time,
  asr_shafii time,
  asr_hanafi time,
  sunset time,
  isha time
)
language plpgsql
stable
set search_path = ''
as $$
declare
  -- days from J2000, at the masjid's solar noon
  d double precision := (p_day - date '2000-01-01') - p_lng / 360.0;
  g double precision := mod((357.529 + 0.98560028 * d)::numeric, 360)::double precision;
  q double precision := mod((280.459 + 0.98564736 * d)::numeric, 360)::double precision;
  l double precision := q + 1.915 * sind(g) + 0.020 * sind(2 * g);
  e double precision := 23.439 - 0.00000036 * d;
  ra double precision := atan2d(cosd(e) * sind(l), cosd(l)) / 15.0;
  decl double precision := asind(sind(e) * sind(l));
  eqt double precision;
  noon double precision; -- hours after UTC midnight
  horizon double precision := 0.833 + 0.0347 * sqrt(greatest(p_elevation_m, 0));
  base timestamptz := p_day::timestamp at time zone 'UTC';
begin
  ra := mod((ra + 24)::numeric, 24)::double precision;
  eqt := q / 15.0 - ra;
  eqt := mod((eqt + 36)::numeric, 24)::double precision - 12;
  noon := 12 - p_lng / 15.0 - eqt;

  return query
  with h as (
    select
      noon - app.hour_angle(18, p_lat, decl) as fajr,
      noon - app.hour_angle(horizon, p_lat, decl) as sunrise,
      noon as dhuhr,
      noon + app.hour_angle(-atand(1 / (1 + tand(abs(p_lat - decl)))), p_lat, decl) as asr1,
      noon + app.hour_angle(-atand(1 / (2 + tand(abs(p_lat - decl)))), p_lat, decl) as asr2,
      noon + app.hour_angle(horizon, p_lat, decl) as sunset,
      noon + app.hour_angle(18, p_lat, decl) as isha
  )
  select
    ((base + make_interval(secs => h.fajr * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.sunrise * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.dhuhr * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.asr1 * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.asr2 * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.sunset * 3600)) at time zone p_tz)::time,
    ((base + make_interval(secs => h.isha * 3600)) at time zone p_tz)::time
  from h;
end;
$$;

-- Hours between solar noon and the sun reaching `p_angle` degrees below the
-- horizon (negative = above, used for Asr). Null when it never gets there
-- (high latitudes in summer); callers then skip the check.
create function app.hour_angle(
  p_angle double precision,
  p_lat double precision,
  p_decl double precision
)
returns double precision
language sql
immutable
set search_path = ''
as $$
  select case
    when abs((-sind(p_angle) - sind(p_decl) * sind(p_lat)) / (cosd(p_decl) * cosd(p_lat))) > 1
      then null
    else acosd((-sind(p_angle) - sind(p_decl) * sind(p_lat)) / (cosd(p_decl) * cosd(p_lat))) / 15.0
  end
$$;

-- When a jamat for p_prayer may be: [starts, ends], 10 minutes of slack on
-- each side for calculation error and local custom. Isha wraps past
-- midnight (ends < starts). Zuhr/Jummah run to the later (Hanafi) Asr and Asr
-- starts at the earlier (Shafi'i) one, so both schools fit.
create function app.prayer_window(
  p_prayer public.prayer,
  p_lat double precision,
  p_lng double precision,
  p_tz text,
  p_day date
)
returns table (starts time, ends time)
language sql
stable
set search_path = ''
as $$
  -- Whole minutes: starts rounded down, ends up, so a time picked from the
  -- displayed window is never refused by its seconds.
  select
    date_trunc('minute', timestamp '2000-01-01' + w.starts)::time,
    date_trunc('minute', timestamp '2000-01-01' + w.ends + interval '59.999 seconds')::time
  from (
    select
      case p_prayer
        when 'fajr' then s.fajr
        when 'zuhr' then s.dhuhr
        when 'jummah' then s.dhuhr
        when 'asr' then s.asr_shafii
        when 'maghrib' then s.sunset
        when 'isha' then s.isha
      end - interval '10 minutes' as starts,
      case p_prayer
        when 'fajr' then s.sunrise
        when 'zuhr' then s.asr_hanafi
        when 'jummah' then s.asr_hanafi
        when 'asr' then s.sunset
        when 'maghrib' then s.isha
        when 'isha' then s.fajr
      end + interval '10 minutes' as ends
    from app.solar_times(p_lat, p_lng, p_tz, p_day) s
  ) w
$$;

-- True when t is inside [starts, ends], including a window that wraps past
-- midnight. A null window (never computed) lets everything through.
create function app.in_window(t time, starts time, ends time)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case
    when t is null or starts is null or ends is null then true
    when starts <= ends then t between starts and ends
    else t >= starts or t <= ends
  end
$$;

grant execute on function app.solar_times(double precision, double precision, text, date, double precision),
  app.hour_angle(double precision, double precision, double precision),
  app.prayer_window(public.prayer, double precision, double precision, text, date),
  app.in_window(time, time, time)
  to anon, authenticated;

-- Today's window per namaz at one masjid (masjid's local date). The suggest
-- sheet shows it and checks input before sending; the trigger below is the
-- real check.
create function public.prayer_windows(masjid_id uuid)
returns table (prayer public.prayer, starts time, ends time)
language sql
stable
set search_path = ''
as $$
  select p.prayer, w.starts, w.ends
  from public.masjids m
  cross join unnest(enum_range(null::public.prayer)) as p(prayer)
  cross join lateral app.prayer_window(
    p.prayer,
    extensions.st_y(m.location::extensions.geometry),
    extensions.st_x(m.location::extensions.geometry),
    m.timezone,
    (now() at time zone m.timezone)::date
  ) w
  where m.id = prayer_windows.masjid_id
  order by p.prayer
$$;

-- The suggestions trigger from 20261108000005, plus the window check
-- (SQLSTATE MT422). Checked against the masjid's local today.
create or replace function app.before_suggestion_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  w record;
begin
  if (
    select count(*)
    from public.time_suggestions s
    where s.suggested_by = new.suggested_by
      and s.created_at > now() - interval '1 day'
  ) >= 10 then
    raise exception 'daily suggestion limit reached' using errcode = 'MT429';
  end if;

  select x.starts, x.ends into w
  from public.masjids m
  cross join lateral app.prayer_window(
    new.prayer,
    extensions.st_y(m.location::extensions.geometry),
    extensions.st_x(m.location::extensions.geometry),
    m.timezone,
    (now() at time zone m.timezone)::date
  ) x
  where m.id = new.masjid_id;

  if not app.in_window(new.jamat_time, w.starts, w.ends)
     or not app.in_window(new.azaan_time, w.starts, w.ends) then
    raise exception 'time outside the % window (% - %)', new.prayer, w.starts, w.ends
      using errcode = 'MT422';
  end if;

  update public.time_suggestions s
     set status = 'superseded'
   where s.masjid_id = new.masjid_id
     and s.prayer = new.prayer
     and s.suggested_by = new.suggested_by
     and s.status = 'open';
  return new;
end;
$$;
