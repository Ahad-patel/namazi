class AppConstants {
  const AppConstants._();

  static const appName = 'Masjid Timer';

  /// Contact + grievance address (DPDP) in Settings → About and the legal
  /// pages in web/.
  // ponytail: placeholder (.invalid never resolves) until the owner picks
  // the real address; change it here and in web/*.html together.
  static const contactEmail = 'contact@masjid-timer.invalid';

  /// Default nearby radius (PRD: 3 km). "Search a wider area" uses [wideRadiusM].
  static const nearbyRadiusM = 3000;
  static const wideRadiusM = 10000;

  static const requestTimeout = Duration(seconds: 10);
  static const locationTimeout = Duration(seconds: 8);
  static const searchDebounce = Duration(milliseconds: 350);
  static const timesCacheTtl = Duration(minutes: 5);

  /// Admin queues, moderation log, inbox: `.range()` pages of 25.
  static const pageSize = 25;
  static const proofUrlTtlSeconds = 300;

  /// Average walking pace used for "distance · walking time".
  static const walkingMetresPerMinute = 80;

  /// Two-column list + map from this width up (DESIGN.md).
  static const wideBreakpoint = 900.0;
  static const maxContentWidth = 1180.0;
}
