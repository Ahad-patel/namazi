begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'u2@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'u3@test.local');

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'trust-one', 'Trust One',
   'SRID=4326;POINT(72.8777 19.0760)', 'active');

insert into public.jamat_times (masjid_id, prayer, azaan_time, jamat_time, valid_from, updated_at) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:00', '13:30', current_date - 1, now()),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '20:15', '20:30', current_date - 1, now()),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '16:45', '17:00', current_date - 200, now() - interval '200 days');

-- Inserted as the superuser (RLS bypassed) so net_votes and status can be set.
insert into public.time_suggestions (masjid_id, prayer, jamat_time, suggested_by, net_votes, status, created_at) values
  -- zuhr: two differ from verified 13:30, one matches
  ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:45', '11111111-1111-1111-1111-111111111111', 5, 'open', now()),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:50', '22222222-2222-2222-2222-222222222222', 0, 'open', now()),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:30', '33333333-3333-3333-3333-333333333333', 0, 'open', now()),
  -- isha: only one differs
  ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '20:45', '11111111-1111-1111-1111-111111111111', 3, 'open', now()),
  -- asr: verified is stale, community says 17:15
  ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:15', '11111111-1111-1111-1111-111111111111', 3, 'open', now()),
  -- maghrib: no verified; two tie on 2 votes, newest wins; 1 vote never shows
  ('aaaaaaaa-0000-0000-0000-000000000001', 'maghrib', '18:40', '11111111-1111-1111-1111-111111111111', 2, 'open', now() - interval '2 hours'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'maghrib', '18:45', '22222222-2222-2222-2222-222222222222', 2, 'open', now() - interval '1 hour'),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'maghrib', '18:50', '33333333-3333-3333-3333-333333333333', 1, 'open', now()),
  -- fajr: below the 2-vote threshold
  ('aaaaaaaa-0000-0000-0000-000000000001', 'fajr', '05:30', '11111111-1111-1111-1111-111111111111', 1, 'open', now()),
  -- jummah: only archived / hidden rows
  ('aaaaaaaa-0000-0000-0000-000000000001', 'jummah', '13:45', '11111111-1111-1111-1111-111111111111', 3, 'superseded', now()),
  ('aaaaaaaa-0000-0000-0000-000000000001', 'jummah', '13:50', '22222222-2222-2222-2222-222222222222', 9, 'hidden', now());

set local role anon;

create temp table t as
  select * from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001');

select results_eq(
  $$select source, jamat_time from t where prayer = 'zuhr'$$,
  $$values ('verified'::text, '13:30'::time)$$,
  'verified time wins over a higher-voted suggestion');
select is((select differing_reports from t where prayer = 'zuhr'), 2,
  '2 open suggestions differ from verified: reported');
select is((select differing_reports from t where prayer = 'isha'), 0,
  'a single differing suggestion is not reported');
select is((select stale from t where prayer = 'zuhr'), false, 'fresh verified time is not stale');
select is((select community_jamat_time from t where prayer = 'zuhr'), null::time,
  'no community line when not stale');
select is((select stale from t where prayer = 'asr'), true, 'verified time older than 120 days is stale');
select is((select source from t where prayer = 'asr'), 'verified', 'stale verified time still shows');
select results_eq(
  $$select community_jamat_time, community_net_votes from t where prayer = 'asr'$$,
  $$values ('17:15'::time, 3)$$,
  'stale row carries the community suggestion');
select results_eq(
  $$select source, jamat_time, net_votes from t where prayer = 'maghrib'$$,
  $$values ('community'::text, '18:45'::time, 2)$$,
  'no verified: top suggestion with >= 2 votes, tie goes to newest');
select is_empty($$select 1 from t where prayer = 'fajr'$$,
  'suggestion below 2 net votes is not shown');
select is_empty($$select 1 from t where prayer = 'jummah'$$,
  'superseded and hidden suggestions are never shown');
select is((select net_votes from t where prayer = 'zuhr'), null::int,
  'verified rows carry no net_votes');
select ok((select bool_and(next_at > now()) from t), 'every next_at is in the future');

select is(
  (select count(*)::int from public.masjid_suggestions('aaaaaaaa-0000-0000-0000-000000000001')),
  9, 'masjid_suggestions lists only open suggestions');
select is(
  (select next_source from public.nearby_masjids(19.0760, 72.8777, 1000) limit 1) is not null,
  true, 'nearby_masjids still works on top of the new masjid_times');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select results_eq(
  $$select prayer, jamat_time from public.masjid_suggestions('aaaaaaaa-0000-0000-0000-000000000001') where is_mine$$,
  $$values ('zuhr'::public.prayer, '13:50'::time), ('maghrib'::public.prayer, '18:45'::time)$$,
  'is_mine marks the caller''s own suggestions');
reset role;

select * from finish();
rollback;
