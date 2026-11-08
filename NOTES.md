# Notes

## Decisions that differ from PRD / earlier drafts
- **BLoC + clean architecture, not Riverpod.** Matches the owner's `qqc_management` and `marc_management` repos: `flutter_bloc`, `get_it` (`lib/core/di/injector.dart`), `dartz` `Either<Failure, T>`, `lib/features/<f>/{data,domain,presentation}`. One way of working across all three apps.
- **Single Flutter package at the repo root, no monorepo.** The `flutter create` output (`namazi`, `com.ska.namazi`) stays as generated; generated files are only edited to add code, permissions or config.
- **No freezed / json_serializable / build_runner.** Equatable entities, sealed bloc events/states, hand-written `fromJson`. Same as the reference repos; the only codegen is `flutter gen-l10n`.

## Open questions
- None yet.

## Verified
- Nothing built yet (docs-only change).

## Still to do
- Phase 1 skeleton per PRD.md: `lib/core/` (env, di, error, router, theme, widgets), bootstrap, l10n, `tools/check.sh`.
