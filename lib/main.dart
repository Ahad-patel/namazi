import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bootstrap.dart';
import 'core/di/injector.dart';
import 'core/network/network_info.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/app_frame.dart';
import 'l10n/gen/app_localizations.dart';

void main() => bootstrap(NamaziApp.new);

class NamaziApp extends StatefulWidget {
  const NamaziApp({super.key});

  @override
  State<NamaziApp> createState() => _NamaziAppState();
}

class _NamaziAppState extends State<NamaziApp> {
  late final _router = createRouter();
  late final _online = sl<NetworkInfo>().onStatusChange;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: sl<ThemeCubit>(),
    child: BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
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
        routerConfig: _router,
        builder: (context, child) =>
            AppFrame(online: _online, child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}
