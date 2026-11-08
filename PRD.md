# Masjid Timer — PRD (v1)

## Users
- **General user:** browses nearby masjids and their times. No login needed to browse.
- **Community contributor:** a logged-in user who suggests times, votes, or adds a missing masjid.
- **Masjid admin:** a logged-in user approved for a specific masjid. Their times are shown as verified.
- **Super admin (owner):** reviews admin claims and new masjids, and can hide abusive content.

## Auth
- Sign-in with Google or email OTP. Required for suggesting, voting, claiming and adding.
- `profiles.role`: `user` | `super_admin`. Admin rights are per masjid, stored in `masjid_admins`.
- A `handle_new_user()` trigger on `auth.users` creates the `profiles` row (role `user`). The client never inserts into `profiles`.
- The first super admin is promoted once by hand in the SQL editor (`update public.profiles set role = 'super_admin' where id = '<uuid>' returning id, role;`). Every later role change goes through the app.
- Banned users can still sign in and browse; RLS blocks their inserts and votes.
- First sign-in, before contributing: "I am 18 or older" (required, DPDP) and "I agree to the Terms and Privacy Policy" (unticked, linked). Stored as `profiles.terms_version` + `terms_accepted_at`; asked again when `TERMS_VERSION` changes. Browsing never needs this.

## Permissions
RLS enforces every row of this. The UI only hides buttons.

| Capability | Anon | User | Banned | Masjid admin (own masjid) | Super admin |
|---|:--:|:--:|:--:|:--:|:--:|
| Browse masjids, times, map, `/m/:slug` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Suggest a time, vote, add a masjid | ❌ | ✅ | ❌ | ✅ | ✅ |
| Submit a claim | ❌ | ✅ | ❌ | ✅ | ✅ |
| Set verified times, accept/reject suggestions | ❌ | ❌ | ❌ | ✅ | ✅ |
| Read claim proof photos | ❌ | own only | own only | own only | ✅ |
| Approve/reject claims and new masjids, revoke admins | ❌ | ❌ | ❌ | ❌ | ✅ |
| Hide suggestions, ban users, read moderation log | ❌ | ❌ | ❌ | ❌ | ✅ |

## MVP features
1. **Nearby masjids (list + map)**
   - With location granted, the list shows masjids within 3 km sorted by distance, each with distance and its next jamat. The map shows the same set as pins.
   - With location denied, the user can search an area and get the same list.
2. **Next-jamat highlight**
   - The top of the nearby screen shows the soonest upcoming jamat within the radius (masjid, namaz, time, countdown).
   - It moves to the next namaz automatically once the current jamat time passes.
3. **Masjid detail**
   - Shows azaan and jamat for Fajr, Zuhr, Asr, Maghrib, Isha and Jummah, each with its source badge (verified or community) and when it was updated.
   - The next namaz row is highlighted. A Directions button opens the platform maps app.
4. **Suggest times (community)**
   - A logged-in user can submit a jamat (and optional azaan) time per namaz, with a note. It appears under "Community suggestions" straight away.
   - Each user has one active suggestion per masjid and namaz. A new one replaces their old one.
5. **Vote on suggestions**
   - A logged-in user can upvote or downvote another user's suggestion, once per suggestion. They can't vote on their own.
6. **Claim masjid (admin request)**
   - A logged-in user submits a claim: their role at the masjid (imam, mutawalli or committee), a phone number, and an optional proof photo. Status starts as `pending`.
   - Once approved, the admin section unlocks for that masjid only.
7. **Admin: manage times**
   - An approved admin can set azaan and jamat per namaz, with a `valid_from` date. The times show as verified immediately.
   - The admin inbox lists open community suggestions that differ from the verified time, with Accept or Reject on each.
8. **Super admin review**
   - Queues for pending claims and pending new masjids, each with Approve or Reject and an optional reason.
9. **Add missing masjid**
   - A logged-in user can drop a pin and enter a name (optionally in Arabic or Urdu script). It stays hidden until a super admin approves it.
10. **Website (Flutter web)**
    - `/` is a landing page with an area search and "use my location". `/m/:slug` is a shareable masjid detail page.
    - Path URLs (no `#`). A reload or a shared link on any route opens that route, not a 404.
11. **Settings**
    - Theme: system (default), light or dark, remembered on the device.
    - Sign out, and an app version line (`version+build`, plus the Shorebird patch number on Android) so a bug report says exactly what build it came from.
    - **Download my data** (JSON of profile, suggestions, votes, claims via `my_data()` RPC).
    - **Delete my account** (typed confirmation → `delete-account` Edge Function). Suggestions stay, anonymised.
    - About: contact email, Privacy, Terms, Open-source licences.
