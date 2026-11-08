# Masjid Timer

Find the nearest masjids from your location and see each one's namaz jamat times. Times are either verified by the masjid's admin or suggested by the community.

## Stack
- Flutter 3.x: one app for Android, iOS and web. The website is the same Flutter web build.
- Supabase: Auth, Postgres, PostGIS for nearby search, Storage for claim proof photos.
- RLS is enabled on every table. No table is ever created without policies.
- Routing: go_router with `usePathUrlStrategy()` (no `#` in web URLs, so `/m/:slug` links work).
- Models: freezed + json_serializable.
- Maps: flutter_map with MapTiler tiles. Never use tile.openstreetmap.org in production.
- Location: geolocator. If permission is denied, fall back to searching by area.
- Hosting: web on Vercel, Android OTA patches via Shorebird, one-click deploys via Jenkins on the dev Mac.

## State management
- Riverpod (riverpod_generator): compile-safe dependency injection plus async state, works across packages, and can be tested without a BuildContext.

## Monorepo (Dart pub workspaces)
```
apps/
  masjid_timer/          # user app + role-gated admin; mobile + web
    lib/bootstrap.dart   # runZonedGuarded, Supabase.initialize, misconfigured screen
    lib/features/<feature>/{data,presentation}/
    lib/router/
    lib/l10n/            # ARB files, flutter gen-l10n
    assets/fonts/        # bundled fonts (no google_fonts runtime fetch)
  # admin app goes here if it's ever split out; it must only depend on packages/
packages/
  core/                  # models (freezed), enums, AppException types, pure Dart, no Flutter
  data/                  # Supabase client, repositories, Riverpod providers, Env
  ui/                    # theme tokens (ThemeExtension), shared widgets
supabase/
  migrations/            # the only way the schema changes
  tests/                 # pgTAP: RLS, trust rules, triggers (`supabase test db`)
  seed.sql
  functions/             # edge functions, if needed
tools/
  osm_import/            # one-off script that imports masjids from OSM
  check.sh               # format + analyze + every package's tests + SQL tests
  build_all.sh           # web | patch | release | all — used by Jenkins
  vercel_build.sh        # Vercel git builds: fetches pinned Flutter SDK
  verify_remote.sh       # probes prod with the anon key: every table/RPC exists
Jenkinsfile              # one-click deploy, calls tools/build_all.sh
vercel.json              # SPA rewrites + cache headers
shorebird.yaml           # Shorebird app_id (not secret, committed)
env.example.json         # template; real env.<local|staging|prod>.json are git-ignored
web/privacy.html, web/terms.html, web/delete-account.html   # static legal pages
NOTES.md                 # decisions that differ from PRD, open questions, verified, still to do
CHECKLISTS.md            # data-loss, performance and launch/legal checklists, ticked as done
```
- Dependency direction: apps → data → core, and apps → ui → core. Packages never import from apps.
- Admin and super-admin screens live in `apps/masjid_timer/lib/features/admin/`, gated by `profiles.role`.

## Commands
- `dart pub get` at the repo root (resolves the whole workspace)
- `flutter run -d chrome --dart-define-from-file=env.local.json` or `flutter run --dart-define-from-file=env.local.json`, from `apps/masjid_timer`
- `dart run build_runner build -d`, in the package you changed
- `supabase start` / `supabase db reset` / `supabase migration new <name>` / `supabase test db`
- `./tools/check.sh` — everything CI runs; must pass before a task is done. The SQL tests need Docker running (`supabase start`).
- `./tools/build_all.sh [web|patch|release|all]` — release builds (see Build & deploy)

## Config and secrets
- Build-time config only, via `--dart-define-from-file=env.<env>.json`. Keys: `APP_ENV` (`local` | `staging` | `prod`), `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MAPTILER_KEY`, `SENTRY_DSN` (empty = off), `TERMS_VERSION`.
- Three Supabase projects: local, staging, prod. One env file per environment; never point a dev build at prod.
- `env.*.json` are git-ignored; `env.example.json` is the committed template. Add a key to all of them.
- Non-prod builds show a persistent environment strip in the app bar, so prod is unmistakable.
- Read config through `Env` in `packages/data` (`String.fromEnvironment`). If `Env.isConfigured` is false, `bootstrap.dart` shows a misconfigured screen explaining what's missing, never a blank page.
- The anon key and MapTiler key ship in the build and are public by design. RLS is the guard. Restrict the MapTiler key to the app's domains in the MapTiler dashboard.
- Service role key, Shorebird token, Vercel token, DB password: Jenkins credentials only. Never in Flutter code, dart-defines or git.

