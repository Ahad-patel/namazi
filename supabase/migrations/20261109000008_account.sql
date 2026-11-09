-- Phase 3b: "Download my data" and the daily retention job.
-- Account deletion itself is the delete-account Edge Function (service role,
-- server side); the FKs already cascade profile, votes and claims and set
-- suggested_by / created_by to null, so community times survive anonymously.

-- ---------------------------------------------------------------------------
-- my_data(): everything we hold about the caller, as one JSON document.
-- Security definer so hidden/superseded suggestions are included too; it
-- only ever reads rows of auth.uid().
-- ---------------------------------------------------------------------------

create function public.my_data()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'sign in first' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'exported_at', now(),
    'profile', (
      select jsonb_build_object(
        'id', p.id, 'display_name', p.display_name, 'role', p.role,
        'is_banned', p.is_banned, 'is_adult', p.is_adult,
        'terms_version', p.terms_version, 'terms_accepted_at', p.terms_accepted_at,
        'created_at', p.created_at)
      from public.profiles p where p.id = v_uid
    ),
    'suggestions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id, 'masjid_id', s.masjid_id, 'prayer', s.prayer,
        'azaan_time', s.azaan_time, 'jamat_time', s.jamat_time, 'note', s.note,
        'status', s.status, 'net_votes', s.net_votes, 'created_at', s.created_at)
        order by s.created_at)
      from public.time_suggestions s where s.suggested_by = v_uid
    ), '[]'::jsonb),
    'votes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'suggestion_id', v.suggestion_id, 'value', v.value, 'created_at', v.created_at)
        order by v.created_at)
      from public.suggestion_votes v where v.user_id = v_uid
    ), '[]'::jsonb),
    'claims', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id, 'masjid_id', a.masjid_id, 'status', a.status,
        'role_at_masjid', a.role_at_masjid, 'phone', a.phone,
        'proof_path', a.proof_path, 'reason', a.reason,
        'created_at', a.created_at, 'reviewed_at', a.reviewed_at)
        order by a.created_at)
      from public.masjid_admins a where a.user_id = v_uid
    ), '[]'::jsonb),
    'masjids_added', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', m.id, 'name', m.name, 'status', m.status, 'created_at', m.created_at)
        order by m.created_at)
      from public.masjids m where m.created_by = v_uid
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.my_data() from public, anon;
grant execute on function public.my_data() to authenticated;

-- ---------------------------------------------------------------------------
-- Retention (purge-claims Edge Function), daily at 03:00 IST (21:30 UTC).
-- The function needs the Storage API to delete proof photos, hence HTTP and
-- not plain SQL. URL and shared secret live in Vault, never in git:
--   select vault.create_secret('https://<ref>.supabase.co', 'project_url');
--   select vault.create_secret('<random>', 'purge_secret');
-- and the same <random> as the function secret PURGE_SECRET.
-- ---------------------------------------------------------------------------

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- What the job deletes, also used by the function: claims decided 90+ days
-- ago that still hold a phone or photo.
create index masjid_admins_purge_idx on public.masjid_admins (reviewed_at)
  where phone is not null or proof_path is not null;
create index time_suggestions_superseded_idx on public.time_suggestions (created_at)
  where status = 'superseded';

select cron.schedule(
  'purge-claims',
  '30 21 * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/purge-claims',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'purge_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $job$
);
