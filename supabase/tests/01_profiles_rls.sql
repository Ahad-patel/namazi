begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'user@test.local', '{"full_name":"Test User"}'),
  ('22222222-2222-2222-2222-222222222222', 'super@test.local', '{}');

-- handle_new_user trigger
select is(
  (select role from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'user', 'trigger creates a profile with role user');
select is(
  (select display_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Test User', 'display_name comes from full_name');
select is(
  (select display_name from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  'super', 'display_name falls back to the email local part');

update public.profiles set role = 'super_admin'
  where id = '22222222-2222-2222-2222-222222222222';

-- anon
set local role anon;
select is_empty('select id from public.profiles', 'anon reads no profiles');
reset role;

-- user
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq(
  'select id from public.profiles',
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'user reads only own profile');
select is(public.app_role(), 'user', 'app_role() is user');
select throws_ok(
  $$insert into public.profiles (id) values ('33333333-3333-3333-3333-333333333333')$$,
  '42501', null, 'user cannot insert a profile');
update public.profiles set role = 'super_admin'
  where id = '11111111-1111-1111-1111-111111111111';
delete from public.profiles where id = '11111111-1111-1111-1111-111111111111';
reset role;

select is(
  (select role from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'user', 'user cannot promote self (no update policy)');
select is(
  (select count(*)::int from public.profiles), 2,
  'user cannot delete own profile (no delete policy)');

-- super admin
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select is((select count(*)::int from public.profiles), 2, 'super admin reads all profiles');
select is(public.app_role(), 'super_admin', 'app_role() is super_admin');
reset role;

select * from finish();
rollback;
