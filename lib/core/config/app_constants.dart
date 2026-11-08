class AppConstants {
  const AppConstants._();

  static const appName = 'Masjid Timer';

  /// Default nearby radius (PRD: 3 km). "Search a wider area" uses [wideRadiusM].
  static const nearbyRadiusM = 3000;
  static const wideRadiusM = 10000;

  static const requestTimeout = Duration(seconds: 10);
  static const locationTimeout = Duration(seconds: 8);
  static const searchDebounce = Duration(milliseconds: 350);
  static const timesCacheTtl = Duration(minutes: 5);

  /// Average walking pace used for "distance · walking time".
  static const walkingMetresPerMinute = 80;

  /// Two-column list + map from this width up (DESIGN.md).
  static const wideBreakpoint = 900.0;
  static const maxContentWidth = 1180.0;
}
