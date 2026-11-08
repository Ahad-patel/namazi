-- Phase 1: verified jamat times. Local `time` + masjids.timezone, never UTC.
-- Client writes arrive in Phase 3 (masjid admins) through RPCs.

create type public.prayer as enum ('fajr', 'zuhr', 'asr', 'maghrib', 'isha', 'jummah');

create table public.jamat_times (
  id uuid primary key default gen_random_uuid(),
  masjid_id uuid not null references public.masjids (id) on delete restrict,
  prayer public.prayer not null,
  azaan_time time,
  jamat_time time not null,
  valid_from date not null default current_date,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (masjid_id, prayer, valid_from),
  check (azaan_time is null or azaan_time <= jamat_time)
);

-- The unique constraint's index covers (masjid_id, prayer, valid_from desc) scans.
create index jamat_times_updated_by_idx on public.jamat_times (updated_by);

alter table public.jamat_times enable row level security;

create policy jamat_times_select_active_masjid
  on public.jamat_times for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.masjids m
      where m.id = jamat_times.masjid_id and m.status = 'active'
    )
  );
