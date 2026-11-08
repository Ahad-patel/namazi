begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'user@test.local');

insert into public.masjids (id, slug, name, location, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'active-one', 'Active One',
   'SRID=4326;POINT(72.8777 19.0760)', 'active'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'pending-one', 'Pending One',
   'SRID=4326;POINT(72.8777 19.0760)', 'pending'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'hidden-one', 'Hidden One',
   'SRID=4326;POINT(72.8777 19.0760)', 'hidden');

-- anon
set local role anon;
select results_eq('select slug from public.masjids', $$values ('active-one')$$,
  'anon sees only active masjids');
select throws_ok(
  $$insert into public.masjids (slug, name, location) values ('x-x', 'Xx', 'SRID=4326;POINT(0 0)')$$,
  '42501', null, 'anon cannot insert a masjid');
update public.masjids set name = 'Changed' where slug = 'active-one';
delete from public.masjids;
reset role;
select is((select name from public.masjids where slug = 'active-one'), 'Active One',
  'anon cannot update a masjid');
select is((select count(*)::int from public.masjids), 3, 'anon cannot delete masjids');

-- user
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq('select slug from public.masjids', $$values ('active-one')$$,
  'user sees only active masjids');
select throws_ok(
  $$insert into public.masjids (slug, name, location) values ('x-x', 'Xx', 'SRID=4326;POINT(0 0)')$$,
  '42501', null, 'user cannot insert a masjid directly');
update public.masjids set status = 'hidden' where slug = 'active-one';
delete from public.masjids;
reset role;
select is((select status from public.masjids where slug = 'active-one'), 'active',
  'user cannot update a masjid');
select is((select count(*)::int from public.masjids), 3, 'user cannot delete masjids');

select * from finish();
rollback;
