import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../error/failures.dart';
import '../theme/app_spacing.dart';

/// Plain-language error + Retry. The raw detail sits behind a collapsed
/// "Technical details" line so a bug-report screenshot still carries it.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  static String messageFor(AppLocalizations l10n, Failure f) => switch (f) {
    NetworkFailure() => l10n.errorNetwork,
    PermissionFailure() => l10n.errorPermission,
    NotFoundFailure() => l10n.errorNotFound,
    SessionExpiredFailure() => l10n.errorSessionExpired,
    ServerFailure() => l10n.errorServer,
    LocationFailure() => l10n.errorLocation,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = failure.detail;
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: AppSpacing.emptyIcon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            messageFor(l10n, failure),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
          if (detail != null && detail.isNotEmpty)
            ExpansionTile(
              title: Text(
                l10n.technicalDetails,
                style: theme.textTheme.bodySmall,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              children: [
                SelectableText(
                  '${failure.runtimeType}: $detail',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
