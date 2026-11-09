import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/di/injector.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}

/// Sets up Supabase and DI, then runs [builder]. A build without config shows
/// a screen saying what's missing, never a blank page.
Future<void> bootstrap(Widget Function() builder) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();
    Bloc.observer = const AppBlocObserver();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };
    _registerFontLicences();

    if (!Env.isConfigured) {
      runApp(const _MisconfiguredApp());
      return;
    }

    if (Env.sentryEnabled) await _initSentry();

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    await configureDependencies();

    runApp(builder());
  }, _reportError);
}

void _reportError(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error');
  if (stack != null) debugPrintStack(stackTrace: stack);
  if (Env.sentryEnabled) Sentry.captureException(error, stackTrace: stack);
}

/// PII off, and no HTTP breadcrumbs: request URLs can carry a searched area
/// or map tile coordinates, and user location never leaves the device
/// except as a query parameter (CLAUDE.md privacy rules).
Future<void> _initSentry() => SentryFlutter.init((o) {
  o
    ..dsn = Env.sentryDsn
    ..environment = Env.appEnv
    ..sendDefaultPii = false
    ..tracesSampleRate = 0.2
    ..beforeBreadcrumb = (crumb, _) =>
        crumb?.category == 'http' || crumb?.type == 'http' ? null : crumb;
});

void _registerFontLicences() {
  const fonts = {
    'Manrope': 'assets/fonts/Manrope-OFL.txt',
    'Noto Naskh Arabic': 'assets/fonts/NotoNaskhArabic-OFL.txt',
    'Noto Nastaliq Urdu': 'assets/fonts/NotoNastaliqUrdu-OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
}

/// Renders before the theme exists, so this is the one place colours and
/// strings are literal (DESIGN.md).
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1B2A4A),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(32),
          child: Text(
            'This build is not configured.\n\n'
            'Missing: ${Env.missingKeys.join(', ')}\n\n'
            'Rebuild with --dart-define-from-file=env.<local|staging|prod>.json',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFFFFF), height: 1.6),
          ),
        ),
      ),
    ),
  );
}
