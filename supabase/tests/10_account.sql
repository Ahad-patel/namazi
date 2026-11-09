begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'u2@test.local');
update public.profiles set is_adult = true, terms_version = 't1', terms_accepted_at = now();

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'acct-one', 'Acct One', 'SRID=4326;POINT(72.8777 19.0760)', 'active');

-- u1: one claim; u2: one claim (must not leak into u1's export).
insert into public.masjid_admins (masjid_id, user_id, role_at_masjid, phone) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'imam', '+919800000001'),
  ('aaaaaaaa-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'committee', '+919800000002');

set local role anon;
select throws_ok($$ select public.my_data() $$, '42501', null, 'anon cannot export');

set local role authenticated;
select throws_ok($$ select public.my_data() $$, '42501', null, 'no jwt sub: refused');

set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is((public.my_data() -> 'profile' ->> 'id'), '11111111-1111-1111-1111-111111111111', 'own profile');
select is(jsonb_array_length(public.my_data() -> 'claims'), 1, 'only own claims');
select is((public.my_data() -> 'claims' -> 0 ->> 'phone'), '+919800000001', 'own phone included');
select is(jsonb_array_length(public.my_data() -> 'suggestions'), 0, 'no suggestions yet');
select is(jsonb_array_length(public.my_data() -> 'votes'), 0, 'no votes yet');

reset role;
select is(
  (select count(*)::int from cron.job where jobname = 'purge-claims'),
  1,
  'purge-claims is scheduled daily'
);
select is(
  (select schedule from cron.job where jobname = 'purge-claims'),
  '30 21 * * *',
  'at 03:00 IST'
);

select * from finish();
rollback;
