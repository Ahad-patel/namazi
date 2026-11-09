import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namazi/core/theme/app_theme.dart';
import 'package:namazi/l10n/gen/app_localizations.dart';

/// DESIGN.md smoke sizes.
const smokeSizes = [
  Size(360, 800),
  Size(390, 844),
  Size(900, 1024),
  Size(1440, 900),
];

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    required Size size,
    ThemeMode mode = ThemeMode.light,
    double textScale = 1,
  }) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => child)],
    );
    addTearDown(router.dispose);
    await pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
    );
    await pump();
  }
}
