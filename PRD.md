# Masjid Timer — PRD (v1)

## Users
- **General user:** browses nearby masjids and their times. No login needed to browse.
- **Community contributor:** a logged-in user who suggests times, votes, or adds a missing masjid.
- **Masjid admin:** a logged-in user approved for a specific masjid. Their times are shown as verified.
- **Super admin (owner):** reviews admin claims and new masjids, and can hide abusive content.

## Auth
- Sign-in with Google or email OTP. Required for suggesting, voting, claiming and adding.
- `profiles.role`: `user` | `super_admin`. Admin rights are per masjid, stored in `masjid_admins`.

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

## Core tables (key columns)
- `profiles`: id (→auth.users), display_name, role, is_banned, created_at
- `masjids`: id, slug, name, name_local, name_script (`arab`|`urdu`|null), address, location geography(Point), timezone, facilities text[], status (`pending`|`active`|`hidden`), osm_id, created_by
- `masjid_admins`: masjid_id, user_id, status (`pending`|`approved`|`rejected`|`revoked`), role_at_masjid, phone, proof_path, reviewed_by, reviewed_at, reason
- `jamat_times` (verified, current): masjid_id, prayer (enum fajr|zuhr|asr|maghrib|isha|jummah), azaan_time, jamat_time, valid_from, updated_by, updated_at. Unique on (masjid_id, prayer, valid_from).
- `jamat_time_history`: jamat_times columns plus changed_at and changed_by (written by a trigger)
- `time_suggestions`: id, masjid_id, prayer, azaan_time, jamat_time, note, suggested_by, status (`open`|`accepted`|`rejected`|`superseded`|`hidden`), net_votes, created_at
- `suggestion_votes`: suggestion_id, user_id, value (−1|1). PK (suggestion_id, user_id).
- RPCs: `nearby_masjids(lat, lng, radius_m)`, `masjid_times(masjid_id)`, `next_jamat_nearby(lat, lng, radius_m)`

## Build order
- **Phase 1 — Browse (read-only)**
  - Monorepo, theme tokens, router, l10n setup
  - Migrations: profiles, masjids, jamat_times, RLS, PostGIS, the nearby RPC
  - OSM import for Mumbai, plus seed jamat times for 5 test masjids
  - Nearby list and map, masjid detail, next-jamat highlight, location-denied fallback
- **Phase 2 — Community**
  - Auth (Google + email OTP)
  - time_suggestions and suggestion_votes, `masjid_times` RPC with the trust rules, abuse trigger
  - Suggest times, voting, add missing masjid
- **Phase 3 — Admins + web**
  - Claim flow and proof upload (private bucket)
  - Admin time management and admin inbox; super admin review queues
  - History trigger, staleness rule
  - Web landing page at `/`, `/m/:slug` pages, release builds

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
