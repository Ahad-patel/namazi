-- destructive: drops public.masjid_times(uuid) only to recreate it with the trust-rule columns (return type changed); no data is dropped.
-- Phase 2: consent, community time suggestions, votes, full trust rules in
-- masjid_times, add a missing masjid.

-- ---------------------------------------------------------------------------
-- Consent + contributor check
-- ---------------------------------------------------------------------------

-- True when the caller may suggest, vote or add: signed in, not banned, said
-- they are 18+ and accepted the terms. The client re-asks when TERMS_VERSION
-- changes; the server only needs to know consent was given.
create function app.can_contribute()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select not p.is_banned and p.is_adult and p.terms_accepted_at is not null
      from public.profiles p
      where p.id = (select auth.uid())
    ),
    false
  )
$$;

revoke all on function app.can_contribute() from public;
grant execute on function app.can_contribute() to anon, authenticated;

-- First sign-in consent: "I am 18 or older" + "I agree to the Terms".
create function public.accept_terms(version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  if version is null or char_length(version) not between 1 and 32 then
    raise exception 'invalid terms version' using errcode = '22023';
  end if;
  update public.profiles
     set is_adult = true,
         terms_version = accept_terms.version,
         terms_accepted_at = now()
   where id = (select auth.uid());
end;
$$;

revoke all on function public.accept_terms(text) from public, anon;
grant execute on function public.accept_terms(text) to authenticated;

-- ---------------------------------------------------------------------------
-- time_suggestions
-- ---------------------------------------------------------------------------

create table public.time_suggestions (
  id uuid primary key default gen_random_uuid(),
  masjid_id uuid not null references public.masjids (id) on delete restrict,
  prayer public.prayer not null,
  azaan_time time,
  jamat_time time not null,
  note text check (char_length(note) <= 200),
  -- null after account deletion (anonymised, not deleted).
  suggested_by uuid default auth.uid() references public.profiles (id) on delete set null,
  status text not null default 'open'
    check (status in ('open', 'accepted', 'rejected', 'superseded', 'hidden')),
  -- Maintained by the suggestion_votes trigger only.
  net_votes integer not null default 0,
  created_at timestamptz not null default now(),
  check (azaan_time is null or azaan_time <= jamat_time)
);

create index time_suggestions_masjid_prayer_status_idx
  on public.time_suggestions (masjid_id, prayer, status);
-- 10-a-day trigger.
create index time_suggestions_suggested_by_created_idx
  on public.time_suggestions (suggested_by, created_at);
-- One active suggestion per user, masjid and namaz.
create unique index time_suggestions_one_open_idx
  on public.time_suggestions (masjid_id, prayer, suggested_by)
  where status = 'open';

alter table public.time_suggestions enable row level security;

create policy time_suggestions_select_open
  on public.time_suggestions for select
  to anon, authenticated
  using (
    status = 'open'
    and exists (
      select 1 from public.masjids m
      where m.id = time_suggestions.masjid_id and m.status = 'active'
    )
  );

create policy time_suggestions_insert_contributor
  on public.time_suggestions for insert
  to authenticated
  with check (
    suggested_by = (select auth.uid())
    and status = 'open'
    and net_votes = 0
    and (select app.can_contribute())
    and exists (
      select 1 from public.masjids m
      where m.id = time_suggestions.masjid_id and m.status = 'active'
    )
  );

-- No update or delete policy: status changes go through role-checked RPCs
-- (Phase 3) and the triggers below.

-- Abuse limit + "a new one replaces their old one". security definer because
-- the caller has no update right on their old row. RLS WITH CHECK runs after
-- this trigger; if it fails, the supersede rolls back with the insert.
create function app.before_suggestion_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (
    select count(*)
    from public.time_suggestions s
    where s.suggested_by = new.suggested_by
      and s.created_at > now() - interval '1 day'
  ) >= 10 then
    raise exception 'daily suggestion limit reached' using errcode = 'MT429';
  end if;

  update public.time_suggestions s
     set status = 'superseded'
   where s.masjid_id = new.masjid_id
     and s.prayer = new.prayer
     and s.suggested_by = new.suggested_by
     and s.status = 'open';
  return new;
end;
$$;

revoke all on function app.before_suggestion_insert() from public, anon, authenticated;

create trigger time_suggestions_before_insert
  before insert on public.time_suggestions
  for each row execute function app.before_suggestion_insert();

-- ---------------------------------------------------------------------------
-- suggestion_votes
-- ---------------------------------------------------------------------------

create table public.suggestion_votes (
  suggestion_id uuid not null references public.time_suggestions (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  value smallint not null check (value in (-1, 1)),
  created_at timestamptz not null default now(),
  primary key (suggestion_id, user_id)
);

create index suggestion_votes_user_idx on public.suggestion_votes (user_id);

alter table public.suggestion_votes enable row level security;

create policy suggestion_votes_select_own
  on public.suggestion_votes for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Vote on someone else's open suggestion only. The exists() reads
-- time_suggestions under its own RLS, so only open rows of active masjids.
create policy suggestion_votes_insert_contributor
  on public.suggestion_votes for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and (select app.can_contribute())
    and exists (
      select 1 from public.time_suggestions s
      where s.id = suggestion_votes.suggestion_id
        and s.suggested_by is distinct from (select auth.uid())
    )
  );

create policy suggestion_votes_update_own
  on public.suggestion_votes for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (select app.can_contribute())
    and exists (
      select 1 from public.time_suggestions s
      where s.id = suggestion_votes.suggestion_id
        and s.suggested_by is distinct from (select auth.uid())
    )
  );

