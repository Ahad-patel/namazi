begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

-- Origin: 19.0760, 72.8777. 0.005 deg lat ~ 556 m, 0.05 deg ~ 5.6 km.
insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'near', 'Near',
   'SRID=4326;POINT(72.8777 19.0810)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'mid', 'Mid',
   'SRID=4326;POINT(72.8777 19.0960)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'far', 'Far',
   'SRID=4326;POINT(72.8777 19.1260)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000004', 'hidden-close', 'Hidden Close',
   'SRID=4326;POINT(72.8777 19.0770)', 'hidden');

insert into public.jamat_times (masjid_id, prayer, jamat_time, valid_from) values
  ('aaaaaaaa-0000-0000-0000-000000000002', 'fajr', '05:30', current_date - 1),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'zuhr', '13:30', current_date - 1),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'asr', '17:00', current_date - 1),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'maghrib', '18:45', current_date - 1),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'isha', '20:30', current_date - 1),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'isha', '20:15', current_date - 1);

set local role anon;
select results_eq(
  'select slug from public.nearby_masjids(19.0760, 72.8777, 3000)',
  $$values ('near'), ('mid')$$,
  'nearby: within 3 km, nearest first, hidden excluded');
select results_eq(
  'select slug from public.nearby_masjids(19.0760, 72.8777, 10000)',
  $$values ('near'), ('mid'), ('far')$$,
  'wider radius includes the far masjid');
select ok(
  (select distance_m between 500 and 600 from public.nearby_masjids(19.0760, 72.8777, 3000) where slug = 'near'),
  'distance_m is in metres');
select ok(
  (select latitude = 19.0810 and longitude = 72.8777
     from public.nearby_masjids(19.0760, 72.8777, 3000) where slug = 'near'),
  'latitude/longitude are returned');
select is(
  (select next_at from public.nearby_masjids(19.0760, 72.8777, 3000) where slug = 'mid'),
  (select min(next_at) from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000002')),
  'nearby carries the soonest jamat of each masjid');
select ok(
  (select next_prayer is null from public.nearby_masjids(19.0760, 72.8777, 3000) where slug = 'near'),
  'masjid with no times has a null next jamat');
select results_eq(
  'select slug from public.next_jamat_nearby(19.0760, 72.8777, 3000)',
  $$values ('mid')$$,
  'next_jamat_nearby skips masjids without times');
reset role;

insert into public.masjids (slug, name, location, status)
select 'bulk-' || g, 'Bulk ' || g, 'SRID=4326;POINT(72.8777 19.0765)', 'active'
from generate_series(1, 60) g;

set local role anon;
select is(
  (select count(*)::int from public.nearby_masjids(19.0760, 72.8777, 3000)), 50,
  'nearby is capped at 50 rows');
select is(
  (select count(*)::int from public.nearby_masjids(19.0760, 72.8777, 999999)),
  50, 'huge radius is clamped and still capped');
reset role;

select * from finish();
rollback;
