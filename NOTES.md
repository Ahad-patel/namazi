# Notes

## Decisions that differ from PRD / earlier drafts

- **BLoC + clean architecture, not Riverpod.** Matches the owner's `qqc_management` and `marc_management` repos: `flutter_bloc`, `get_it` (`lib/core/di/injector.dart`), `dartz` `Either<Failure, T>`, `lib/features/<f>/{data,domain,presentation}`. One way of working across all three apps.
- **Single Flutter package at the repo root, no monorepo.** The `flutter create` output (`namazi`, `com.ska.namazi`) stays as generated; generated files are only edited to add code, permissions or config.
- **No freezed / json_serializable / build_runner.** Equatable entities, sealed bloc events/states, hand-written `fromJson`. Same as the reference repos; the only codegen is `flutter gen-l10n` (output in `lib/l10n/gen/`).
- **Next-jamat instant is computed in SQL.** `masjid_times` returns `next_at timestamptz` per row (masjid's timezone, Jummah only on Fridays, Zuhr skips Fridays when the masjid has a Jummah time). The client never does timezone maths: countdown = `next_at - now`, highlight = smallest future `next_at`. When it passes, the bloc refetches.
- **`masjids.osm_id` is `text` (`node/123`, `way/45`)**, not `bigint`: OSM ids are only unique per element type.
- **`masjid_times` carries all trust rules from Phase 2** (migration `…05_community.sql`): verified wins; else top open suggestion with net ≥ 2 (ties → newest); `differing_reports` (0 unless ≥ 2); staleness (120 days, with `community_*` columns) is in already, though the PRD lists it under Phase 3 — the return type had to change once, so it changed once. The function is dropped + recreated (return type changed), hence the `-- destructive:` header; no data is dropped.
- **Helpers in schema `app`** (`app.next_occurrence`, `app.masjids_within`), not exposed through PostgREST. `nearby_masjids` and `next_jamat_nearby` both read `app.masjids_within`, so the banner sees every masjid in the radius, not just the 50 nearest.
- **Detail page by slug: `masjid_by_slug(masjid_slug)` RPC** (PostgREST can't return lat/lng from a geography column). Opening from the list passes the `Masjid` via go_router `extra`, so only `masjid_times` is fetched; a shared link fetches masjid then times (chained — the times RPC needs the id).
- **Area search = MapTiler Geocoding API** (same key as tiles, `country=in`, first result). No extra service or key.
- **Fonts are the Google Fonts variable TTFs** (one file per family, wght axis, weight chosen with `FontVariation`). Total ~1.1 MB. Static per-weight files would be smaller per weight but Manrope alone needs 4.
- **Environment strip and offline banner are global** (`AppFrame` in `MaterialApp.builder`), above every route's app bar.
- **Masjid card at text scale > 1.4** moves the next jamat under the name instead of the trailing column (the trailing column squeezed the name to 13 px at 2.0× on 360 px).
- **OSM import includes dargahs** (`amenity=place_of_worship` + `religion=muslim`). The super admin hides any that shouldn't be listed (Phase 3 tools).
- **ODbL:** masjid locations come from OpenStreetMap; the map shows "© OpenStreetMap contributors · © MapTiler" (`RichAttributionWidget`) and the detail page footer repeats it. If the masjids table is ever offered publicly as data, it must be under ODbL.

- **Google sign-in is browser OAuth on every platform** (`signInWithOAuth`, deep link `com.ska.namazi://login-callback` on Android/iOS, full-page redirect to `/` on web). No `google_sign_in` plugin and no per-platform client ids; only the web client id + secret in Supabase. Switch to native if the browser hop hurts.
- **Email sign-in is a 6-digit OTP code**, not a magic link (`verifyOTP(type: email)`). The Supabase "Magic Link" email template must contain `{{ .Token }}` — the default template only sends a link.
- **No router auth redirects.** Browsing never needs an account; `ensureContributor()` (`lib/features/auth/presentation/contributor_gate.dart`) pushes `/sign-in` then `/consent` when a user taps Suggest / Vote / Add masjid, and returns whether they may go ahead. RLS (`app.can_contribute()`: signed in, not banned, `is_adult`, terms accepted) is the real check.
- **Consent is enforced server side as "accepted some version"**; the client re-asks when `TERMS_VERSION` differs from `profiles.terms_version`. `TERMS_VERSION` is now a required build key (misconfigured screen if empty).
- **New build key `SITE_URL`** (public web origin, empty for now). Web uses its own origin for `/terms.html` and `/privacy.html`; mobile hides the links until it's set. Added (empty) to every `env.*.json`.
- **`suggested_by` defaults to `auth.uid()`** and `masjid_suggestions(masjid_id)` returns `is_mine` / `my_vote`, so the client never sends or compares user ids. Votes: upsert on `(suggestion_id, user_id)`, delete to take a vote back; `net_votes` is recounted by a trigger.
- **Add masjid goes through `add_masjid(...)` RPC** (security invoker): it builds the slug (`<latin-slug>-<6 hex>`, or `masjid-<hex>` for a name with no Latin letters) and the geography. Rows are `pending` and invisible to everyone (including the creator) until Phase 3 review. No per-user cap yet (`ponytail:` in the migration).
- **Rate limits are their own Failure** (`RateLimitFailure`): our SQLSTATE `MT429` from the 10-a-day trigger, and auth HTTP 429. Auth errors are `SignInFailure`.
- **Suggestions list capped at 50** per masjid (RPC `limit 50`, `ponytail:`), not paginated — at most one open row per user and namaz.
- **Suggestion submit shows "Sending…" on the button**, not as a placeholder row in the list (CHECKLISTS §2 Optimistic UI asks for the row). Votes are fully optimistic with rollback + snackbar.
- **`TimeText` / `formatters` are imported by `suggestions` from `masjids/presentation`.** Allowed (only `data/` is off-limits), but strictly they're now 2-feature widgets; moving them to `core/` would drag `ClockTime` into core. Left as is.

- **Suggested times must fall inside their namaz window** (`…06_prayer_windows.sql`, owner request 2026-11-09). The PRD keeps calculated times out of v1, and they're still never *displayed*: the sun position at the masjid's lat/lng is used only to validate input. Method: Karachi (Fajr/Isha at 18°, standard in India). Windows: Fajr dawn→sunrise, Zuhr/Jummah noon→Hanafi Asr, Asr Shafi'i Asr→sunset, Maghrib sunset→Isha, Isha→next Fajr (wraps midnight), each with 10 min slack, edges rounded to whole minutes. Checked against the masjid's local *today* (SQLSTATE `MT422` → `ValidationFailure`). The sheet fetches `prayer_windows(masjid_id)` and shows "Fajr here today: 5:17 AM – 6:53 AM", blocking Submit outside it; the trigger is the real check. Elevation is a parameter but defaults to 0 (no column, OSM rarely has it; < 1 min near sea level, `ponytail:`). Where the sun never reaches 18° (far north in summer) the check is skipped. Phase 3 admin times should call the same `app.prayer_window`.

## Open questions

- MapTiler key: needs creating and restricting to the app domains before the map shows tiles. Until then the map renders pins on a plain background.
- DPDP: account creation asks "I am 18 or older" (Phase 2). Confirm the store target audience 13+.
- Google provider + redirect URLs + SMTP must be configured per Supabase project (dashboard, by hand): Redirect URLs `http://localhost:*`, the Vercel domain, `com.ska.namazi://login-callback`; email template with `{{ .Token }}`; custom SMTP before launch.
- Supabase CLI is not installed on the dev Mac; the owner applies migrations by hand for now. `tools/check.sh` prints a loud SKIPPED line for the SQL tests until it is.

## Verified

- 2026-11-08: `./tools/check.sh` green — format, `flutter analyze` 0 issues, 209 Dart tests (theme contrast light+dark, repository guard mapping, repository + cache, nearby/detail bloc tests, widget smoke tests for both screens × 4 sizes × light/dark × 1.0/2.0 text scale × every state, with an Urdu name).
- 2026-11-08: `flutter build web --release` compiles (no `dart:io` in the web build).
- 2026-11-08: `tools/osm_import` ran against Overpass: 162 masjids for Greater Mumbai written to `supabase/osm_mumbai.sql`.
- 2026-11-08 (Phase 2): `./tools/check.sh` green — format, analyze 0 issues, 515 Dart tests (AuthBloc, SignInBloc, SuggestionsBloc incl. optimistic vote + rollback, AddMasjidBloc, auth/suggestion repositories, `pg()` mapping incl. `MT429` and auth 429, smoke tests for sign-in, consent, settings, add masjid, suggest sheet, suggestion tiles, and detail with suggestions + trust-rule rows at 4 sizes × light/dark × 1.0/2.0). `flutter build web --release` compiles.
- 2026-11-09: `…05_community.sql` applied to the dev project (`env.local.json`). Probed with the anon key: `time_suggestions`, `suggestion_votes`, `masjid_suggestions`, new `masjid_times` columns and `nearby_masjids` all return 200; anon `accept_terms`, `add_masjid` and suggestion insert are refused with `42501`. Two real suggestions exist (sign-in → consent → insert worked end to end); with 0 votes they correctly stay out of `masjid_times`. Owner confirmed the OTP email (custom SMTP + `{{ .Token }}` template) arrives.
- 2026-11-09: sun maths of `…06` run in PGlite (Postgres 16 in WASM, scratchpad only; Homebrew postgres@16 is broken — missing ICU): Mumbai 21 Jun sunrise 06:02 / noon 12:40 / sunset 19:18, 21 Dec 07:07 / 18:06, Delhi 9 Nov 06:39 / 17:31 — all within 1–2 min of published almanacs; Tromsø midsummer returns null Fajr/Isha (check skipped). The trigger itself and pgTAP 08 are not run (need PostGIS + auth schema). `./tools/check.sh` green, 519 Dart tests.
- Dev DB has one pre-window test row (Fajr 18:00) from before `…06`; the trigger checks inserts only, so it stays until hidden (Phase 3 tools) or ignored.
- **Not verified:** Phase 2 SQL (`…05_community.sql`, `supabase/tests/05–07`) has not been run either — same reason. Google OAuth and email OTP not tried against a real project.
- **Not verified:** migrations and pgTAP tests (`supabase/tests/01–04`) have not been run — no Supabase CLI and Docker was not running. Run `supabase start && supabase db reset && supabase test db` before trusting them.

## Still to do

- Phase 1 leftovers: run the SQL tests; `explain analyze` of `nearby_masjids` on the Mumbai import; staging project + `env.staging.json`; Jenkins job pointing at `Jenkinsfile` (test-only); app name/icon suffix for non-prod builds; `meetsGuideline` accessibility widget test.
- Phase 2 leftovers: two-account vote test (2 upvotes → row shows "Community"); 11th suggestion in a day refused; run pgTAP 01–07 once the CLI exists; staging project + same dashboard auth setup there.
- Phase 3 (PRD): claims + proof upload, admin times + inbox, super admin queues (incl. pending masjids from `add_masjid`), history trigger, moderation log, landing page, Vercel/Shorebird/Jenkins deploy, download my data / delete account, legal pages (consent links point at `/terms.html` and `/privacy.html`, which don't exist yet), Shorebird patch number in the Settings version line.