## Supabase rules
- Change the schema only through a new file in `supabase/migrations/`. Never edit an applied migration.
- Every new table gets `enable row level security` and explicit policies in the same migration.
- Every new table, policy, RPC or trigger gets a pgTAP test in `supabase/tests/` in the same change.
- Nearby search is only the `nearby_masjids(lat, lng, radius_m)` RPC (PostGIS `ST_DWithin` on `geography`).
- What the UI displays per namaz comes from the `masjid_times(masjid_id)` RPC. Never reimplement the trust rules on the client.
- The client uses only the anon key. The service role key never goes in Flutter code.
- Store times as local `time` plus `masjids.timezone`. Never store UTC timestamps for jamat.
- Data-loss rules:
  - No client `delete` policy on any table except `suggestion_votes` (own vote). Removal = `status` change (`hidden` / `revoked` / `superseded`) through a role-checked RPC, restorable by the super admin.
  - Moderation RPCs act on one id at a time. Any future bulk action caps at 50 rows server-side.
  - Storage objects are write-once: insert policy only, new path per upload, no client update/delete.
  - A migration that drops or truncates anything starts with `-- destructive: <reason>`; `tools/check.sh` fails on a drop without it.
  - Every migration goes local (`db reset` + `test db`) → staging → prod. Never straight to prod.
- Privacy rules:
  - User lat/lng is a query parameter only. Never insert it, log it, or `raise notice` it.
  - Phone numbers and proof photos exist only on claims and are purged 90 days after the decision.
  - Account deletion runs in the `delete-account` Edge Function (service role, server side). Suggestions are anonymised (`suggested_by = null`), not deleted.
- Query rules: always list columns in `.select('a,b,c')`, never `*`. Index every column a policy, RPC filter or sort uses, in the same migration. Lists are paginated (`.range()`, 25) or capped (nearby: 50).- Postgres gotchas (all hit in earlier projects):
  - Views are `with (security_invoker = true)`. Without it a view runs as its owner and reads straight past RLS.
  - `security definer` functions set `search_path = ''` and schema-qualify every name.
  - Don't name a helper `current_role()` (reserved). Use `app_role()`.
  - Audit/history triggers branch on `tg_op`. `NEW` is unassigned in a DELETE trigger.
  - RLS tests run as real roles: `set local role authenticated` plus `request.jwt.claims` with the user's `sub`, the way PostgREST does. Hiding a button is not a permission check.
- After applying migrations to prod, run `./tools/verify_remote.sh`. It expects 200 (or 401/403) for each object and fails on 404 (`PGRST205`, object never created).

## Errors
- Repositories wrap every Supabase call in one shared helper (`guardPg` in `packages/data`) that maps errors to `AppException` subtypes from `packages/core`:
  - `PostgrestException` code `42501` → `PermissionException` (an RLS policy said no)
  - `PGRST116` → `NotFoundException`
  - `StorageException` 403 → `PermissionException`
  - socket / host lookup / `ClientException` / `TimeoutException` → `NetworkException`
  - JWT expired → `SessionExpiredException`
  - every call gets `.timeout(const Duration(seconds: 10))`
  - anything else → `ServerException`, logged with `debugPrint` + stack
- Each `AppException` has a plain-language message (from ARB) plus the raw technical detail. The shared error view shows the message and hides the detail behind "Technical details".
- No `try` outside the data layer. Widgets get errors only through `AsyncValue.error`.

## Coding rules
- Before finishing any task: `./tools/check.sh` passes (`dart format --set-exit-if-changed`, `flutter analyze` with 0 issues, all tests).
- No hardcoded colors, strings or sizes:
  - Colors and typography: `Theme.of(context)` and `context.tokens` (ThemeExtension in `packages/ui`).
  - Spacing and radius: `AppSpacing.*` and `AppRadius.*` from `packages/ui`.
  - User-facing strings: ARB files via `AppLocalizations`.
