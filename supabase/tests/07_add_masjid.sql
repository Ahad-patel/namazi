begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'u3@test.local');
update public.profiles set is_adult = true, terms_version = 't1', terms_accepted_at = now()
  where id = '11111111-1111-1111-1111-111111111111';

set local role anon;
select throws_ok(
  $$select public.add_masjid('Masjid Anon', 19.07, 72.87)$$,
  '42501', null, 'anon cannot add a masjid');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok(
  $$select public.add_masjid('Masjid No Consent', 19.07, 72.87)$$,
  '42501', null, 'user without consent cannot add a masjid');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok(
  $$select public.add_masjid('  Masjid-e-Noor (Kurla)  ', 19.07, 72.87, 'مسجد نور', 'urdu')$$,
  'consented user adds a masjid');
select lives_ok(
  $$select public.add_masjid('مسجد', 19.08, 72.88)$$,
  'a name without Latin letters still gets a slug');
select is_empty(
  $$select 1 from public.masjids$$,
  'pending masjids are not visible to their creator');
select throws_ok(
  $$select public.add_masjid('Masjid Nowhere', 120, 72.87)$$,
  '22023', null, 'invalid latitude rejected');
select throws_ok(
  $$insert into public.masjids (slug, name, location, status)
    values ('sneaky', 'Sneaky', 'SRID=4326;POINT(72.8 19.0)', 'active')$$,
  '42501', null, 'cannot insert an active masjid directly');
reset role;

select results_eq(
  $$select name, name_local, status, created_by from public.masjids where name_script = 'urdu'$$,
  $$values ('Masjid-e-Noor (Kurla)'::text, 'مسجد نور'::text, 'pending'::text,
            '11111111-1111-1111-1111-111111111111'::uuid)$$,
  'row is pending, trimmed, owned by the caller');
select ok(
  (select bool_and(slug ~ '^masjid-e-noor-kurla-[a-f0-9]{6}$' or slug ~ '^masjid-[a-f0-9]{6}$')
     from public.masjids),
  'slugs are url-safe with a random suffix');

select * from finish();
rollback;