-- The only client delete policy in the schema: removing your own vote.
create policy suggestion_votes_delete_own
  on public.suggestion_votes for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Recount instead of +/- deltas, so an update that moves a vote stays correct.
create function app.sync_net_votes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[];
begin
  if tg_op = 'INSERT' then
    v_ids := array[new.suggestion_id];
  elsif tg_op = 'DELETE' then
    v_ids := array[old.suggestion_id];
  else
    v_ids := array[old.suggestion_id, new.suggestion_id];
  end if;

  update public.time_suggestions s
     set net_votes = (
       select coalesce(sum(v.value), 0)::integer
       from public.suggestion_votes v
       where v.suggestion_id = s.id
     )
   where s.id = any (v_ids);
  return null;
end;
$$;

revoke all on function app.sync_net_votes() from public, anon, authenticated;

create trigger suggestion_votes_sync_net_votes
  after insert or update or delete on public.suggestion_votes
  for each row execute function app.sync_net_votes();

-- Open suggestions of one masjid, with the caller's own state. Capped at 50
-- (at most one open row per user and namaz).
-- ponytail: hard cap of 50; switch to .range() pages if a masjid ever gets
-- more open suggestions than that.
create function public.masjid_suggestions(masjid_id uuid)
returns table (
  id uuid,
  prayer public.prayer,
  azaan_time time,
  jamat_time time,
  note text,
  net_votes integer,
  created_at timestamptz,
  is_mine boolean,
  my_vote smallint
)
language sql
stable
set search_path = ''
as $$
  select
    s.id,
    s.prayer,
    s.azaan_time,
    s.jamat_time,
    s.note,
    s.net_votes,
    s.created_at,
    coalesce(s.suggested_by = (select auth.uid()), false),
    (
      select v.value from public.suggestion_votes v
      where v.suggestion_id = s.id and v.user_id = (select auth.uid())
    )
  from public.time_suggestions s
  where s.masjid_id = masjid_suggestions.masjid_id
    and s.status = 'open'
  order by s.prayer, s.net_votes desc, s.created_at desc
  limit 50
$$;

-- ---------------------------------------------------------------------------
-- masjid_times with the PRD trust rules
-- ---------------------------------------------------------------------------
-- 1. Verified time (latest valid_from on or before local today) wins.
-- 2. Otherwise the top open suggestion with net_votes >= 2 (ties: newest).
-- 3. Otherwise no row ("Not available — suggest a time").
-- differing_reports: open suggestions whose jamat differs from the verified
--   time, reported only when >= 2 (else 0).
-- stale: verified time not updated for 120 days; then the community_* columns
--   carry the top community suggestion (if it differs).
-- language sql without BEGIN ATOMIC, so app.masjids_within (which calls this)
-- is not a tracked dependency and keeps working after the recreate.

drop function public.masjid_times(uuid);

