#!/usr/bin/env bash
# Everything CI runs. Must pass before a task is done.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> destructive-migration guard'
fail=0
for f in supabase/migrations/*.sql; do
  [ -e "$f" ] || continue
  if grep -qiE '^[^-]*(^|[^a-z_])(drop|truncate)([^a-z_]|$)' "$f" && ! head -n 1 "$f" | grep -q -- '-- destructive:'; then
    echo "FAIL: $f drops/truncates without a '-- destructive: <reason>' first line"
    fail=1
  fi
done
[ "$fail" -eq 0 ]

echo '==> flutter pub get + gen-l10n'
flutter pub get >/dev/null
flutter gen-l10n

echo '==> dart format'
dart format --set-exit-if-changed lib test

echo '==> flutter analyze'
flutter analyze

echo '==> flutter test'
flutter test

echo '==> SQL tests'
if command -v supabase >/dev/null 2>&1; then
  supabase test db
else
  echo '*******************************************************'
  echo '*  SKIPPED: SQL tests (supabase CLI missing).          *'
  echo '*  Install it and run `supabase start` to run pgTAP.   *'
  echo '*******************************************************'
fi

echo '==> check.sh passed'
