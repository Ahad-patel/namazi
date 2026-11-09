#!/usr/bin/env bash
# After a migration reaches staging/prod: probe every table and RPC the app
# uses with the anon key. 200 (or 401/403: exists, but anon may not) passes;
# 404 / PGRST202 / PGRST205 (object never created) fails.
# Needs env.json (SUPABASE_URL, SUPABASE_ANON_KEY) or the same two env vars.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${SUPABASE_URL:-}" ] && [ -f env.json ]; then
  SUPABASE_URL=$(python3 -c 'import json;print(json.load(open("env.json"))["SUPABASE_URL"])')
  SUPABASE_ANON_KEY=$(python3 -c 'import json;print(json.load(open("env.json"))["SUPABASE_ANON_KEY"])')
fi
: "${SUPABASE_URL:?set SUPABASE_URL or provide env.json}"
: "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY or provide env.json}"

tables=(profiles masjids jamat_times time_suggestions suggestion_votes
  masjid_admins moderation_log jamat_time_history)
# rpc name + a JSON body with dummy (valid-typed) args
rpcs=(
  'nearby_masjids|{"lat":19.07,"lng":72.87,"radius_m":100}'
  'next_jamat_nearby|{"lat":19.07,"lng":72.87,"radius_m":100}'
  'masjid_by_slug|{"masjid_slug":"verify-remote-probe"}'
  'masjid_times|{"masjid_id":"00000000-0000-0000-0000-000000000000"}'
  'masjid_suggestions|{"masjid_id":"00000000-0000-0000-0000-000000000000"}'
  'prayer_windows|{"masjid_id":"00000000-0000-0000-0000-000000000000"}'
  'masjid_access|{"masjid_id":"00000000-0000-0000-0000-000000000000"}'
  'accept_terms|{"version":"probe"}'
  'add_masjid|{"name":"probe","lat":19.07,"lng":72.87}'
  'set_jamat_time|{"masjid_id":"00000000-0000-0000-0000-000000000000","prayer":"fajr","jamat_time":"05:00"}'
  'admin_inbox|{"masjid_id":"00000000-0000-0000-0000-000000000000"}'
  'accept_suggestion|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'reject_suggestion|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'claims_by_status|{"p_status":"pending"}'
  'masjids_by_status|{"p_status":"pending"}'
  'open_suggestions|{}'
  'hidden_suggestions|{}'
  'banned_users|{}'
  'suggestion_author|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'review_claim|{"claim_id":"00000000-0000-0000-0000-000000000000","approve":false}'
  'revoke_admin|{"claim_id":"00000000-0000-0000-0000-000000000000"}'
  'set_masjid_status|{"masjid_id":"00000000-0000-0000-0000-000000000000","status":"active"}'
  'hide_suggestion|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'restore_suggestion|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'ban_suggestion_author|{"suggestion_id":"00000000-0000-0000-0000-000000000000"}'
  'unban_user|{"user_id":"00000000-0000-0000-0000-000000000000"}'
  'my_data|{}'
)

fail=0
check() { # name status body
  local name=$1 code=$2 body=$3
  if [ "$code" = 404 ] || grep -qE 'PGRST20[25]' <<<"$body"; then
    echo "FAIL $name ($code) $(head -c 160 <<<"$body")"; fail=1
  else
    echo "ok   $name ($code)"
  fi
}

for t in "${tables[@]}"; do
  out=$(curl -sS -w '\n%{http_code}' "$SUPABASE_URL/rest/v1/$t?select=*&limit=0" \
    -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY")
  check "table $t" "$(tail -n1 <<<"$out")" "$(sed '$d' <<<"$out")"
done
for entry in "${rpcs[@]}"; do
  fn=${entry%%|*}; body=${entry#*|}
  out=$(curl -sS -w '\n%{http_code}' -X POST "$SUPABASE_URL/rest/v1/rpc/$fn" \
    -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H 'Content-Type: application/json' -d "$body")
  check "rpc $fn" "$(tail -n1 <<<"$out")" "$(sed '$d' <<<"$out")"
done
# Storage bucket and Edge Functions (401 without a user JWT = deployed).
out=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$SUPABASE_URL/functions/v1/delete-account" \
  -H "apikey: $SUPABASE_ANON_KEY")
check "function delete-account" "$out" ""
out=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$SUPABASE_URL/functions/v1/purge-claims")
check "function purge-claims" "$out" ""

[ "$fail" -eq 0 ] && echo "verify_remote: all objects exist" || { echo "verify_remote: FAILED" >&2; exit 1; }
