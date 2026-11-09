#!/usr/bin/env bash
# Vercel git builds (vercel.json buildCommand). Vercel's image has no
# Flutter, so fetch the pinned SDK, write env.json from the project's
# environment variables, and build. Same Flutter version as the dev Mac.
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER_VERSION=3.47.7

missing=()
for k in SUPABASE_URL SUPABASE_ANON_KEY MAPTILER_KEY TERMS_VERSION; do
  [ -n "${!k:-}" ] || missing+=("$k")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "FAIL: Vercel environment variables not set: ${missing[*]}" >&2
  exit 1
fi

if [ ! -x .flutter/bin/flutter ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git .flutter
fi
export PATH="$PWD/.flutter/bin:$PATH"
flutter --version
flutter config --no-analytics >/dev/null

# Public build-time config only (anon + MapTiler keys are public by design).
python3 - <<PY
import json, os
json.dump({
  "APP_ENV": os.environ.get("APP_ENV", "prod"),
  "SUPABASE_URL": os.environ["SUPABASE_URL"],
  "SUPABASE_ANON_KEY": os.environ["SUPABASE_ANON_KEY"],
  "MAPTILER_KEY": os.environ["MAPTILER_KEY"],
  "SENTRY_DSN": os.environ.get("SENTRY_DSN", ""),
  "TERMS_VERSION": os.environ["TERMS_VERSION"],
  "SITE_URL": os.environ.get("SITE_URL", ""),
}, open("env.json", "w"))
PY

flutter pub get
flutter build web --release --dart-define-from-file=env.json
rm -f env.json
