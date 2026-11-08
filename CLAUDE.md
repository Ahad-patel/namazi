# Masjid Timer

Find the nearest masjids from your location and see each one's namaz jamat times. Times are either verified by the masjid's admin or suggested by the community.

## Stack
- Flutter 3.x: one app for Android, iOS and web. The website is the same Flutter web build.
- Supabase: Auth, Postgres, PostGIS for nearby search, Storage for claim proof photos.
- RLS is enabled on every table. No table is ever created without policies.
- Routing: go_router with `usePathUrlStrategy()` (no `#` in web URLs, so `/m/:slug` links work).
- Models: Equatable entities + hand-written `fromJson`/`toJson` on data models. No freezed, no json_serializable, no build_runner (same as qqc_management / marc_management).
- Maps: flutter_map with MapTiler tiles. Never use tile.openstreetmap.org in production.
- Location: geolocator. If permission is denied, fall back to searching by area.
- Hosting: web on Vercel, Android OTA patches via Shorebird, one-click deploys via Jenkins on the dev Mac.

## Architecture: BLoC + clean architecture
Same structure as the owner's `qqc_management` and `marc_management` repos. When unsure how something is done, copy the pattern from there.
- State: `flutter_bloc` (`bloc`, `equatable`). Events and states are Dart 3 `sealed` classes / Equatable classes with `copyWith`, in `part` files next to the bloc. Cubit only for trivial state (theme).
- DI: `get_it`, one `lib/core/di/injector.dart` (`final sl = GetIt.instance; configureDependencies()`). Supabase client, data sources and repositories are lazy singletons; use cases and blocs are factories. `AuthBloc` is a lazy singleton because the router listens to it.
- Errors across layers: `dartz` `Either<Failure, T>`. Data sources throw; repositories catch and return `Left(Failure)`; blocs `fold`.
- Layers per feature, dependency points inward: `presentation → domain ← data`. `domain/` is pure Dart (no Flutter, no Supabase imports).