- Widgets used in 2+ features move to `packages/ui`.
- Repositories return typed models from `packages/core`. Widgets never call Supabase directly.
- Handle loading, empty and error states with `AsyncValue.when`. No silent catches.
- Fonts are bundled in `assets/fonts/`. Don't use `google_fonts` (fetches at runtime, breaks offline first launch and widget tests).
- Web-only and IO-only code goes behind conditional imports (`if (dart.library.js_interop)` / `if (dart.library.io)`). Never import `dart:io` from code the web build compiles.
- Use `EdgeInsetsDirectional` / `AlignmentDirectional` everywhere (RTL masjid names, future Urdu UI).
- Accessibility: every icon-only button has a `tooltip`; badges, map pins and the countdown have a `Semantics` label; decorative icons are excluded from semantics.
- Performance: lists use `.builder` constructors; a ticking widget (countdown) rebuilds only itself; watch single fields with `ref.watch(p.select(...))`; admin features are `deferred as` imports on web.
- A deliberate shortcut with a known ceiling gets a `ponytail:` comment naming the ceiling and the upgrade path.

## Tests
- Unit tests for repositories (mock Supabase client) and every trust-rule edge case.
- pgTAP in `supabase/tests/` for RLS per role (anon, user, banned user, masjid admin, super admin), the `masjid_times` trust rules, the 10-a-day abuse trigger, the 3-admins cap and the history trigger.
- `theme_contrast_test.dart` in `packages/ui`: every text/background token pair in DESIGN.md is ≥ 4.5:1, light and dark. Fails the build if a token change breaks contrast.
- Widget smoke tests for each main screen at 360×800, 390×844, 900×1024 and 1440×900, in light and dark, and at 2.0 text scale: render, `expect(tester.takeException(), isNull)`.

## Build & deploy
- `tools/build_all.sh <target>` (run from repo root, needs `env.json`, copied from the chosen `env.<env>.json`):
  - `web` — `flutter build web --release`, copy `vercel.json` into `build/web` with the build step switched off, `vercel deploy --prod`.
  - `patch` — `shorebird patch android` against the current `pubspec.yaml` version. Dart-only changes.
  - `release` — `shorebird release android --artifact apk` (and `appbundle` for Play), copied to `dist/masjid_timer_v<version>+<build>.apk`.
  - `all` — `web` + `patch`, the everyday deploy.
- Patch or release: Dart code change = `patch`, no version bump. Asset, font, native plugin or dependency change = bump `version:` in `pubspec.yaml`, then `release`. A patch can't change assets or native code.
- Jenkins (`Jenkinsfile`, runs on the dev Mac):
  - Parameters: `BRANCH` (Git Parameter plugin, default `main`) and `TARGET` (`all` | `web` | `patch` | `release` | `db`).
  - Stages: checkout `BRANCH` → `./tools/check.sh` → build target → archive APK.
  - `env.json` comes from a secret-file credential and is deleted by a `trap` even on failure. `disableConcurrentBuilds()`.
  - `ENV` parameter (`staging` | `prod`) picks the secret file `masjid-env-<env>`. Default `staging`.
  - `db` runs `supabase db push` then `./tools/verify_remote.sh`. It is never part of `all`. With `ENV=prod` it stops at an input step that needs "PROD" typed.
- Jenkins `backup-prod` job (nightly): schema + data dump and `rclone sync` of the `claim-proofs` bucket to an off-Supabase bucket with object lock (30 days), write-only key. Emails on failure, and on > 20 moderation actions in 24h. Restore test monthly (CHECKLISTS.md §1).
- Vercel: `vercel.json` rewrites everything to `/index.html` (go_router owns routes). `assets/`, `canvaskit/`, `icons/` are `immutable` for a year; `index.html`, `flutter_service_worker.js`, `version.json`, `manifest.json` are `must-revalidate` so a deploy is never pinned to a stale build.
- `tools/vercel_build.sh` (Vercel git builds) clones a pinned Flutter tag (same version as local) and fails loudly if `SUPABASE_URL`, `SUPABASE_ANON_KEY` or `MAPTILER_KEY` is unset.
- iOS: release builds by hand (Xcode / TestFlight) for v1. No iOS lane in Jenkins yet.

## NOTES.md
- Keep `NOTES.md` at the repo root updated at the end of each session: decisions that differ from PRD.md and why, open questions for the owner, what was verified (and how), and what's still to do.

## Before you start
- Read `PRD.md` before starting a feature. Build in its phase order.
- Read `DESIGN.md` before any UI work.
- Read `NOTES.md` for open decisions and known gaps.
- Check `CHECKLISTS.md` for items tied to the feature's phase; tick them when done and verified.
