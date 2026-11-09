-- Phase 1: masjids. Read-only for clients; only active rows are visible.

create table public.masjids (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (char_length(name) between 2 and 120),
  name_local text check (char_length(name_local) <= 120),
  name_script text check (name_script in ('arab', 'urdu')),
  address text check (char_length(address) <= 300),
  location extensions.geography (point, 4326) not null,
  timezone text not null default 'Asia/Kolkata',
  facilities text[] not null default '{}',
  status text not null default 'pending'
    check (status in ('pending', 'active', 'hidden')),
  -- OSM ids are unique per element type, so keep the type: 'node/123', 'way/45'.
  osm_id text unique,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create index masjids_location_gist on public.masjids using gist (location);
create index masjids_status_idx on public.masjids (status);
create index masjids_created_by_idx on public.masjids (created_by);

alter table public.masjids enable row level security;

create policy masjids_select_active
  on public.masjids for select
  to anon, authenticated
  using (status = 'active');
