# Notes

## Decisions that differ from PRD / earlier drafts

- **BLoC + clean architecture, not Riverpod.** Matches the owner's `qqc_management` and `marc_management` repos: `flutter_bloc`, `get_it` (`lib/core/di/injector.dart`), `dartz` `Either<Failure, T>`, `lib/features/<f>/{data,domain,presentation}`. One way of working across all three apps.
- **Single Flutter package at the repo root, no monorepo.** The `flutter create` output (`namazi`, `com.ska.namazi`) stays as generated; generated files are only edited to add code, permissions or config.
- **No freezed / json_serializable / build_runner.** Equatable entities, sealed bloc events/states, hand-written `fromJson`. Same as the reference repos; the only codegen is `flutter gen-l10n` (output in `lib/l10n/gen/`).
- **Next-jamat instant is computed in SQL.** `masjid_times` returns `next_at timestamptz` per row (masjid's timezone, Jummah only on Fridays, Zuhr skips Fridays when the masjid has a Jummah time). The client never does timezone maths: countdown = `next_at - now`, highlight = smallest future `next_at`. When it passes, the bloc refetches.
- **`masjids.osm_id` is `text` (`node/123`, `way/45`)**, not `bigint`: OSM ids are only unique per element type.
- **Phase-1 `masjid_times` is verified-only.** Community fallback, conflicts and staleness come with `time_suggestions` in Phase 2 (`create or replace`).
- **Helpers in schema `app`** (`app.next_occurrence`, `app.masjids_within`), not exposed through PostgREST. `nearby_masjids` and `next_jamat_nearby` both read `app.masjids_within`, so the banner sees every masjid in the radius, not just the 50 nearest.
- **Detail page by slug: `masjid_by_slug(masjid_slug)` RPC** (PostgREST can't return lat/lng from a geography column). Opening from the list passes the `Masjid` via go_router `extra`, so only `masjid_times` is fetched; a shared link fetches masjid then times (chained — the times RPC needs the id).
- **Area search = MapTiler Geocoding API** (same key as tiles, `country=in`, first result). No extra service or key.
- **Fonts are the Google Fonts variable TTFs** (one file per family, wght axis, weight chosen with `FontVariation`). Total ~1.1 MB. Static per-weight files would be smaller per weight but Manrope alone needs 4.
- **Environment strip and offline banner are global** (`AppFrame` in `MaterialApp.builder`), above every route's app bar.
- **Masjid card at text scale > 1.4** moves the next jamat under the name instead of the trailing column (the trailing column squeezed the name to 13 px at 2.0× on 360 px).
- **OSM import includes dargahs** (`amenity=place_of_worship` + `religion=muslim`). The super admin hides any that shouldn't be listed (Phase 3 tools).
- **ODbL:** masjid locations come from OpenStreetMap; the map shows "© OpenStreetMap contributors · © MapTiler" (`RichAttributionWidget`) and the detail page footer repeats it. If the masjids table is ever offered publicly as data, it must be under ODbL.

## Open questions

- MapTiler key: needs creating and restricting to the app domains before the map shows tiles. Until then the map renders pins on a plain background.
- DPDP: account creation asks "I am 18 or older" (Phase 2). Confirm the store target audience 13+.
- Supabase CLI is not installed on the dev Mac; the owner applies migrations by hand for now. `tools/check.sh` prints a loud SKIPPED line for the SQL tests until it is.

## Verified

- 2026-11-08: `./tools/check.sh` green — format, `flutter analyze` 0 issues, 209 Dart tests (theme contrast light+dark, repository guard mapping, repository + cache, nearby/detail bloc tests, widget smoke tests for both screens × 4 sizes × light/dark × 1.0/2.0 text scale × every state, with an Urdu name).
- 2026-11-08: `flutter build web --release` compiles (no `dart:io` in the web build).
- 2026-11-08: `tools/osm_import` ran against Overpass: 162 masjids for Greater Mumbai written to `supabase/osm_mumbai.sql`.
- **Not verified:** migrations and pgTAP tests (`supabase/tests/01–04`) have not been run — no Supabase CLI and Docker was not running. Run `supabase start && supabase db reset && supabase test db` before trusting them.

## Still to do

- Phase 1 leftovers: run the SQL tests; `explain analyze` of `nearby_masjids` on the Mumbai import; staging project + `env.staging.json`; Jenkins job pointing at `Jenkinsfile` (test-only); app name/icon suffix for non-prod builds; `meetsGuideline` accessibility widget test.
- Phase 2 per PRD: auth (Google + email OTP), consent screen, `time_suggestions` + `suggestion_votes`, full trust rules in `masjid_times`, abuse trigger, suggest/vote/add masjid, Settings (theme, sign out, version, licences).
