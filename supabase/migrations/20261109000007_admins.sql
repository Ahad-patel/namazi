-- Phase 3a: masjid admin claims + proof photos, verified-time writes with
-- history, admin inbox, super-admin moderation and its log.
-- Every write here goes through a role-checked RPC acting on one id. No
-- client update/delete policies.

-- ---------------------------------------------------------------------------
-- Role helpers
-- ---------------------------------------------------------------------------

create function app.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select p.role = 'super_admin' and not p.is_banned
       from public.profiles p where p.id = (select auth.uid())),
    false
  )
$$;

-- ---------------------------------------------------------------------------
-- masjid_admins (claims)
-- ---------------------------------------------------------------------------

create table public.masjid_admins (
  id uuid primary key default gen_random_uuid(),
  masjid_id uuid not null references public.masjids (id) on delete restrict,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'revoked')),
  role_at_masjid text not null check (role_at_masjid in ('imam', 'mutawalli', 'committee')),
  -- Phone and proof are purged 90 days after the decision (purge-claims).
  phone text check (phone ~ '^\+?[0-9]{8,15}$'),
  proof_path text check (char_length(proof_path) <= 200),
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  reason text check (char_length(reason) <= 300),
  created_at timestamptz not null default now()
);

create index masjid_admins_user_status_idx on public.masjid_admins (user_id, status);
create index masjid_admins_masjid_status_idx on public.masjid_admins (masjid_id, status);
create index masjid_admins_status_created_idx on public.masjid_admins (status, created_at);
create index masjid_admins_reviewed_by_idx on public.masjid_admins (reviewed_by);
-- One live claim per user and masjid.
create unique index masjid_admins_one_live_idx
  on public.masjid_admins (masjid_id, user_id)
  where status in ('pending', 'approved');

alter table public.masjid_admins enable row level security;

create function app.is_masjid_admin(p_masjid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.masjid_admins a
    join public.profiles p on p.id = a.user_id
    where a.masjid_id = p_masjid
      and a.user_id = (select auth.uid())
      and a.status = 'approved'
      and not p.is_banned
  )
$$;

-- Approved admin of this masjid, or super admin.
create function app.can_manage(p_masjid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.is_super_admin() or app.is_masjid_admin(p_masjid)
$$;

revoke all on function app.is_super_admin(), app.is_masjid_admin(uuid), app.can_manage(uuid) from public;
grant execute on function app.is_super_admin(), app.is_masjid_admin(uuid), app.can_manage(uuid)
  to anon, authenticated;

create policy masjid_admins_select_own_or_super_admin
  on public.masjid_admins for select
  to authenticated
  using (user_id = (select auth.uid()) or (select app.is_super_admin()));

create policy masjid_admins_insert_claim
  on public.masjid_admins for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'pending'
    and phone is not null
    and reviewed_by is null
    and reviewed_at is null
    and reason is null
    and (proof_path is null or proof_path like (select auth.uid())::text || '/%')
    and (select app.can_contribute())
    and exists (
      select 1 from public.masjids m
      where m.id = masjid_admins.masjid_id and m.status = 'active'
    )
  );

-- At most 3 approved admins per masjid (PRD). SQLSTATE MT409.
create function app.check_admin_cap()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' and (
    select count(*) from public.masjid_admins a
    where a.masjid_id = new.masjid_id and a.status = 'approved'
  ) >= 3 then
    raise exception 'masjid already has 3 approved admins' using errcode = 'MT409';
  end if;
  return new;
end;
$$;

revoke all on function app.check_admin_cap() from public, anon, authenticated;

create trigger masjid_admins_cap
  before update on public.masjid_admins
  for each row execute function app.check_admin_cap();

-- ---------------------------------------------------------------------------
-- Storage: claim-proofs (private, write-once)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('claim-proofs', 'claim-proofs', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

-- Insert only into your own folder (`<user_id>/<claim_id>.jpg`). No update
-- or delete policy: a new claim gets a new path.
create policy claim_proofs_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'claim-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select app.can_contribute())
  );

create policy claim_proofs_select_own_or_super_admin
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'claim-proofs'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select app.is_super_admin())
    )
  );

-- What the detail page needs: can I manage this masjid, and my latest claim.
create function public.masjid_access(masjid_id uuid)
returns table (can_manage boolean, claim_status text)
language sql
stable
set search_path = ''
as $$
  select
    app.can_manage(masjid_access.masjid_id),
    (
      select a.status from public.masjid_admins a
      where a.masjid_id = masjid_access.masjid_id and a.user_id = (select auth.uid())
      order by a.created_at desc
      limit 1
    )