## Project structure
Single Flutter package at the repo root. The `flutter create` output stays as generated: package name `namazi`, Android `com.ska.namazi`, iOS/macOS/web/windows/linux folders. Touch generated files only to add code, permissions or config (e.g. location permission in `AndroidManifest.xml` / `Info.plist`). Never rename the package or move the app into a subfolder.
```
lib/
  main.dart              # void main() => bootstrap(NamaziApp.new);
  bootstrap.dart         # runZonedGuarded, BlocObserver, Supabase.initialize, configureDependencies, misconfigured screen
  core/
    config/              # env.dart (Env), app_constants.dart
    di/injector.dart     # get_it registrations
    error/               # exceptions.dart, failures.dart, postgrest_guard.dart (pg), repository_guard.dart (guard)
    network/             # network_info.dart
    platform/            # conditional-import helpers (*_io.dart / *_web.dart / *_stub.dart)
    router/app_router.dart
    theme/               # app_colors, app_spacing, app_typography, app_theme, AppTokens ThemeExtension, theme_cubit
    usecase/usecase.dart # UseCase<R, Params>, NoParams
    utils/
    widgets/             # shared widgets: ErrorView, EmptyState, LoadingView, ConfirmDestructiveDialog, ...
  features/<feature>/
    data/
      datasources/       # <feature>_remote_ds.dart: Supabase calls, throws exceptions
      models/            # <x>_model.dart extends entity, fromJson/toJson
      repositories/      # <feature>_repository_impl.dart, mixes in RepositoryGuard
    domain/
      entities/          # Equatable, pure Dart
      repositories/      # abstract <feature>_repository.dart
      usecases/          # one class per use case (or <feature>_usecases.dart when several are one-liners)
    presentation/
      bloc/              # <feature>_bloc.dart + part <feature>_event.dart + part <feature>_state.dart
      pages/
      widgets/
  l10n/                  # ARB files, flutter gen-l10n
assets/fonts/            # bundled fonts (no google_fonts runtime fetch)
test/                    # mirrors lib/: test/core/..., test/features/<feature>/...
supabase/
  migrations/            # the only way the schema changes
  tests/                 # pgTAP: RLS, trust rules, triggers (`supabase test db`)
  seed.sql
  functions/             # edge functions, if needed
tools/
  osm_import/            # one-off script that imports masjids from OSM
  check.sh               # format + analyze + flutter test + SQL tests
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
- Features never import another feature's `data/`. Shared needs go through `core/` or the other feature's `domain/`.
- Admin and super-admin screens live in `lib/features/admin/`, gated by `profiles.role` (read from `AuthBloc` state).

## Commands
- `flutter pub get` at the repo root
- `flutter run -d chrome --dart-define-from-file=env.local.json` or `flutter run --dart-define-from-file=env.local.json`, from the repo root
- `flutter gen-l10n` after editing ARB files (no other codegen)
- `supabase start` / `supabase db reset` / `supabase migration new <name>` / `supabase test db`
- `./tools/check.sh` — everything CI runs; must pass before a task is done. The SQL tests need Docker running (`supabase start`).
- `./tools/build_all.sh [web|patch|release|all]` — release builds (see Build & deploy)

## Config and secrets
- Build-time config only, via `--dart-define-from-file=env.<env>.json`. Keys: `APP_ENV` (`local` | `staging` | `prod`), `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MAPTILER_KEY`, `SENTRY_DSN` (empty = off), `TERMS_VERSION`.
- Three Supabase projects: local, staging, prod. One env file per environment; never point a dev build at prod.
- `env.*.json` are git-ignored; `env.example.json` is the committed template. Add a key to all of them.
- Non-prod builds show a persistent environment strip in the app bar, so prod is unmistakable.
- Read config through `Env` in `lib/core/config/env.dart` (`String.fromEnvironment`). If `Env.isConfigured` is false, `bootstrap.dart` shows a misconfigured screen explaining what's missing, never a blank page.
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
- Data sources wrap every Supabase call in `pg()` (`lib/core/error/postgrest_guard.dart`), which maps errors to exceptions in `lib/core/error/exceptions.dart`:
  - `PostgrestException` code `42501` → `PermissionException` (an RLS policy said no)
  - `PGRST116` → `NotFoundException`
  - `StorageException` 403 → `PermissionException`
  - JWT expired → `SessionExpiredException`
  - anything else → `ServerException(message, code)`
  - every call gets `.timeout(const Duration(seconds: 10))`
- Repositories mix in `RepositoryGuard` and return `guard(() => ...)`, which turns exceptions into `Failure` subtypes (`lib/core/error/failures.dart`): `PermissionFailure`, `NotFoundFailure`, `SessionExpiredFailure`, `NetworkFailure` (socket / host lookup / `ClientException` / `TimeoutException`), `ServerFailure` (anything else, logged with `debugPrint` + stack).
- Each `Failure` carries the raw technical `detail`. The shared `ErrorView` maps the subtype to a plain-language ARB string and hides the detail behind "Technical details".
- No `try` outside `data/`. Blocs `fold` the `Either`; widgets see errors only as a bloc state.

## Coding rules
- Before finishing any task: `./tools/check.sh` passes (`dart format --set-exit-if-changed`, `flutter analyze` with 0 issues, all tests).
- No hardcoded colors, strings or sizes:
  - Colors and typography: `Theme.of(context)` and `context.tokens` (ThemeExtension in `lib/core/theme/`).
  - Spacing and radius: `AppSpacing.*` and `AppRadius.*` from `lib/core/theme/app_spacing.dart`.
  - User-facing strings: ARB files via `AppLocalizations`.
- Widgets used in 2+ features move to `lib/core/widgets/`.
- Repositories return domain entities. Widgets and blocs never call Supabase directly; blocs call use cases.
- Every bloc state models loading, empty, loaded and error (status enum or sealed states); pages switch on it exhaustively. No silent catches.
- Fonts are bundled in `assets/fonts/`. Don't use `google_fonts` (fetches at runtime, breaks offline first launch and widget tests).
- Web-only and IO-only code goes behind conditional imports (`if (dart.library.js_interop)` / `if (dart.library.io)`). Never import `dart:io` from code the web build compiles.
- Use `EdgeInsetsDirectional` / `AlignmentDirectional` everywhere (RTL masjid names, future Urdu UI).
- Accessibility: every icon-only button has a `tooltip`; badges, map pins and the countdown have a `Semantics` label; decorative icons are excluded from semantics.
- Performance: lists use `.builder` constructors; a ticking widget (countdown) rebuilds only itself; read single fields with `context.select` / `BlocSelector` / `buildWhen`; admin features are `deferred as` imports on web.
- A deliberate shortcut with a known ceiling gets a `ponytail:` comment naming the ceiling and the upgrade path.

## Tests
- Unit tests (`mocktail`) for repositories (mocked data source) and every trust-rule edge case; `bloc_test` for every bloc.
- pgTAP in `supabase/tests/` for RLS per role (anon, user, banned user, masjid admin, super admin), the `masjid_times` trust rules, the 10-a-day abuse trigger, the 3-admins cap and the history trigger.
- `test/core/theme_contrast_test.dart`: every text/background token pair in DESIGN.md is ≥ 4.5:1, light and dark. Fails the build if a token change breaks contrast.
- Widget smoke tests for each main screen at 360×800, 390×844, 900×1024 and 1440×900, in light and dark, and at 2.0 text scale: render, `expect(tester.takeException(), isNull)`.

## Build & deploy
- `tools/build_all.sh <target>` (run from repo root, needs `env.json`, copied from the chosen `env.<env>.json`):
  - `web` — `flutter build web --release`, copy `vercel.json` into `build/web` with the build step switched off, `vercel deploy --prod`.
  - `patch` — `shorebird patch android` against the current `pubspec.yaml` version. Dart-only changes.
  - `release` — `shorebird release android --artifact apk` (and `appbundle` for Play), copied to `dist/namazi_v<version>+<build>.apk`.
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
