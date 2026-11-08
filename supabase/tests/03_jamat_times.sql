begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'user@test.local');

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'active-one', 'Active One',
   'SRID=4326;POINT(72.8777 19.0760)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'hidden-one', 'Hidden One',
   'SRID=4326;POINT(72.8777 19.0760)', 'hidden');

insert into public.jamat_times (masjid_id, prayer, azaan_time, jamat_time, valid_from) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'fajr', '05:15', '05:30', current_date - 10),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'fajr', '05:30', '05:45', current_date + 10),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:00', '13:30', current_date - 10),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'jummah', '13:00', '13:45', current_date - 10),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'fajr', '05:15', '05:30', current_date - 10);

set local role anon;
select is((select count(*)::int from public.jamat_times), 4,
  'anon reads times of active masjids only');
select is(
  (select jamat_time from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') where prayer = 'fajr'),
  '05:30'::time, 'masjid_times uses the latest valid_from on or before today');
select is(
  (select count(*)::int from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001')), 3,
  'one row per prayer that has a time');
select is(
  (select source from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') limit 1),
  'verified', 'phase 1 source is verified');
select ok(
  (select bool_and(next_at > now()) from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001')),
  'every next_at is in the future');
select is(
  (select extract(isodow from next_at at time zone 'Asia/Kolkata')::int
     from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') where prayer = 'jummah'),
  5, 'jummah next_at is a Friday');
select isnt(
  (select extract(isodow from next_at at time zone 'Asia/Kolkata')::int
     from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') where prayer = 'zuhr'),
  5, 'zuhr skips Friday when the masjid has jummah');
select is_empty(
  $$select prayer from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000003')$$,
  'masjid_times of a hidden masjid is empty for anon');
select throws_ok(
  $$insert into public.jamat_times (masjid_id, prayer, jamat_time) values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:00')$$,
  '42501', null, 'anon cannot insert a time');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok(
  $$insert into public.jamat_times (masjid_id, prayer, jamat_time) values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:00')$$,
  '42501', null, 'user cannot insert a time directly');
reset role;

select * from finish();
rollback;
