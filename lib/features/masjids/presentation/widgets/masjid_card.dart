import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/nearby_masjid.dart';
import 'formatters.dart';
import 'masjid_name.dart';
import 'source_badge.dart';
import 'time_text.dart';

class MasjidCard extends StatelessWidget {
  const MasjidCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final NearbyMasjid item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final theme = Theme.of(context);
    final next = item.next;
    // At large text sizes the trailing column would squeeze the name, so the
    // next jamat moves under it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    Widget nextJamat(CrossAxisAlignment align) => Column(
      crossAxisAlignment: align,
      children: [
        Text(
          next == null ? l10n.noTimeYet : prayerName(l10n, next.prayer),
          style: tokens.label.copyWith(color: c.onSurfaceVariant),
        ),
        if (next != null)
          TimeText(next.jamat, style: tokens.time, color: c.onSurface),
      ],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: AppSpacing.leadingTile,
                  height: AppSpacing.leadingTile,
                  alignment: AlignmentDirectional.center,
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: tokens.label.copyWith(color: c.onPrimaryContainer),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MasjidName(item.masjid),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      distanceWalkText(l10n, item.distanceM),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    if (stacked) ...[
                      const SizedBox(height: AppSpacing.sm),
                      nextJamat(CrossAxisAlignment.start),
                    ],
                    if (next != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SourceBadge(
                        source: next.source,
                        updatedAt: next.updatedAt,
                      ),
                    ],
                  ],
                ),
              ),
              if (!stacked) ...[
                const SizedBox(width: AppSpacing.md),
                nextJamat(CrossAxisAlignment.end),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
