begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

-- Reference values for Mumbai (19.0760, 72.8777), Asia/Kolkata, from
-- published almanacs: 21 Jun 2024 sunrise 06:02, solar noon 12:40, sunset
-- 19:18; 21 Dec 2024 sunrise 07:08, sunset 18:05. Allow 3 minutes.
create temp table jun as
  select * from app.solar_times(19.0760, 72.8777, 'Asia/Kolkata', date '2024-06-21');
create temp table dec24 as
  select * from app.solar_times(19.0760, 72.8777, 'Asia/Kolkata', date '2024-12-21');

select ok(abs(extract(epoch from (select sunrise from jun) - '06:02'::time)) <= 180, 'June sunrise ~06:02');
select ok(abs(extract(epoch from (select dhuhr from jun) - '12:40'::time)) <= 180, 'June solar noon ~12:40');
select ok(abs(extract(epoch from (select sunset from jun) - '19:18'::time)) <= 180, 'June sunset ~19:18');
select ok(abs(extract(epoch from (select sunrise from dec24) - '07:08'::time)) <= 180, 'December sunrise ~07:08');
select ok(abs(extract(epoch from (select sunset from dec24) - '18:05'::time)) <= 180, 'December sunset ~18:05');
select ok(
  (select fajr < sunrise and sunrise < dhuhr and dhuhr < asr_shafii and asr_shafii < asr_hanafi
          and asr_hanafi < sunset and sunset < isha from jun),
  'times are in order through the day');

select ok(
  (select ends < starts from app.prayer_window('isha', 19.0760, 72.8777, 'Asia/Kolkata', date '2024-06-21')),
  'isha window wraps past midnight');
select ok(app.in_window('23:30', '20:00', '05:00') and app.in_window('04:00', '20:00', '05:00')
          and not app.in_window('12:00', '20:00', '05:00'), 'in_window handles a wrapping window');
select ok(app.in_window(null, '05:00', '06:00'), 'a null time (no azaan) passes');

-- ---- trigger ----
insert into auth.users (id, email) values ('11111111-1111-1111-1111-111111111111', 'u1@test.local');
update public.profiles set is_adult = true, terms_version = 't1', terms_accepted_at = now()
  where id = '11111111-1111-1111-1111-111111111111';
insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'window-one', 'Window One',
   'SRID=4326;POINT(72.8777 19.0760)', 'active');

set local role anon;
select is(
  (select count(*)::int from public.prayer_windows('aaaaaaaa-0000-0000-0000-000000000001')),
  6, 'prayer_windows: one row per namaz for anon');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'fajr', '18:00')$$,
  'MT422', null, 'fajr at 6 PM is rejected');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '12:00')$$,
  'MT422', null, 'isha at noon is rejected');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, azaan_time, jamat_time)
    select 'aaaaaaaa-0000-0000-0000-000000000001', 'maghrib', '12:00', w.starts + interval '15 minutes'
    from public.prayer_windows('aaaaaaaa-0000-0000-0000-000000000001') w where w.prayer = 'maghrib'$$,
  'MT422', null, 'an azaan outside the window is rejected');
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    select 'aaaaaaaa-0000-0000-0000-000000000001', 'maghrib', w.starts + interval '15 minutes'
    from public.prayer_windows('aaaaaaaa-0000-0000-0000-000000000001') w where w.prayer = 'maghrib'$$,
  'a time inside today''s window is accepted');
reset role;

select * from finish();
rollback;
