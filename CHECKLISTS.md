# Launch checklists

Three external checklists mapped onto Masjid Timer. Every item is either a concrete task with the phase it lands in, or marked **N/A** with the reason. Tick items as they are done and verified; note how it was verified in `NOTES.md`.

Sources (BreakingBreach guides): *Protect Your App from Data Loss* (20 controls), *App-Performance Toolkit* (31 fixes), *App Launch Checklist* (35 checks).

What the app holds, for reference: masjid data (partly derived from OpenStreetMap), community suggestions and votes, user email + display name (Google or OTP), claimant phone numbers and proof photos. No payments, no subscriptions, no marketing email, no AI, no ads, no stored user location.

---

## 1. Data loss (20 controls)

### Separate environments
- [ ] **Separate test and production databases.** Three Supabase projects: local (`supabase start`), `masjid-timer-staging`, `masjid-timer-prod`. Prod is never used for testing or seeding. (Phase 1, staging by Phase 2)
- [ ] **Make production unmistakable.** `APP_ENV` dart-define (`local` | `staging` | `prod`). Non-prod builds show a persistent "STAGING" strip in the app bar (`error` color) and a different app name/icon suffix. Jenkins job names and the Supabase project names carry the env. (Phase 1)
- [ ] **Separate credentials per environment.** `env.local.json`, `env.staging.json`, `env.prod.json`; Jenkins secret files `masjid-env-staging` and `masjid-env-prod`. The DB password and `SUPABASE_ACCESS_TOKEN` for `db push` are per env too. Nobody's laptop has the prod DB password in a file. (Phase 1)

### Stop bad deletes before they happen
- [ ] **Restrict bulk deletes to authorized users.** No table has a client `delete` policy except `suggestion_votes` (a user removing their own vote). Everything else is removed by changing `status`, through RPCs gated on role. (Phase 1, enforced by pgTAP)
- [ ] **Limit how many records one action can delete.** Moderation RPCs take exactly one id (`hide_suggestion(id)`, `ban_user(id)`, `hide_masjid(id)`). No "hide all from user" in v1. If one is added later, it caps at 50 rows and raises above that. (Phase 3)
- [ ] **Require explicit authorization for destructive prod actions.** Jenkins `db` target runs on staging first; prod needs a separate run with `TARGET=db` and `ENV=prod`, plus an input step ("Type PROD to continue"). Migrations that `drop` or `truncate` anything need a `-- destructive: <reason>` header, and `tools/check.sh` fails on a drop without it. (Phase 3)
- [ ] **Turn on deletion protection for the database resource.** Supabase has no per-project delete lock, so: org has only the owner as Owner, everyone else Developer or Read-only; MFA on every Supabase, Vercel, GitHub and Jenkins account; prod project in its own org if collaborators join. (Phase 1)
- [ ] **Enforce delete permissions and limits on the server.** Covered by RLS + RPC checks above; the UI only hides buttons. pgTAP tests try a delete as every role and expect failure. (Phase 1–3)
- [ ] **Preview the records a bulk action will affect.** Only bulk-ish action is banning a user: the confirm dialog shows "This hides N open suggestions by <name>" before the ban. (Phase 3)
- [ ] **Typed confirmation for high-impact deletes.** Hide masjid, ban user, revoke admin, delete own account: the confirm button stays disabled until the masjid name / user name / "DELETE" is typed. Shared `ConfirmDestructiveDialog` in `packages/ui`. (Phase 3)
- [ ] **Let users restore eligible items from Trash.** Soft delete everywhere: `masjids.status = hidden`, `time_suggestions.status = hidden`, `masjid_admins.status = revoked`. Super admin has a "Hidden" tab with Restore. Nothing is hard-deleted from the client. (Phase 3)
- [ ] **Versioning for file storage.** Supabase Storage has no versioning, so proof photos are write-once: path `<user_id>/<claim_id>.jpg`, insert policy only, no `update` or `delete` policy for clients. A new claim gets a new path. (Phase 3)
- [ ] **Test migrations on a staging copy first.** Every migration: `supabase db reset` locally + pgTAP green → `db push` to staging → `verify_remote.sh` on staging → app smoke on staging → then prod. Before a risky migration, restore last night's prod dump into staging and run it there. (Phase 2 on)