12. **Legal pages (static, web)**
    - `/privacy.html`, `/terms.html`, `/delete-account.html` as plain HTML in `web/`, linked from the landing page, sign-in, Settings and store listings.
13. **Trust copy**
    - Tapping a source badge explains it ("Set by an approved admin of this masjid" / "Suggested by the community, N net votes").
    - Masjid detail footer: "Times can change. Confirm with the masjid." Map and `/m/:slug` show "© OpenStreetMap contributors · © MapTiler".

## Trust rules
- **Display priority per namaz** (computed in the `masjid_times` RPC):
  1. A verified admin time whose `valid_from` is today or earlier is shown with the "Verified" badge.
  2. If there's no verified time, show the top community suggestion with net votes ≥ 2, badged "Community". Ties go to the most recent.
  3. If neither exists, show "Not available — suggest a time".
- **Conflicts:**
  - A verified time always wins the main display.
  - If 2 or more open suggestions differ from the verified time, show a secondary line: "N people report a different time".
  - Accepted suggestions become the verified time. Rejected and replaced ones are archived (`superseded`) and never shown.
- **Staleness:** if a verified time hasn't been updated for 120 days, show "May be outdated" and also show the community suggestion.
- **Abuse limits:** at most 10 suggestions per user per day (enforced in a trigger). A super admin can hide a suggestion or ban a user from contributing.
- **Admin verification:**
  - Manual review by the super admin, who calls the masjid or checks the proof photo.
  - At most 3 approved admins per masjid. Admin rights can be revoked.
  - Every verified time change is logged in `jamat_time_history`.
- **Soft delete only:** masjids, suggestions and admin rights are hidden/revoked, never hard-deleted from the client. The super admin has a Hidden tab with Restore. Hide masjid, ban user and revoke admin need the name typed to confirm.
- **Moderation log:** every super-admin action (approve/reject claim or masjid, revoke admin, hide suggestion, ban/unban) is written to `moderation_log` by a trigger, with who, when, the before/after status and the reason. Super admin only, read-only, newest first.

## Core tables (key columns)
- `profiles`: id (→auth.users), display_name, role, is_banned, is_adult, terms_version, terms_accepted_at, created_at
- `masjids`: id, slug, name, name_local, name_script (`arab`|`urdu`|null), address, location geography(Point), timezone, facilities text[], status (`pending`|`active`|`hidden`), osm_id, created_by
- `masjid_admins`: masjid_id, user_id, status (`pending`|`approved`|`rejected`|`revoked`), role_at_masjid, phone, proof_path, reviewed_by, reviewed_at, reason
- `jamat_times` (verified, current): masjid_id, prayer (enum fajr|zuhr|asr|maghrib|isha|jummah), azaan_time, jamat_time, valid_from, updated_by, updated_at. Unique on (masjid_id, prayer, valid_from).
- `jamat_time_history`: jamat_times columns plus changed_at and changed_by (written by a trigger)
- `time_suggestions`: id, masjid_id, prayer, azaan_time, jamat_time, note, suggested_by, status (`open`|`accepted`|`rejected`|`superseded`|`hidden`), net_votes, created_at
- `suggestion_votes`: suggestion_id, user_id, value (−1|1). PK (suggestion_id, user_id).
- `moderation_log`: id, actor_id, action, target_table, target_id, before jsonb, after jsonb, reason, created_at (written by triggers only; no client insert policy)
- Storage: `claim-proofs` bucket, private. Path `<user_id>/<claim_id>.jpg`; owner and super admin can read, owner can upload once (no update/delete). Resized on device to 1600px, JPEG 80.
- Retention: claim phone + proof photo deleted 90 days after the decision (`purge-claims` scheduled Edge Function); superseded suggestions deleted after 1 year.
- Edge Functions: `delete-account`, `purge-claims`. Both region `ap-south-1`, same as the database.
- RPCs: `nearby_masjids(lat, lng, radius_m)`, `masjid_times(masjid_id)`, `next_jamat_nearby(lat, lng, radius_m)`

