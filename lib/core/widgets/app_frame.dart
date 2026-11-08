import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../config/env.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

/// Wraps every route (MaterialApp.builder): the non-prod environment strip on
/// top and the offline banner below it.
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
    required this.online,
    this.appEnv = Env.appEnv,
  });

  final Widget child;
  final Stream<bool> online;
  final String appEnv;

  @override
  Widget build(BuildContext context) {
    final c = context.tokens.colors;
    final showStrip = appEnv != 'prod';
    final topInset = MediaQuery.paddingOf(context).top;
    return Material(
      color: c.background,
      child: Column(
        children: [
          if (showStrip)
            Container(
              color: c.error,
              padding: EdgeInsetsDirectional.only(top: topInset),
              height: AppSpacing.envStripHeight + topInset,
              alignment: AlignmentDirectional.center,
              child: Text(
                appEnv.toUpperCase(),
                style: context.tokens.label.copyWith(color: c.surface),
                textScaler: TextScaler.noScaling,
              ),
            ),
          _OfflineBanner(online: online),
          Expanded(
            child: showStrip
                ? MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: child,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.online});

  final Stream<bool> online;

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: online,
    initialData: true,
    builder: (context, snap) {
      if (snap.data ?? true) return const SizedBox.shrink();
      final c = context.tokens.colors;
      return Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: AppSpacing.offlineBannerHeight,
          ),
          color: c.surfaceVariant,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            AppLocalizations.of(context).offline,
            style: context.tokens.label.copyWith(color: c.onSurface),
          ),
        ),
      );
    },
  );
}