### Recover when they happen anyway
- [ ] **Automatic backups of DB and uploaded files.** Supabase Pro plan for prod (the free plan has no backups). Plus our own nightly Jenkins job `backup-prod`: `supabase db dump --data-only` and `--schema` (via pg_dump), and an `rclone sync` of the `claim-proofs` bucket. (Before launch)
- [ ] **Point-in-time recovery.** PITR add-on on prod once there's real community data worth more than a day's loss. Until then, the daily backup is the ceiling; noted in `NOTES.md`. (After launch, when traffic justifies it)
- [ ] **A backup live credentials can't delete.** The nightly dump goes to an off-Supabase bucket (Backblaze B2 or Cloudflare R2) with object lock / retention 30 days. The upload key is write-only; the app and Supabase hold no credential for it. (Before launch)
- [ ] **Alert on backup failures and unusual deletes.** Jenkins emails on `backup-prod` failure. A daily `moderation_report` query (part of the same job) emails if more than 20 hide/ban/revoke actions happened in 24h or the `masjids` active count dropped by more than 1%. (Before launch)
- [ ] **Log who deleted what, and when.** `moderation_log` (trigger-written, super admin read-only) and `jamat_time_history`. Triggers branch on `tg_op` and log `before`/`after` jsonb. (Phase 3)
- [ ] **Test a restore in an isolated environment.** Monthly: restore the latest dump into a fresh local `supabase start`, run `supabase test db`, run row-count checks against the numbers in the backup log. Write the date and result in `NOTES.md`. (Before launch, then monthly)
- [ ] **Verify the app works with restored data.** Point a local build at the restored stack (`env.local.json`), open nearby, a masjid detail, an admin inbox, a proof photo. Record in `NOTES.md`. (With each restore test)

---

## 2. Performance (31 fixes)

### UI feel
- [ ] **Skeleton loading screens.** `StateView` loading = skeleton masjid cards / prayer rows (DESIGN.md). (Phase 1)
- [ ] **Optimistic UI.** Votes update the count and arrow immediately and roll back with a snackbar on error. Suggestion submit shows the row as "Sending…" in the list. (Phase 2)
- [ ] **Prevent unnecessary re-renders.** The next-jamat countdown ticks inside its own small widget (one `Timer.periodic` per minute, not per second, aligned to the minute), never by rebuilding the screen. `ref.watch(p.select(...))` for single fields; `const` constructors everywhere the linter allows. (Phase 1)
- [ ] **Virtualize long lists.** `ListView.builder` / `SliverList.builder` for nearby, search results, admin queues, moderation log. Never `Column` of a mapped list. (Phase 1)
- [ ] **Lazy-load images below the screen.** Only images are map tiles (loaded per viewport by flutter_map) and proof photos (loaded only when the super admin opens a claim, via short-lived signed URL). (Phase 3)
- [ ] **Debounce search inputs.** Area search waits 350ms after the last keystroke and cancels the previous request. (Phase 1)

### Network and API
- [ ] **Prevent duplicate API calls.** Riverpod providers are the only fetch path, so two widgets watching the same provider share one request. `masjid_times(id)` is `keepAlive` for 5 minutes. No fetch in `build()`. (Phase 1)
- [ ] **Paginate API results.** `nearby_masjids` returns at most 50 rows ordered by distance. Admin queues, moderation log and suggestions use `.range()` pages of 25. (Phase 1/3)
- [ ] **Select only the columns you need.** Never `.select()` / `.select('*')`; always list the columns. RPCs return only what the screen shows. (Phase 1, reviewed in code review)
- [ ] **Fix N+1 queries.** The nearby list must not call `masjid_times` per card. `nearby_masjids` returns each masjid's next jamat (name, time, source) in the same query, and `next_jamat_nearby` gives the banner in one call. (Phase 1)
- [ ] **Run independent requests in parallel.** Detail page: masjid row and `masjid_times` together (`Future.wait` or two providers), not chained. Startup: location permission and the cached session in parallel. (Phase 1)
- [ ] **Timeouts for external calls.** `guardPg` wraps every Supabase call in `.timeout(const Duration(seconds: 10))` → `NetworkException`. `geolocator` uses `timeLimit: 8s` then falls back to last known position, then to area search. (Phase 1)
- [ ] **Stream AI responses.** N/A, no AI.
- [ ] **Move slow tasks to a background job queue.** N/A in-app. The only slow jobs (OSM import, backups, proof purge) already run outside the request path (script, Jenkins, scheduled Edge Function).

