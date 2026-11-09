begin;
create extension if not exists pgtap with schema extensions;
select plan(49);

-- u1 claimant, u2/u3/u5 more claimants, u4 banned, sa super admin.
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'u2@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'u3@test.local'),
  ('44444444-4444-4444-4444-444444444444', 'u4@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'u5@test.local'),
  ('99999999-9999-9999-9999-999999999999', 'sa@test.local');
update public.profiles set is_adult = true, terms_version = 't1', terms_accepted_at = now();
update public.profiles set is_banned = true where id = '44444444-4444-4444-4444-444444444444';
update public.profiles set role = 'super_admin' where id = '99999999-9999-9999-9999-999999999999';

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin-one', 'Admin One', 'SRID=4326;POINT(72.8777 19.0760)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'admin-two', 'Admin Two', 'SRID=4326;POINT(72.8777 19.0760)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'pending-one', 'Pending One', 'SRID=4326;POINT(72.8777 19.0760)', 'pending');

create temp table win as
  select p.prayer, w.starts
  from unnest(enum_range(null::public.prayer)) p(prayer)
  cross join lateral app.prayer_window(p.prayer, 19.0760, 72.8777, 'Asia/Kolkata', current_date) w;
grant select on win to anon, authenticated;

-- ---- claims ----
set local role anon;
select throws_ok(
  $$insert into public.masjid_admins (masjid_id, user_id, role_at_masjid, phone)
    values ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'imam', '9876543210')$$,
  '42501', null, 'anon cannot claim');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok(
  $$insert into public.masjid_admins (masjid_id, role_at_masjid, phone, proof_path)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'imam', '+919876543210',
            '11111111-1111-1111-1111-111111111111/c1.jpg')$$,
  'user claims a masjid');
select throws_ok(
  $$insert into public.masjid_admins (masjid_id, role_at_masjid, phone)
    values ('aaaaaaaa-0000-0000-0000-000000000001', 'committee', '9876543210')$$,
  '23505', null, 'one live claim per user and masjid');
select throws_ok(
  $$insert into public.masjid_admins (masjid_id, role_at_masjid)
    values ('aaaaaaaa-0000-0000-0000-000000000002', 'imam')$$,
  '42501', null, 'phone is required');
select throws_ok(
  $$insert into public.masjid_admins (masjid_id, role_at_masjid, phone, proof_path)
    values ('aaaaaaaa-0000-0000-0000-000000000002', 'imam', '9876543210',
            '22222222-2222-2222-2222-222222222222/x.jpg')$$,
  '42501', null, 'proof path must be in your own folder');
select throws_ok(
  $$insert into public.masjid_admins (masjid_id, role_at_masjid, phone, status)
    values ('aaaaaaaa-0000-0000-0000-000000000002', 'imam', '9876543210', 'approved')$$,
  '42501', null, 'cannot self-approve on insert');
update public.masjid_admins set status = 'approved';
delete from public.masjid_admins;
select results_eq(
  $$select status from public.masjid_admins$$,
  $$values ('pending'::text)$$,
  'claim unchanged: no client update or delete');
select results_eq(
  $$select can_manage, claim_status from public.masjid_access('aaaaaaaa-0000-0000-0000-000000000001')$$,
  $$values (false, 'pending'::text)$$,
  'masjid_access: pending, cannot manage yet');
select throws_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:30')$$,
  '42501', null, 'pending claimant cannot set times');
select throws_ok(
  $$select public.review_claim((select id from public.masjid_admins limit 1), true)$$,
  '42501', null, 'user cannot review claims');
select throws_ok(
  $$select * from public.claims_by_status('pending')$$,
  '42501', null, 'user cannot read the claims queue');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select is_empty($$select 1 from public.masjid_admins$$, 'others cannot see my claim (or my phone)');
insert into public.masjid_admins (masjid_id, role_at_masjid, phone)
  values ('aaaaaaaa-0000-0000-0000-000000000001', 'committee', '9876543211');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
