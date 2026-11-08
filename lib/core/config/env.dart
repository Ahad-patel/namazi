/// Build-time configuration, passed with
/// `--dart-define-from-file=env.<local|staging|prod>.json`.
/// Nothing secret lives here: the anon key and MapTiler key ship in every
/// build by design. RLS is the guard.
class Env {
  const Env._();

  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const termsVersion = String.fromEnvironment('TERMS_VERSION');

  static bool get isProd => appEnv == 'prod';

  /// Required keys that are empty in this build.
  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    if (mapTilerKey.isEmpty) 'MAPTILER_KEY',
  ];

  static bool get isConfigured => missingKeys.isEmpty;
}
