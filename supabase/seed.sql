-- Local and staging only. Never run against prod (no seeded data in prod).
-- Five test masjids in Mumbai with a full set of verified times.

insert into public.masjids (id, slug, name, name_local, name_script, address, location, status) values
  ('5eed0000-0000-0000-0000-000000000001', 'test-masjid-colaba', 'Test Masjid Colaba',
   null, null, 'Colaba, Mumbai', 'SRID=4326;POINT(72.8311 18.9067)', 'active'),
  ('5eed0000-0000-0000-0000-000000000002', 'test-masjid-noor', 'Test Masjid-e-Noor',
   'مسجد نور', 'urdu', 'Mohammed Ali Road, Mumbai', 'SRID=4326;POINT(72.8347 18.9562)', 'active'),
  ('5eed0000-0000-0000-0000-000000000003', 'test-masjid-al-huda', 'Test Masjid Al-Huda',
   'مسجد الهدى', 'arab', 'Byculla, Mumbai', 'SRID=4326;POINT(72.8336 18.9750)', 'active'),
  ('5eed0000-0000-0000-0000-000000000004', 'test-masjid-bandra', 'Test Masjid Bandra',
   null, null, 'Bandra West, Mumbai', 'SRID=4326;POINT(72.8295 19.0596)', 'active'),
  ('5eed0000-0000-0000-0000-000000000005', 'test-masjid-kurla', 'Test Masjid Kurla',
   null, null, 'Kurla West, Mumbai', 'SRID=4326;POINT(72.8796 19.0726)', 'active');

insert into public.jamat_times (masjid_id, prayer, azaan_time, jamat_time, valid_from)
select m.id, t.prayer::public.prayer, t.azaan::time + (m.n * interval '5 min'),
       t.jamat::time + (m.n * interval '5 min'), current_date - 30
from (values
  ('5eed0000-0000-0000-0000-000000000001'::uuid, 0),
  ('5eed0000-0000-0000-0000-000000000002'::uuid, 1),
  ('5eed0000-0000-0000-0000-000000000003'::uuid, 2),
  ('5eed0000-0000-0000-0000-000000000004'::uuid, 3)
) as m (id, n)
cross join (values
  ('fajr', '05:20', '05:45'),
  ('zuhr', '13:00', '13:30'),
  ('asr', '16:45', '17:15'),
  ('maghrib', '18:30', '18:35'),
  ('isha', '20:00', '20:30'),
  ('jummah', '13:00', '13:45')
) as t (prayer, azaan, jamat);
-- test-masjid-kurla has no times on purpose (empty state).