$$;

-- ---------------------------------------------------------------------------
-- Moderation log (trigger-written, super admin read-only)
-- ---------------------------------------------------------------------------

create table public.moderation_log (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id) on delete set null,
  action text not null,
  target_table text not null,
  target_id uuid not null,
  before jsonb,
  after jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index moderation_log_created_idx on public.moderation_log (created_at desc);
create index moderation_log_actor_idx on public.moderation_log (actor_id);

alter table public.moderation_log enable row level security;

create policy moderation_log_select_super_admin
  on public.moderation_log for select
  to authenticated
  using ((select app.is_super_admin()));

-- Moderation RPCs call this first; the trigger below logs only rows changed
-- while it is set (transaction-local), so a user's own supersede is not logged.
create function app.begin_moderation(p_action text, p_reason text)
returns void
language sql
set search_path = ''
as $$
  select set_config('app.action', p_action, true), set_config('app.reason', coalesce(p_reason, ''), true)
$$;

-- Phone and proof path never go into the log.
create function app.log_moderation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action text := nullif(current_setting('app.action', true), '');
begin
  if v_action is null or tg_op <> 'UPDATE' then
    return null;
  end if;
  insert into public.moderation_log (actor_id, action, target_table, target_id, before, after, reason)
  values (
    (select auth.uid()),
    v_action,
    tg_table_name,
    new.id,
    to_jsonb(old) - array['phone', 'proof_path', 'location'],
    to_jsonb(new) - array['phone', 'proof_path', 'location'],
    nullif(current_setting('app.reason', true), '')
  );
  return null;
end;
$$;

revoke all on function app.begin_moderation(text, text), app.log_moderation() from public, anon, authenticated;

create trigger masjid_admins_log after update on public.masjid_admins
  for each row execute function app.log_moderation();
create trigger masjids_log after update on public.masjids
  for each row execute function app.log_moderation();
create trigger time_suggestions_log after update on public.time_suggestions
  for each row execute function app.log_moderation();
create trigger profiles_log after update on public.profiles
  for each row execute function app.log_moderation();

-- ---------------------------------------------------------------------------
-- Verified times: write RPC + history
-- ---------------------------------------------------------------------------

create table public.jamat_time_history (
  id bigint generated always as identity primary key,
  jamat_time_id uuid not null,
  masjid_id uuid not null references public.masjids (id) on delete restrict,
  prayer public.prayer not null,
  azaan_time time,
  jamat_time time not null,
  valid_from date not null,
  updated_by uuid,
  updated_at timestamptz not null,
  op text not null check (op in ('INSERT', 'UPDATE', 'DELETE')),
  changed_at timestamptz not null default now(),
  changed_by uuid
);

create index jamat_time_history_masjid_idx on public.jamat_time_history (masjid_id, changed_at desc);

alter table public.jamat_time_history enable row level security;

create policy jamat_time_history_select_managers
  on public.jamat_time_history for select
  to authenticated
  using ((select app.can_manage(jamat_time_history.masjid_id)));

-- NEW is unassigned on DELETE, so branch on tg_op.
create function app.log_jamat_time()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.jamat_times;
begin
  if tg_op = 'DELETE' then
    r := old;
  else
    r := new;
  end if;
  insert into public.jamat_time_history
    (jamat_time_id, masjid_id, prayer, azaan_time, jamat_time, valid_from, updated_by, updated_at, op, changed_by)
  values
    (r.id, r.masjid_id, r.prayer, r.azaan_time, r.jamat_time, r.valid_from, r.updated_by, r.updated_at, tg_op, (select auth.uid()));
  return null;
end;
$$;

revoke all on function app.log_jamat_time() from public, anon, authenticated;

create trigger jamat_times_history
  after insert or update or delete on public.jamat_times
  for each row execute function app.log_jamat_time();