### Database
- [ ] **Indexes for common queries.** In the migration that creates each table: GIST on `masjids(location)`; unique `masjids(slug)`; `jamat_times(masjid_id, prayer, valid_from desc)`; `time_suggestions(masjid_id, prayer, status)` and `(suggested_by, created_at)` for the 10-a-day trigger; `masjid_admins(user_id, status)`; `moderation_log(created_at desc)`. Check `explain analyze` of `nearby_masjids` on the Mumbai import. (Phase 1–3)
- [ ] **Connection pooling.** The app goes through PostgREST, already pooled. `tools/osm_import` and backup scripts connect through the Supavisor pooler (port 6543), not direct. (Phase 1)
- [ ] **Cache frequently accessed data with Redis.** N/A. Data is small and read-mostly; Riverpod `keepAlive` plus HTTP caching cover it. Revisit only if `nearby_masjids` p95 > 300ms under real load.
- [ ] **Trace slow backend requests.** No OpenTelemetry in v1. Use Supabase dashboard → Query Performance (`pg_stat_statements`) monthly; anything > 100ms mean gets an index or a rewrite. App side: Sentry performance traces on the four main screens (below). (Before launch)
- [ ] **Place servers close to the database.** Supabase prod and staging in `ap-south-1` (Mumbai), same as the users. Edge Functions run in that region. (Phase 1)
- [ ] **Load-balance across app instances.** N/A. Vercel and Supabase are managed; nothing of ours runs as a server.

### Web delivery
- [ ] **Serve static files through a CDN.** Vercel edge serves the web build; MapTiler serves tiles from its CDN. (Phase 3)
- [ ] **Brotli / Gzip compression.** Vercel compresses automatically. Verify `content-encoding: br` on `main.dart.js` after the first deploy. (Phase 3)
- [ ] **Browser caching for static files.** `vercel.json` headers: hashed assets immutable, entry files must-revalidate. (Phase 3)
- [ ] **Split JavaScript by page.** The admin and super-admin features are imported with `deferred as` so the web user never downloads them. (Phase 3)
- [ ] **Render on the server or at build time.** N/A for the Flutter app (no SSR). The static legal pages (`privacy.html`, `terms.html`) are plain HTML in `web/`. `web/index.html` shows a lightweight HTML splash (logo + "Loading…" in token colors) until Flutter's first frame. (Phase 3)
- [ ] **Load third-party scripts after the page.** No third-party web scripts in v1. If one is ever added, it loads after first frame.
- [ ] **Self-host fonts, limit weights.** Fonts bundled (DESIGN.md). Manrope only at 500, 600, 700, 800. Noto Nastaliq Urdu is large: ship one weight (600) only. (Phase 1)
- [ ] **WebP / AVIF images.** Proof photos are resized on device before upload: `image_picker` with `maxWidth: 1600, imageQuality: 80` (JPEG; no extra dependency). App icons and any illustration assets as WebP. (Phase 3)
- [ ] **Remove unused dependencies.** Before each release: check `pubspec.yaml` of every package against its imports; remove anything unused. `flutter build web --analyze-size` and `flutter build apk --analyze-size` numbers go in `NOTES.md` so growth is visible. (Each release)

### Measure
- [ ] **Real-user performance monitoring.** `sentry_flutter` in prod builds only (`SENTRY_DSN` dart-define, empty = off): crashes, unhandled errors from `bootstrap.dart`, and performance traces for app start, nearby, detail, map. `sendDefaultPii: false`, no location or email in events. Disclosed in the privacy policy. (Phase 3)
- [ ] **Test on slow phones and networks.** Before each release: one low-end Android (≤ 3 GB RAM) in `flutter run --profile`, no jank on nearby scroll or map pan; web in Chrome DevTools with "Slow 4G" + 4× CPU throttle, landing usable in < 5s. Result in `NOTES.md`. (Before launch, then each release)

