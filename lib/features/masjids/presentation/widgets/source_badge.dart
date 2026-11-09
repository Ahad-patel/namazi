import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/prayer.dart';
import 'formatters.dart';

/// "Verified · 3 Nov" or "Community · 3 Nov". Tap explains the source.
class SourceBadge extends StatelessWidget {
  const SourceBadge({
    super.key,
    required this.source,
    required this.updatedAt,
    this.netVotes,
  });

  final TimeSource source;
  final DateTime updatedAt;

  /// Community only: shown in the explanation sheet.
  final int? netVotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.tokens.colors;
    final date = shortDate(l10n, updatedAt);
    final verified = source == TimeSource.verified;
    final fg = verified ? c.verified : c.onSurfaceVariant;
    return Semantics(
      button: true,
      label: verified
          ? l10n.badgeVerifiedSemantics(date)
          : l10n.badgeCommunitySemantics(date),
      excludeSemantics: true,
      child: Material(
        color: verified ? c.verifiedContainer : c.surface,
        shape: StadiumBorder(
          side: verified ? BorderSide.none : BorderSide(color: c.outline),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _explain(context, verified),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.badgeHorizontal,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verified) ...[
                  Icon(Icons.check, size: AppSpacing.lg, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    verified
                        ? l10n.badgeVerified(date)
                        : l10n.badgeCommunity(date),
                    style: context.tokens.caption.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _explain(BuildContext context, bool verified) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verified ? l10n.sourceVerifiedTitle : l10n.sourceCommunityTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                verified
                    ? l10n.sourceVerifiedBody
                    : netVotes == null
                    ? l10n.sourceCommunityBody
                    : l10n.sourceCommunityBodyVotes(netVotes!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