insert into public.masjid_admins (masjid_id, role_at_masjid, phone)
  values ('aaaaaaaa-0000-0000-0000-000000000001', 'mutawalli', '9876543212');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}';
insert into public.masjid_admins (masjid_id, role_at_masjid, phone)
  values ('aaaaaaaa-0000-0000-0000-000000000001', 'committee', '9876543213');
reset role;

-- ---- super admin review + 3-admin cap ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"99999999-9999-9999-9999-999999999999","role":"authenticated"}';
select is((select count(*)::int from public.claims_by_status('pending')), 4, 'super admin sees the pending queue');
select lives_ok(
  $$select public.review_claim(id, true) from public.masjid_admins
    where user_id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222',
                      '33333333-3333-3333-3333-333333333333')$$,
  'super admin approves three claims');
select throws_ok(
  $$select public.review_claim(id, true) from public.masjid_admins
    where user_id = '55555555-5555-5555-5555-555555555555'$$,
  'MT409', null, 'a fourth approved admin is refused');
select lives_ok(
  $$select public.review_claim(id, false, 'already 3 admins') from public.masjid_admins
    where user_id = '55555555-5555-5555-5555-555555555555'$$,
  'super admin rejects with a reason');
select throws_ok(
  $$select public.review_claim(id, true) from public.masjid_admins
    where user_id = '55555555-5555-5555-5555-555555555555'$$,
  'P0002', null, 'a decided claim cannot be reviewed again');
select ok(
  (select bool_and(not (after ? 'phone') and not (before ? 'phone') and not (after ? 'proof_path'))
     from public.moderation_log where target_table = 'masjid_admins'),
  'moderation log never stores phone or proof path');
select results_eq(
  $$select action, reason from public.moderation_log
    where target_table = 'masjid_admins' order by id desc limit 1$$,
  $$values ('reject_claim'::text, 'already 3 admins'::text)$$,
  'reject is logged with its reason');
reset role;

-- ---- admin: times + history ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is_empty($$select 1 from public.moderation_log$$, 'non super admin reads no moderation log');
select is((select can_manage from public.masjid_access('aaaaaaaa-0000-0000-0000-000000000001')), true,
  'approved admin can manage');
select lives_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr',
      (select starts + interval '40 minutes' from win where prayer = 'zuhr'),
      (select starts + interval '20 minutes' from win where prayer = 'zuhr'))$$,
  'admin sets zuhr');
select lives_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr',
      (select starts + interval '45 minutes' from win where prayer = 'zuhr'))$$,
  'admin changes zuhr the same day');
select results_eq(
  $$select source, jamat_time from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') where prayer = 'zuhr'$$,
  $$select 'verified'::text, starts + interval '45 minutes' from win where prayer = 'zuhr'$$,
  'the new time shows as verified');
select results_eq(
  $$select op from public.jamat_time_history order by id$$,
  $$values ('INSERT'::text), ('UPDATE'::text)$$,
  'every change lands in jamat_time_history');
select throws_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000001', 'fajr', '18:00')$$,
  'MT422', null, 'admin times obey the namaz window too');
select throws_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', '13:30', null, current_date - 2)$$,
  '22023', null, 'valid_from cannot be in the past');
select throws_ok(
  $$select public.set_jamat_time('aaaaaaaa-0000-0000-0000-000000000002', 'zuhr', '13:30')$$,
  '42501', null, 'admin of one masjid cannot set another''s times');
reset role;

-- ---- inbox: a differing suggestion, accepted ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}';
insert into public.time_suggestions (masjid_id, prayer, jamat_time)
  select 'aaaaaaaa-0000-0000-0000-000000000001', 'zuhr', starts + interval '60 minutes' from win where prayer = 'zuhr';
select throws_ok(
  $$select * from public.admin_inbox('aaaaaaaa-0000-0000-0000-000000000001')$$,
  '42501', null, 'non admins cannot read the inbox');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is((select count(*)::int from public.admin_inbox('aaaaaaaa-0000-0000-0000-000000000001')), 1,
  'inbox lists the suggestion that differs');