-- Admin sets azaan + jamat for one namaz from `valid_from` (default: the
-- masjid's local today; never in the past). Same window rule as suggestions.
create function public.set_jamat_time(
  masjid_id uuid,
  prayer public.prayer,
  jamat_time time,
  azaan_time time default null,
  valid_from date default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_tz text;
  v_lat double precision;
  v_lng double precision;
  v_today date;
  v_from date;
  w record;
begin
  if not app.can_manage(set_jamat_time.masjid_id) then
    raise exception 'not an admin of this masjid' using errcode = '42501';
  end if;
  select m.timezone,
         extensions.st_y(m.location::extensions.geometry),
         extensions.st_x(m.location::extensions.geometry)
    into v_tz, v_lat, v_lng
  from public.masjids m
  where m.id = set_jamat_time.masjid_id and m.status = 'active';
  if v_tz is null then
    raise exception 'masjid not found' using errcode = 'P0002';
  end if;

  v_today := (now() at time zone v_tz)::date;
  v_from := coalesce(set_jamat_time.valid_from, v_today);
  if v_from < v_today then
    raise exception 'valid_from is in the past' using errcode = '22023';
  end if;

  select x.starts, x.ends into w
  from app.prayer_window(set_jamat_time.prayer, v_lat, v_lng, v_tz, v_from) x;
  if not app.in_window(set_jamat_time.jamat_time, w.starts, w.ends)
     or not app.in_window(set_jamat_time.azaan_time, w.starts, w.ends) then
    raise exception 'time outside the % window (% - %)', set_jamat_time.prayer, w.starts, w.ends
      using errcode = 'MT422';
  end if;

  insert into public.jamat_times (masjid_id, prayer, azaan_time, jamat_time, valid_from, updated_by, updated_at)
  values (set_jamat_time.masjid_id, set_jamat_time.prayer, set_jamat_time.azaan_time,
          set_jamat_time.jamat_time, v_from, (select auth.uid()), now())
  on conflict on constraint jamat_times_masjid_id_prayer_valid_from_key do update
    set azaan_time = excluded.azaan_time,
        jamat_time = excluded.jamat_time,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.set_jamat_time(uuid, public.prayer, time, time, date) from public, anon;
grant execute on function public.set_jamat_time(uuid, public.prayer, time, time, date) to authenticated;

-- ---------------------------------------------------------------------------
-- Admin inbox: open suggestions that differ from the verified time
-- ---------------------------------------------------------------------------

create function public.admin_inbox(masjid_id uuid)
returns table (
  id uuid,
  prayer public.prayer,
  azaan_time time,
  jamat_time time,
  note text,
  net_votes integer,
  created_at timestamptz,
  verified_jamat_time time
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not app.can_manage(admin_inbox.masjid_id) then
    raise exception 'not an admin of this masjid' using errcode = '42501';
  end if;
  return query
  select s.id, s.prayer, s.azaan_time, s.jamat_time, s.note, s.net_votes, s.created_at, t.jamat_time
  from public.time_suggestions s
  left join public.masjid_times(admin_inbox.masjid_id) t
    on t.prayer = s.prayer and t.source = 'verified'
  where s.masjid_id = admin_inbox.masjid_id
    and s.status = 'open'
    and s.jamat_time is distinct from t.jamat_time
  order by s.net_votes desc, s.created_at desc;
end;
$$;

revoke all on function public.admin_inbox(uuid) from public, anon;
grant execute on function public.admin_inbox(uuid) to authenticated;

-- Accept: becomes the verified time from the masjid's today.
create function public.accept_suggestion(suggestion_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.time_suggestions;
begin
  select * into s from public.time_suggestions x
  where x.id = accept_suggestion.suggestion_id and x.status = 'open';
  if s.id is null then
    raise exception 'suggestion not open' using errcode = 'P0002';
  end if;
  if not app.can_manage(s.masjid_id) then
    raise exception 'not an admin of this masjid' using errcode = '42501';
  end if;
  perform public.set_jamat_time(s.masjid_id, s.prayer, s.jamat_time, s.azaan_time, null);
  perform app.begin_moderation('accept_suggestion', null);
  update public.time_suggestions set status = 'accepted' where id = s.id;
end;
$$;

create function public.reject_suggestion(suggestion_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_masjid uuid;
begin
  select x.masjid_id into v_masjid from public.time_suggestions x
  where x.id = reject_suggestion.suggestion_id and x.status = 'open';
  if v_masjid is null then
    raise exception 'suggestion not open' using errcode = 'P0002';
  end if;
  if not app.can_manage(v_masjid) then
    raise exception 'not an admin of this masjid' using errcode = '42501';
  end if;
  perform app.begin_moderation('reject_suggestion', reject_suggestion.reason);
  update public.time_suggestions set status = 'rejected'
  where id = reject_suggestion.suggestion_id;
end;
$$;

revoke all on function public.accept_suggestion(uuid), public.reject_suggestion(uuid, text) from public, anon;
grant execute on function public.accept_suggestion(uuid), public.reject_suggestion(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Super admin: queues (read) and one-id actions (write)
-- ---------------------------------------------------------------------------

create function app.require_super_admin()
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if not app.is_super_admin() then
    raise exception 'super admin only' using errcode = '42501';
  end if;
end;
$$;

revoke all on function app.require_super_admin() from public, anon;
grant execute on function app.require_super_admin() to authenticated;

-- Queue filters + sorts below.
create index time_suggestions_status_created_idx
  on public.time_suggestions (status, created_at desc);
create index profiles_banned_idx on public.profiles (display_name) where is_banned;

-- Claims by status (pending queue, approved = admins list). Paginate with
-- .range(): 25 per page.
create function public.claims_by_status(p_status text)
returns table (
  id uuid,
  masjid_id uuid,
  masjid_name text,
  masjid_slug text,
  user_name text,
  role_at_masjid text,
  phone text,
  proof_path text,
  reason text,
  created_at timestamptz,
  reviewed_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select a.id, a.masjid_id, m.name, m.slug, p.display_name, a.role_at_masjid, a.phone,
         a.proof_path, a.reason, a.created_at, a.reviewed_at
  from public.masjid_admins a
  join public.masjids m on m.id = a.masjid_id
  join public.profiles p on p.id = a.user_id
  where a.status = p_status
  order by a.created_at;
end;
$$;

-- Masjids by status (pending queue, active to hide, hidden to restore), with
-- lat/lng for the map link. p_query filters by name.
create function public.masjids_by_status(p_status text, p_query text default null)
returns table (
  id uuid,
  slug text,
  name text,
  name_local text,
  name_script text,
  latitude double precision,
  longitude double precision,
  created_by_name text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select m.id, m.slug, m.name, m.name_local, m.name_script,
         extensions.st_y(m.location::extensions.geometry),
         extensions.st_x(m.location::extensions.geometry),
         p.display_name, m.created_at
  from public.masjids m
  left join public.profiles p on p.id = m.created_by
  where m.status = p_status
    and (p_query is null or m.name ilike '%' || p_query || '%' or m.name_local ilike '%' || p_query || '%')
  order by m.created_at desc;
end;
$$;

create function public.hidden_suggestions()
returns table (
  id uuid,
  masjid_name text,
  prayer public.prayer,
  jamat_time time,
  note text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select s.id, m.name, s.prayer, s.jamat_time, s.note, s.created_at
  from public.time_suggestions s
  join public.masjids m on m.id = s.masjid_id
  where s.status = 'hidden'
  order by s.created_at desc;
end;
$$;

-- Recent open suggestions everywhere (to hide one, or ban its author).
create function public.open_suggestions()
returns table (
  id uuid,
  masjid_name text,
  prayer public.prayer,
  jamat_time time,
  note text,
  net_votes integer,
  author_name text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select s.id, m.name, s.prayer, s.jamat_time, s.note, s.net_votes, p.display_name, s.created_at
  from public.time_suggestions s
  join public.masjids m on m.id = s.masjid_id
  left join public.profiles p on p.id = s.suggested_by
  where s.status = 'open'
  order by s.created_at desc;
end;
$$;

create function public.banned_users()
returns table (id uuid, display_name text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select p.id, p.display_name, p.created_at
  from public.profiles p
  where p.is_banned
  order by p.display_name;
end;
$$;

-- Ban preview: who wrote this suggestion and how many open ones they have.
create function public.suggestion_author(suggestion_id uuid)
returns table (display_name text, open_count integer, is_banned boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  return query
  select p.display_name,
         (select count(*)::integer from public.time_suggestions o
          where o.suggested_by = p.id and o.status = 'open'),
         p.is_banned
  from public.time_suggestions s
  join public.profiles p on p.id = s.suggested_by
  where s.id = suggestion_author.suggestion_id;
end;
$$;

create function public.review_claim(claim_id uuid, approve boolean, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  perform app.begin_moderation(case when approve then 'approve_claim' else 'reject_claim' end, review_claim.reason);
  update public.masjid_admins a
     set status = case when review_claim.approve then 'approved' else 'rejected' end,
         reviewed_by = (select auth.uid()),
         reviewed_at = now(),
         reason = review_claim.reason
   where a.id = review_claim.claim_id and a.status = 'pending';
  if not found then
    raise exception 'claim not pending' using errcode = 'P0002';
  end if;
end;
$$;

create function public.revoke_admin(claim_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  perform app.begin_moderation('revoke_admin', revoke_admin.reason);
  update public.masjid_admins a
     set status = 'revoked', reviewed_by = (select auth.uid()), reviewed_at = now(),
         reason = revoke_admin.reason
   where a.id = revoke_admin.claim_id and a.status = 'approved';
  if not found then
    raise exception 'not an approved admin' using errcode = 'P0002';
  end if;
end;
$$;

-- One masjid status change: pending→active (approve), pending→hidden
-- (reject), active→hidden (hide), hidden→active (restore).
create function public.set_masjid_status(masjid_id uuid, status text, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_old text;
begin
  perform app.require_super_admin();
  select m.status into v_old from public.masjids m where m.id = set_masjid_status.masjid_id;
  if v_old is null then
    raise exception 'masjid not found' using errcode = 'P0002';
  end if;
  if not (v_old, set_masjid_status.status) in (
    ('pending', 'active'), ('pending', 'hidden'), ('active', 'hidden'), ('hidden', 'active')
  ) then
    raise exception 'cannot move masjid from % to %', v_old, set_masjid_status.status
      using errcode = '22023';
  end if;
  perform app.begin_moderation(
    case
      when v_old = 'pending' and set_masjid_status.status = 'active' then 'approve_masjid'
      when v_old = 'pending' then 'reject_masjid'
      when set_masjid_status.status = 'hidden' then 'hide_masjid'
      else 'restore_masjid'
    end,
    set_masjid_status.reason
  );
  update public.masjids set status = set_masjid_status.status
  where id = set_masjid_status.masjid_id;
end;
$$;

create function public.hide_suggestion(suggestion_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  perform app.begin_moderation('hide_suggestion', hide_suggestion.reason);
  update public.time_suggestions s set status = 'hidden'
  where s.id = hide_suggestion.suggestion_id and s.status = 'open';
  if not found then
    raise exception 'suggestion not open' using errcode = 'P0002';
  end if;
end;
$$;

-- Back to open, unless the author has posted a newer one for that namaz
-- since; then it is archived (superseded) instead.
create function public.restore_suggestion(suggestion_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.time_suggestions;
begin
  perform app.require_super_admin();
  select * into s from public.time_suggestions x
  where x.id = restore_suggestion.suggestion_id and x.status = 'hidden';
  if s.id is null then
    raise exception 'suggestion not hidden' using errcode = 'P0002';
  end if;
  perform app.begin_moderation('restore_suggestion', null);
  update public.time_suggestions x
     set status = case when exists (
       select 1 from public.time_suggestions o
       where o.masjid_id = s.masjid_id and o.prayer = s.prayer
         and o.suggested_by = s.suggested_by and o.status = 'open'
     ) then 'superseded' else 'open' end
   where x.id = s.id;
end;
$$;

-- Ban the author of a suggestion and hide their open suggestions. Bulk part
-- caps at 50 rows server side (CHECKLISTS §1).
create function public.ban_suggestion_author(suggestion_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid;
begin
  perform app.require_super_admin();
  select s.suggested_by into v_user from public.time_suggestions s
  where s.id = ban_suggestion_author.suggestion_id;
  if v_user is null then
    raise exception 'author not found' using errcode = 'P0002';
  end if;
  if v_user = (select auth.uid()) then
    raise exception 'cannot ban yourself' using errcode = '22023';
  end if;
  if (select count(*) from public.time_suggestions o
      where o.suggested_by = v_user and o.status = 'open') > 50 then
    raise exception 'more than 50 open suggestions; hide them one by one'
      using errcode = 'MT409';
  end if;
  perform app.begin_moderation('ban_user', ban_suggestion_author.reason);
  update public.profiles set is_banned = true where id = v_user;
  update public.time_suggestions set status = 'hidden'
  where suggested_by = v_user and status = 'open';
end;
$$;

create function public.unban_user(user_id uuid, reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform app.require_super_admin();
  perform app.begin_moderation('unban_user', unban_user.reason);
  update public.profiles p set is_banned = false
  where p.id = unban_user.user_id and p.is_banned;
  if not found then
    raise exception 'user not banned' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function
  public.claims_by_status(text), public.masjids_by_status(text, text), public.hidden_suggestions(),
  public.open_suggestions(),
  public.banned_users(), public.suggestion_author(uuid),
  public.review_claim(uuid, boolean, text), public.revoke_admin(uuid, text),
  public.set_masjid_status(uuid, text, text), public.hide_suggestion(uuid, text),
  public.restore_suggestion(uuid), public.ban_suggestion_author(uuid, text),
  public.unban_user(uuid, text)
  from public, anon;
grant execute on function
  public.claims_by_status(text), public.masjids_by_status(text, text), public.hidden_suggestions(),
  public.open_suggestions(),
  public.banned_users(), public.suggestion_author(uuid),
  public.review_claim(uuid, boolean, text), public.revoke_admin(uuid, text),
  public.set_masjid_status(uuid, text, text), public.hide_suggestion(uuid, text),
  public.restore_suggestion(uuid), public.ban_suggestion_author(uuid, text),
  public.unban_user(uuid, text)
  to authenticated;
