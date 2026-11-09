begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

-- u1 consented, u2 consented, u3 no consent yet, u4 banned (consented).
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'u2@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'u3@test.local'),
  ('44444444-4444-4444-4444-444444444444', 'u4@test.local');
update public.profiles set is_adult = true, terms_version = 't1', terms_accepted_at = now()
  where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
               '44444444-4444-4444-4444-444444444444');
update public.profiles set is_banned = true where id = '44444444-4444-4444-4444-444444444444';

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'active-one', 'Active One',
   'SRID=4326;POINT(72.8777 19.0760)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'hidden-one', 'Hidden One',
   'SRID=4326;POINT(72.8777 19.0760)', 'hidden');

-- ---- anon ----
set local role anon;
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time, suggested_by)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:00', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null, 'anon cannot suggest');
select throws_ok(
  $$select public.accept_terms('t1')$$,
  '42501', null, 'anon cannot call accept_terms');
reset role;

-- ---- u3: signed in, no consent ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:00')$$,
  '42501', null, 'user without consent cannot suggest');
select lives_ok($$select public.accept_terms('t1')$$, 'accept_terms runs');
select results_eq(
  $$select is_adult, terms_version from public.profiles where id = '33333333-3333-3333-3333-333333333333'$$,
  $$values (true, 't1'::text)$$,
  'accept_terms records adult + version');
select throws_ok($$select public.accept_terms('')$$, '22023', null, 'empty terms version rejected');
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:00')$$,
  'after consent the user can suggest');
reset role;

-- ---- u1: consented user ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, azaan_time, jamat_time, note)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:00', '13:30', 'board says 1:30')$$,
  'user suggests a time');
select is(
  (select suggested_by from public.time_suggestions where prayer = 'zuhr' and status = 'open'),
  '11111111-1111-1111-1111-111111111111'::uuid, 'suggested_by defaults to the caller');
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:45')$$,
  'a second suggestion for the same namaz');
select results_eq(
  $$select jamat_time from public.time_suggestions where prayer = 'zuhr' and status = 'open'$$,
  $$values ('13:45'::time)$$,
  'new suggestion replaces the old one (one open per user/masjid/namaz)');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time, suggested_by)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '20:30', '22222222-2222-2222-2222-222222222222')$$,
  '42501', null, 'cannot suggest as someone else');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time, net_votes)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '20:30', 99)$$,
  '42501', null, 'cannot seed net_votes');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000003', 'isha', '20:30')$$,
  '42501', null, 'cannot suggest for a hidden masjid');
update public.time_suggestions set jamat_time = '05:00' where prayer = 'zuhr';
delete from public.time_suggestions where prayer = 'zuhr';
reset role;
select is(
  (select count(*)::int from public.time_suggestions where prayer = 'zuhr'), 2,
  'user cannot update or delete suggestions (no policies)');
select is(
  (select jamat_time from public.time_suggestions where prayer = 'zuhr' and status = 'open'),
  '13:45'::time, 'suggestion unchanged after the update attempt');

-- ---- 10-a-day abuse trigger (u1 already made 2 today) ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    select 'aaaaaaaa-0000-0000-0000-000000000001', p, '12:00'
    from unnest(array['fajr','asr','maghrib','isha','jummah']::public.prayer[]) p$$,
  'suggestions 3-7 today');
select lives_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    select 'aaaaaaaa-0000-0000-0000-000000000001', p, '12:30'
    from unnest(array['fajr','asr','maghrib']::public.prayer[]) p$$,
  'suggestions 8-10 today');
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'isha', '21:00')$$,
  'MT429', null, 'the 11th suggestion in a day is rejected');
reset role;

-- ---- votes ----
-- u3's asr suggestion is the target.
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok(
  $$insert into public.suggestion_votes (suggestion_id, value)
    select id, 1 from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333'$$,
  'user upvotes someone else''s suggestion');
select throws_ok(
  $$insert into public.suggestion_votes (suggestion_id, value)
    select id, 1 from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333'$$,
  '23505', null, 'once per suggestion');
select throws_ok(
  $$insert into public.suggestion_votes (suggestion_id, value)
    select id, 1 from public.time_suggestions
    where suggested_by = '11111111-1111-1111-1111-111111111111' and prayer = 'zuhr' and status = 'open'$$,
  '42501', null, 'cannot vote on own suggestion');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
insert into public.suggestion_votes (suggestion_id, value)
  select id, 1 from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333';
reset role;
select is(
  (select net_votes from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333'),
  2, 'net_votes counts both upvotes');

set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
update public.suggestion_votes set value = -1
  where suggestion_id = (select id from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333');
reset role;
select is(
  (select net_votes from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333'),
  0, 'changing a vote recounts');

-- u2 tries to delete u1's vote, then deletes own.
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
delete from public.suggestion_votes where user_id = '11111111-1111-1111-1111-111111111111';
delete from public.suggestion_votes where user_id = '22222222-2222-2222-2222-222222222222';
select is_empty('select 1 from public.suggestion_votes', 'user sees only own votes (none left)');
reset role;
select results_eq(
  $$select user_id from public.suggestion_votes$$,
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'own vote deleted, other user''s vote untouched');

-- ---- banned user ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}';
select throws_ok(
  $$insert into public.time_suggestions (masjid_id, prayer, jamat_time)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'asr', '17:10')$$,
  '42501', null, 'banned user cannot suggest');
select throws_ok(
  $$insert into public.suggestion_votes (suggestion_id, value)
    select id, 1 from public.time_suggestions where suggested_by = '33333333-3333-3333-3333-333333333333'$$,
  '42501', null, 'banned user cannot vote');
reset role;

select * from finish();
rollback;
