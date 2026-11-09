#!/usr/bin/env bash
# Release builds. Run from the repo root with env.json present (Jenkins
# copies it from the masjid-env-<env> secret file and deletes it after).
#   web     flutter build web + vercel deploy --prod (prebuilt, no build on Vercel)
#   patch   shorebird patch android (Dart-only changes, same pubspec version)
#   release shorebird release android (apk + aab), copied to dist/
#   all     web + patch, the everyday deploy
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-}"
[ -f env.json ] || { echo "FAIL: env.json missing (copy env.<env>.json)" >&2; exit 1; }

version_line=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')

web() {
  flutter build web --release --dart-define-from-file=env.json
  # Deploy the built folder as-is: same headers/rewrites, no build step.
  python3 - <<'PY'
import json
d = json.load(open("vercel.json"))
d.update({"buildCommand": None, "installCommand": None, "outputDirectory": "."})
json.dump(d, open("build/web/vercel.json", "w"), indent=2)
PY
  (cd build/web && vercel deploy --prod --yes ${VERCEL_TOKEN:+--token "$VERCEL_TOKEN"})
}

patch() {
  shorebird patch android --release-version="$version_line" -- \
    --dart-define-from-file=env.json
}

release() {
  [ -f android/key.properties ] || {
    echo "FAIL: android/key.properties missing; a store release must use the upload key, never the debug key" >&2
    exit 1
  }
  shorebird release android --artifact apk -- --dart-define-from-file=env.json
  shorebird release android -- --dart-define-from-file=env.json
  mkdir -p dist
  cp build/app/outputs/flutter-apk/app-release.apk "dist/namazi_v${version_line}.apk"
  cp build/app/outputs/bundle/release/app-release.aab "dist/namazi_v${version_line}.aab"
  echo "dist/namazi_v${version_line}.{apk,aab}"
}

case "$target" in
  web) web ;;
  patch) patch ;;
  release) release ;;
  all) web; patch ;;
  *) echo "usage: tools/build_all.sh web|patch|release|all" >&2; exit 2 ;;
esac