---

## 3. Legal, privacy, accessibility, trust (35 checks)

### Policies and acceptance
- [ ] **Privacy policy.** `web/privacy.html` (static, served by Vercel at `/privacy.html`, linked from the landing page, Settings, sign-in screen and both store listings). Covers: what's collected (email, display name, suggestions, votes, claim phone + photo), what isn't (location is used on device and sent only as a query, never stored or logged), processors, retention, rights, contact, children. Written for India's DPDP Act 2023 first, GDPR-compatible. (Phase 3, before store submission)
- [ ] **Terms of service.** `web/terms.html`: community content rules, no guarantee times are correct ("confirm with the masjid"), we may hide content and ban, OSM attribution, governing law (India). (Phase 3)
- [ ] **Checkbox to accept privacy policy and terms.** First sign-in shows "I agree to the Terms and Privacy Policy" (unticked, links open the pages) before the account can contribute. Browsing needs no account and no acceptance. (Phase 2)
- [ ] **Terms acceptance records.** `profiles.terms_version text`, `profiles.terms_accepted_at timestamptz`, set through an RPC. When `TERMS_VERSION` changes, the app asks again on next contribution. (Phase 2)
- [ ] **Refund policy.** N/A, free app, no purchases.
- [ ] **Business contact details.** One contact email (also the data-protection / grievance contact DPDP requires) in the privacy policy, terms, Settings → About, and store listings. (Phase 3)

### Consent and tracking
- [ ] **Cookie banner.** N/A as long as the web app uses only strictly necessary storage (Supabase session in localStorage, theme preference). Adding any analytics or ad SDK re-opens this item.
- [ ] **Trackers off until consent.** No trackers in v1. Sentry is error monitoring with PII off, disclosed in the policy; on the web it does not set cookies.
- [ ] **Separate marketing consent.** N/A, no marketing communication. OTP emails are transactional only.
- [ ] **Unsubscribe option in marketing emails.** N/A for the same reason. If a newsletter is ever added, it needs its own opt-in and an unsubscribe link.

### User data
- [ ] **Stop collecting unnecessary data.** No birth date, no gender, no stored location, no contacts. `nearby_masjids` lat/lng are never written to a table, and the RPC must not `raise notice` them (Postgres logs). Phone number is asked only in the claim form. (Phase 1–3)
- [ ] **Data retention limits.** Claim phone numbers and proof photos are deleted 90 days after the claim is decided (scheduled Edge Function `purge-claims`, daily, via `pg_cron` + `pg_net`; it deletes objects through the Storage API, not by deleting `storage.objects` rows). Superseded suggestions kept 1 year, then deleted. Banned-user records kept while the ban stands. Stated in the privacy policy. (Phase 3)
- [ ] **Data access and deletion requests.**
  - Settings → **Download my data**: `my_data()` RPC returns the user's profile, suggestions, votes and claims as JSON; saved through the conditional-import download helper. (Phase 3)
  - Settings → **Delete my account**: typed confirmation, then Edge Function `delete-account` (service role, server side only) deletes the auth user, profile, votes, claims and proof photos, and sets `time_suggestions.suggested_by = null` so community times survive anonymously. Required in-app by both stores. (Phase 3)
  - Public **web deletion page** `web/delete-account.html` (Play requires a URL that works without the app): explains in-app deletion and gives the contact email. (Phase 3)
