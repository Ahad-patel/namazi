# Masjid Timer

Find the nearest masjids from your location and see each one's namaz jamat times. Times are either verified by the masjid's admin or suggested by the community.

## Stack
- Flutter 3.x: one app for Android, iOS and web. The website is the same Flutter web build.
- Supabase: Auth, Postgres, PostGIS for nearby search, Storage for claim proof photos.
- RLS is enabled on every table. No table is ever created without policies.
- Routing: go_router. Models: freezed + json_serializable.
- Maps: flutter_map with MapTiler tiles. Never use tile.openstreetmap.org in production.
- Location: geolocator. If permission is denied, fall back to searching by area.

## State management
- Riverpod (riverpod_generator): compile-safe dependency injection plus async state, works across packages, and can be tested without a BuildContext.

## Monorepo (Dart pub workspaces)
```
apps/
  masjid_timer/          # user app + role-gated admin; mobile + web
    lib/features/<feature>/{data,presentation}/
    lib/router/
    lib/l10n/            # ARB files, flutter gen-l10n
  # admin app goes here if it's ever split out; it must only depend on packages/
packages/
  core/                  # models (freezed), enums, pure Dart, no Flutter
  data/                  # Supabase client, repositories, Riverpod providers
  ui/                    # theme tokens (ThemeExtension), shared widgets
supabase/
  migrations/            # the only way the schema changes
  seed.sql
  functions/             # edge functions, if needed
tools/osm_import/        # one-off script that imports masjids from OSM
```
- Dependency direction: apps → data → core, and apps → ui → core. Packages never import from apps.
- Admin and super-admin screens live in `apps/masjid_timer/lib/features/admin/`, gated by `profiles.role`.

## Commands
- `dart pub get` at the repo root (resolves the whole workspace)
- `flutter run -d chrome` or `flutter run`, from `apps/masjid_timer`
- `dart run build_runner build -d`, in the package you changed
- `supabase start` / `supabase db reset` / `supabase migration new <name>`

## Supabase rules
- Change the schema only through a new file in `supabase/migrations/`. Never edit an applied migration.
- Every new table gets `enable row level security` and explicit policies in the same migration.
- Nearby search is only the `nearby_masjids(lat, lng, radius_m)` RPC (PostGIS `ST_DWithin` on `geography`).
- What the UI displays per namaz comes from the `masjid_times(masjid_id)` RPC. Never reimplement the trust rules on the client.
- The client uses only the anon key. The service role key never goes in Flutter code.
- Store times as local `time` plus `masjids.timezone`. Never store UTC timestamps for jamat.

## Coding rules
- Before finishing any task: `dart format .` and `flutter analyze` must both pass with 0 issues.
- No hardcoded colors, strings or sizes:
  - Colors and typography: `Theme.of(context)` and `context.tokens` (ThemeExtension in `packages/ui`).
  - Spacing and radius: `AppSpacing.*` and `AppRadius.*` from `packages/ui`.
  - User-facing strings: ARB files via `AppLocalizations`.
- Widgets used in 2+ features move to `packages/ui`.
- Repositories return typed models from `packages/core`. Widgets never call Supabase directly.
- Handle loading, empty and error states with `AsyncValue.when`. No silent catches.
- Add tests for repositories and trust-rule edge cases. Widget tests for key components.

## Before you start
- Read `PRD.md` before starting a feature. Build in its phase order.
- Read `DESIGN.md` before any UI work.
