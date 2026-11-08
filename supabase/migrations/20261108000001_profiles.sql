-- Phase 1: PostGIS, helper schema, profiles + handle_new_user trigger.

create extension if not exists postgis with schema extensions;

-- Internal helpers live in `app` (not exposed through PostgREST).
create schema if not exists app;
grant usage on schema app to anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 80),
  role text not null default 'user' check (role in ('user', 'super_admin')),
  is_banned boolean not null default false,
  is_adult boolean not null default false,
  terms_version text,
  terms_accepted_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Role of the calling user, or null for anon. security definer so policies
-- can call it without recursing into profiles' own RLS.
create function public.app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.role from public.profiles p where p.id = (select auth.uid())
$$;

revoke all on function public.app_role() from public;
grant execute on function public.app_role() to anon, authenticated;

-- Read own row; super admin reads all. No client insert/update/delete:
-- rows come from the trigger, changes go through role-checked RPCs later.
create policy profiles_select_own_or_super_admin
  on public.profiles for select
  to authenticated
  using (id = (select auth.uid()) or (select public.app_role()) = 'super_admin');

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(
      coalesce(
        new.raw_user_meta_data ->> 'full_name',
        new.raw_user_meta_data ->> 'name',
        split_part(new.email, '@', 1)
      ),
      80
    )
  );
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