- [ ] **Parental consent for children's data.** DPDP treats under-18s as children and requires verifiable parental consent. v1 avoids it: browsing is anonymous; creating an account asks "I am 18 or older" (required). Store target audience set to 13+ (not "designed for children"). Open question for the owner in `NOTES.md`. (Phase 2)
- [ ] **No unauthorized AI training on user data.** No AI use. Policy says user content is not used or sold for AI training.
- [ ] **Audit third-party SDKs, analytics, tracking.** List kept in the privacy policy and used to fill the Play **Data safety** form and Apple **App Privacy** labels: Supabase (auth, DB, storage), Google Sign-In, geolocator (on-device), flutter_map + MapTiler (tile requests send IP and viewed area to MapTiler), Sentry (crashes). Re-check on every dependency added. (Phase 3)
- [ ] **Data processing agreements.** Accept/sign the DPAs of Supabase, Vercel, MapTiler and Sentry (all offer them in their dashboards/legal pages). Save PDFs outside the repo. (Before launch)
- [ ] **Subprocessor list.** Section in `privacy.html`: Supabase (AWS ap-south-1), Vercel, MapTiler, Sentry, Google (sign-in), plus the email/SMTP provider. (Phase 3)

### Accessibility
- [ ] **Colour contrast.** `theme_contrast_test.dart` (CLAUDE.md, DESIGN.md). (Phase 1)
- [ ] **Alt text.** Every icon-only button has a `tooltip` (which is its semantic label); map pins, source badges and the countdown have `Semantics(label: ...)` ("Verified time, updated 3 November", "Next jamat Asr in 18 minutes"). Decorative icons `excludeFromSemantics`. A widget test checks `meetsGuideline(labeledTapTargetGuideline)` and `textContrastGuideline` on main screens. (Phase 1 on)
- [ ] **Keyboard navigation.** Web: Tab reaches every control in visual order, Enter/Space activates masjid cards and rows, visible focus ring (`outline` 2px in `primary`), Esc closes dialogs and sheets, map has keyboard zoom buttons. Tested by hand on Chrome each release. (Phase 3)

### Honest UI
- [ ] **Dark patterns.** No pre-ticked boxes, no confirm-shaming copy, Delete account as easy to find as Sign out.
- [ ] **Fake countdown timers.** The only countdown is the real time to the next jamat, from server data and the masjid's timezone.
- [ ] **Hidden fees.** N/A, free.
- [ ] **Auto-renewal disclosure.** N/A, no subscriptions.
- [ ] **Easy subscription cancellation.** N/A, no subscriptions.
- [ ] **Unsupported claims.** Never say "accurate" or "official" times. "Verified" is defined in-app (tap the badge: "Set by an approved admin of this masjid"). Store listing and landing page say times come from masjid admins and the community and may change. Masjid detail footer: "Times can change. Confirm with the masjid."
- [ ] **Fake reviews.** No seeded suggestions or votes in prod; `seed.sql` is for local and staging only. No incentivised store reviews.
- [ ] **False SOC 2 claims.** Don't claim any certification. Say "hosted on Supabase" at most.
- [ ] **Realistic uptime commitments.** No SLA or uptime promise anywhere.
- [ ] **Customer logos only with permission.** Don't show masjid logos or "used by X masjid" on the landing page or store listing without written permission from that masjid's committee.
- [ ] **AI-generated content labels.** N/A, no AI content. If store screenshots or artwork are AI-made, label them per store policy.

### Licences
- [ ] **Image, font and code licences.** Fonts are OFL (licence files bundled and registered with `LicenseRegistry.addLicense`), icons Material Symbols (Apache 2.0). No stock images. Settings → About → **Open-source licences** opens Flutter's `showLicensePage`. (Phase 1)
- [ ] **Open-source licence obligations.** Masjid locations from OpenStreetMap are under **ODbL**: show "© OpenStreetMap contributors" and "© MapTiler" on the map (flutter_map `RichAttributionWidget`) and on `/m/:slug`; the masjids table is a derivative database, so if it's offered publicly, it must be under ODbL too. Note this decision in `NOTES.md`. (Phase 1)
- [ ] **DMCA agent registration.** N/A unless the app targets the US. User content is short (names, notes, photos seen only by the super admin). Terms include a "report content" contact and a takedown process; register a DMCA agent if US users become a target.

### Store-specific (follows from the above)
- [ ] Android: `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` only, no background location. iOS: `NSLocationWhenInUseUsageDescription` = "Used to find masjids near you. Your location is not stored." (Phase 1)
- [ ] Play Console: Data safety form, account deletion URL, target audience, content rating, privacy policy URL. App Store Connect: App Privacy labels, privacy policy URL, in-app account deletion. (Phase 3)