select lives_ok(
  $$select public.accept_suggestion(id) from public.admin_inbox('aaaaaaaa-0000-0000-0000-000000000001')$$,
  'admin accepts it');
select results_eq(
  $$select jamat_time from public.masjid_times('aaaaaaaa-0000-0000-0000-000000000001') where prayer = 'zuhr'$$,
  $$select starts + interval '60 minutes' from win where prayer = 'zuhr'$$,
  'accepted suggestion became the verified time');
select is_empty($$select 1 from public.admin_inbox('aaaaaaaa-0000-0000-0000-000000000001')$$,
  'inbox is empty afterwards');
reset role;

-- ---- super admin: hide / restore / ban / masjid status / revoke ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}';
insert into public.time_suggestions (masjid_id, prayer, jamat_time)
  select 'aaaaaaaa-0000-0000-0000-000000000001', 'asr', starts + interval '30 minutes' from win where prayer = 'asr';
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"99999999-9999-9999-9999-999999999999","role":"authenticated"}';
create temp table sid as
  select id from public.time_suggestions where suggested_by = '55555555-5555-5555-5555-555555555555' and status = 'open';
select is((select count(*)::int from public.open_suggestions() where author_name = 'u5'), 1,
  'open suggestions list shows the author');
select is((select count(*)::int from public.masjids_by_status('active', 'two')), 1,
  'masjid search by name');
select lives_ok($$select public.hide_suggestion((select id from sid), 'spam')$$, 'super admin hides a suggestion');
select is((select count(*)::int from public.hidden_suggestions()), 1, 'it shows in the Hidden tab');
select lives_ok($$select public.restore_suggestion((select id from sid))$$, 'and restores it');
select results_eq(
  $$select display_name, open_count, is_banned from public.suggestion_author((select id from sid))$$,
  $$values ('u5'::text, 1, false)$$,
  'ban preview: author and open suggestion count');
select lives_ok($$select public.ban_suggestion_author((select id from sid), 'abuse')$$, 'super admin bans the author');
select results_eq(
  $$select p.is_banned, (select count(*)::int from public.time_suggestions s
                         where s.suggested_by = p.id and s.status = 'open')
    from public.profiles p where p.id = '55555555-5555-5555-5555-555555555555'$$,
  $$values (true, 0)$$,
  'author banned and their open suggestions hidden');
select lives_ok($$select public.set_masjid_status('aaaaaaaa-0000-0000-0000-000000000003', 'active')$$,
  'super admin approves a pending masjid');
select throws_ok($$select public.set_masjid_status('aaaaaaaa-0000-0000-0000-000000000003', 'pending')$$,
  '22023', null, 'active -> pending is not a valid move');
select lives_ok(
  $$select public.revoke_admin(id, 'left the committee') from public.masjid_admins
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  'super admin revokes an admin');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is((select can_manage from public.masjid_access('aaaaaaaa-0000-0000-0000-000000000001')), false,
  'revoked admin can no longer manage');
reset role;

-- ---- storage: claim-proofs ----
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok(
  $$insert into storage.objects (bucket_id, name) values ('claim-proofs', '22222222-2222-2222-2222-222222222222/c2.jpg')$$,
  'user uploads a proof into their own folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name) values ('claim-proofs', '11111111-1111-1111-1111-111111111111/c9.jpg')$$,
  '42501', null, 'cannot upload into someone else''s folder');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select is_empty($$select 1 from storage.objects where bucket_id = 'claim-proofs'$$,
  'other users cannot read a proof photo');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"99999999-9999-9999-9999-999999999999","role":"authenticated"}';
select is((select count(*)::int from storage.objects where bucket_id = 'claim-proofs'), 1,
  'super admin can read proof photos');
reset role;

select * from finish();
rollback;