create function public.masjid_times(masjid_id uuid)
returns table (
  prayer public.prayer,
  azaan_time time,
  jamat_time time,
  source text,
  updated_at timestamptz,
  next_at timestamptz,
  net_votes integer,
  differing_reports integer,
  stale boolean,
  community_azaan_time time,
  community_jamat_time time,
  community_net_votes integer
)
language sql
stable
set search_path = ''
as $$
  with m as (
    select x.id, x.timezone
    from public.masjids x
    where x.id = masjid_times.masjid_id
  ),
  verified as (
    select distinct on (t.prayer) t.prayer, t.azaan_time, t.jamat_time, t.updated_at
    from public.jamat_times t
    join m on m.id = t.masjid_id
    where t.valid_from <= (now() at time zone m.timezone)::date
    order by t.prayer, t.valid_from desc
  ),
  top_community as (
    select distinct on (s.prayer)
      s.prayer, s.azaan_time, s.jamat_time, s.created_at, s.net_votes
    from public.time_suggestions s
    join m on m.id = s.masjid_id
    where s.status = 'open' and s.net_votes >= 2
    order by s.prayer, s.net_votes desc, s.created_at desc
  ),
  shown as (
    select
      v.prayer, v.azaan_time, v.jamat_time, 'verified'::text as source,
      v.updated_at, null::integer as net_votes,
      v.updated_at < now() - interval '120 days' as stale
    from verified v
    union all
    select
      c.prayer, c.azaan_time, c.jamat_time, 'community'::text,
      c.created_at, c.net_votes, false
    from top_community c
    where not exists (select 1 from verified v where v.prayer = c.prayer)
  ),
  differing as (
    select s.prayer, count(*)::integer as n
    from public.time_suggestions s
    join m on m.id = s.masjid_id
    join verified v on v.prayer = s.prayer
    where s.status = 'open' and s.jamat_time <> v.jamat_time
    group by s.prayer
  )
  select
    sh.prayer,
    sh.azaan_time,
    sh.jamat_time,
    sh.source,
    sh.updated_at,
    app.next_occurrence(
      sh.prayer,
      sh.jamat_time,
      m.timezone,
      exists (select 1 from shown j where j.prayer = 'jummah')
    ),
    sh.net_votes,
    case when coalesce(d.n, 0) >= 2 then d.n else 0 end,
    sh.stale,
    c.azaan_time,
    c.jamat_time,
    c.net_votes
  from shown sh
  cross join m
  left join differing d on d.prayer = sh.prayer
  left join top_community c
    on c.prayer = sh.prayer and sh.stale and c.jamat_time <> sh.jamat_time
  order by sh.prayer
$$;

-- ---------------------------------------------------------------------------
-- Add a missing masjid (hidden until a super admin approves it)
-- ---------------------------------------------------------------------------

alter table public.masjids alter column created_by set default auth.uid();

create policy masjids_insert_pending
  on public.masjids for insert
  to authenticated
  with check (
    status = 'pending'
    and created_by = (select auth.uid())
    and osm_id is null
    and (select app.can_contribute())
  );

-- Builds the slug and the geography server side. security invoker, so the
-- insert policy above applies. The pin is the masjid's location, never the
-- user's own position.
-- ponytail: no per-user cap on pending masjids (they stay hidden until
-- reviewed); add a daily cap like the suggestions trigger if the queue is spammed.
create function public.add_masjid(
  name text,
  lat double precision,
  lng double precision,
  name_local text default null,
  name_script text default null
)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_id uuid := gen_random_uuid();
  v_base text;
begin
  if lat not between -90 and 90 or lng not between -180 and 180 then
    raise exception 'invalid location' using errcode = '22023';
  end if;
  v_base := trim(both '-' from left(
    trim(both '-' from regexp_replace(lower(add_masjid.name), '[^a-z0-9]+', '-', 'g')),
    60
  ));
  if v_base = '' then
    v_base := 'masjid';
  end if;

  insert into public.masjids (id, slug, name, name_local, name_script, location, status, created_by)
  values (
    v_id,
    v_base || '-' || left(replace(v_id::text, '-', ''), 6),
    trim(add_masjid.name),
    nullif(trim(add_masjid.name_local), ''),
    add_masjid.name_script,
    extensions.st_setsrid(extensions.st_makepoint(add_masjid.lng, add_masjid.lat), 4326)::extensions.geography,
    'pending',
    (select auth.uid())
  );
  return v_id;
end;
$$;

revoke all on function public.add_masjid(text, double precision, double precision, text, text) from public, anon;
grant execute on function public.add_masjid(text, double precision, double precision, text, text) to authenticated;