## Supabase project setup (once, per environment)
- Three projects: local, staging, prod, all in `ap-south-1` (Mumbai). Prod on the Pro plan (daily backups); PITR add-on once real community data builds up.
- MFA on every Supabase, Vercel, GitHub and Jenkins account. Only the owner has Owner role on the prod org.
- Sign the DPAs for Supabase, Vercel, MapTiler and Sentry.
- Authentication → URL Configuration: **Site URL** = the Vercel domain. **Redirect URLs** add the Vercel domain, `http://localhost:*` for dev, and the app's deep-link scheme for mobile Google sign-in. Left on `localhost:3000`, OTP and OAuth links only work on the dev machine.
- Email OTP needs **custom SMTP** before launch. The built-in mailer only delivers to project members and is capped at a few emails an hour.
- Google provider: web client ID + secret in Supabase; Android and iOS client IDs for native sign-in.
- Extensions: `postgis` enabled by the first migration, not by hand.
- After every prod migration: `./tools/verify_remote.sh`.

## Build order
- **Phase 1 — Browse (read-only)**
  - Monorepo, theme tokens (with contrast test), bundled fonts, router, l10n setup
  - `Env` + `env.<env>.json` files (local, staging, prod), `bootstrap.dart` with the misconfigured screen, shared error/empty/loading views, `guardPg` error mapping
  - `tools/check.sh` and a Jenkins job that runs it on any branch (test-only, no deploy yet)
  - Migrations: profiles (+ `handle_new_user` trigger), masjids, jamat_times, RLS, PostGIS, the nearby RPC, with pgTAP tests
  - OSM import for Mumbai, plus seed jamat times for 5 test masjids
  - Nearby list and map, masjid detail, next-jamat highlight, location-denied fallback
  - Widget smoke tests at the four sizes, light and dark
- **Phase 2 — Community**
  - Auth (Google + email OTP), custom SMTP, redirect URLs
  - time_suggestions and suggestion_votes, `masjid_times` RPC with the trust rules, abuse trigger, pgTAP for every trust rule
  - Suggest times, voting, add missing masjid
  - Settings screen (theme, sign out, version)
- **Phase 3 — Admins + web + release**
  - Claim flow and proof upload (private bucket, storage policies tested)
  - Admin time management and admin inbox; super admin review queues
  - History trigger, staleness rule, moderation log
  - Web landing page at `/`, `/m/:slug` pages
  - Vercel: `vercel.json`, `tools/vercel_build.sh`, Site URL switched to the Vercel domain
  - Shorebird: `shorebird init`, first `release` APK/AAB; later Dart-only fixes ship as `patch`
  - Android release signing (upload key in Jenkins credentials, never the debug key)
  - Jenkins deploy job: `BRANCH` + `TARGET` (`all` | `web` | `patch` | `release` | `db`), APKs archived on the build page and in `dist/`
  - `tools/verify_remote.sh` against prod; three-account RLS check (user, masjid admin, super admin) repeated on prod
  - Settings: download my data, delete my account; `delete-account` and `purge-claims` Edge Functions
  - Legal pages, Play Data safety + Apple App Privacy forms from the SDK list in CHECKLISTS.md
  - Sentry (prod only, PII off); admin features as deferred imports on web
- **Before launch** (CHECKLISTS.md)
  - `backup-prod` Jenkins job + off-site locked bucket; first restore test passed and recorded
  - Slow-phone and Slow-4G test passed; every unticked CHECKLISTS.md item is either done or has a reason in `NOTES.md`

## Definition of done (every feature)
- `./tools/check.sh` green: format, analyze 0 issues, Dart tests, pgTAP tests.
- Shipped to staging and checked there before prod.
- Related CHECKLISTS.md items ticked.
- Loading, empty and error states handled and visible in the widget smoke test.
- Strings in ARB, no hardcoded colors/sizes.
- `NOTES.md` updated with any deviation from this PRD and anything still open.

## v1.1 candidates (not in v1)
- **Printable timetable:** a masjid admin downloads an A4 PDF of the masjid's current times with a QR code to `/m/:slug`, to pin on the notice board. Browser download on web, share sheet on mobile (conditional-import helper, no `file_saver`).
- **iOS release lane in Jenkins** (Shorebird iOS release + TestFlight upload).
- **Admin invites by email** via an Edge Function (needs the service role key, so never from the client).

## Out of scope for v1
- Push notifications and jamat reminders
- Calculated prayer (azaan) times, qibla, Hijri calendar
- Saved or favourite masjids
- A separate admin app
- Phone OTP login
- Events, donations, announcements, chat
- UI in any language other than English (strings are ARB-ready; masjid names can be in Arabic or Urdu)
- An SEO-optimised static website
- Offline mode beyond Flutter's default caching
