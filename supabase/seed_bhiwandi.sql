-- Local and staging only. Never run against prod (no seeded data in prod).
-- Five test masjids around Bhiwandi with a full set of verified times, so the
-- next-jamat banner and countdown can be tried there. Names say "Test" on
-- purpose: these are not real masjids and the times are made up.
-- Safe to re-run.

insert into public.masjids (id, slug, name, name_local, name_script, address, location, status) values
  ('5eed0000-0000-0000-0000-000000000101', 'test-masjid-bhiwandi-market', 'Test Masjid Bhiwandi Market',
   null, null, 'Market area, Bhiwandi', 'SRID=4326;POINT(73.0631 19.2967)', 'active'),
  ('5eed0000-0000-0000-0000-000000000102', 'test-masjid-nizampura', 'Test Masjid Nizampura',
   'مسجد نظام پورہ', 'urdu', 'Nizampura, Bhiwandi', 'SRID=4326;POINT(73.0560 19.2995)', 'active'),
  ('5eed0000-0000-0000-0000-000000000103', 'test-masjid-shanti-nagar', 'Test Masjid Shanti Nagar',
   null, null, 'Shanti Nagar, Bhiwandi', 'SRID=4326;POINT(73.0700 19.2870)', 'active'),
  ('5eed0000-0000-0000-0000-000000000104', 'test-masjid-kamatghar', 'Test Masjid Kamatghar',
   'مسجد الفلاح', 'arab', 'Kamatghar, Bhiwandi', 'SRID=4326;POINT(73.0530 19.2780)', 'active'),
  ('5eed0000-0000-0000-0000-000000000105', 'test-masjid-dhamankar-naka', 'Test Masjid Dhamankar Naka',
   null, null, 'Dhamankar Naka, Bhiwandi', 'SRID=4326;POINT(73.0480 19.2905)', 'active')
on conflict (id) do nothing;

insert into public.jamat_times (masjid_id, prayer, azaan_time, jamat_time, valid_from)
select m.id, t.prayer::public.prayer, t.azaan::time + (m.n * interval '5 min'),
       t.jamat::time + (m.n * interval '5 min'), current_date - 30
from (values
  ('5eed0000-0000-0000-0000-000000000101'::uuid, 0),
  ('5eed0000-0000-0000-0000-000000000102'::uuid, 1),
  ('5eed0000-0000-0000-0000-000000000103'::uuid, 2),
  ('5eed0000-0000-0000-0000-000000000104'::uuid, 3),
  ('5eed0000-0000-0000-0000-000000000105'::uuid, 4)
) as m (id, n)
cross join (values
  ('fajr', '05:20', '05:40'),
  ('zuhr', '13:00', '13:30'),
  ('asr', '16:45', '17:10'),
  ('maghrib', '18:20', '18:25'),
  ('isha', '19:50', '20:15'),
  ('jummah', '13:00', '13:45')
) as t (prayer, azaan, jamat)
on conflict (masjid_id, prayer, valid_from) do nothing;
