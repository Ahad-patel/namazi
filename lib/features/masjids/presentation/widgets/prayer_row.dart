import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_time.dart';
import 'countdown.dart';
import 'formatters.dart';
import 'source_badge.dart';
import 'time_text.dart';

/// Namaz (label + badge) · azaan · jamat. [time] null = "Not available".
class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.prayer,
    this.time,
    this.isNext = false,
    this.onPassed,
    this.onSuggest,
  });

  final Prayer prayer;
  final PrayerTime? time;
  final bool isNext;
  final VoidCallback? onPassed;

  /// "Suggest" link under a missing time.
  final VoidCallback? onSuggest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final theme = Theme.of(context);
    final t = time;
    final fg = isNext ? c.onAccentContainer : c.onSurface;
    final subtle = isNext ? c.onAccentContainer : c.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.rowHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isNext ? c.accentContainer : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerName(l10n, prayer),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: tokens.label.fontWeight,
                  ),
                ),
                if (isNext && t?.nextAt != null)
                  Countdown(
                    target: t!.nextAt!,
                    onPassed: onPassed,
                    builder: (context, left) => Text(
                      l10n.nextIn(countdownText(l10n, left)),
                      style: tokens.caption.copyWith(color: subtle),
                    ),
                  ),
                if (t != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SourceBadge(
                    source: t.source,
                    updatedAt: t.updatedAt,
                    netVotes: t.netVotes,
                  ),
                  if (t.stale) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.mayBeOutdated,
                      style: tokens.caption.copyWith(
                        color: isNext ? fg : c.error,
                      ),
                    ),
                    if (t.communityJamat != null)
                      _CommunityLine(
                        time: t.communityJamat!,
                        style: tokens.caption.copyWith(color: subtle),
                      ),
                  ],
                  if (t.differingReports > 0)
                    Text(
                      l10n.differingReports(t.differingReports),
                      style: tokens.caption.copyWith(color: subtle),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: t?.azaan == null
                ? Text('—', style: tokens.time.copyWith(color: subtle))
                : TimeText(t!.azaan!, style: tokens.time, color: subtle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: t == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('—', style: tokens.time.copyWith(color: subtle)),
                        Text(
                          l10n.notAvailable,
                          textAlign: TextAlign.end,
                          style: tokens.caption.copyWith(color: subtle),
                        ),
                        if (onSuggest != null)
                          TextButton(
                            onPressed: onSuggest,
                            child: Text(l10n.suggest, textAlign: TextAlign.end),
                          ),
                      ],
                    )
                  : TimeText(t.jamat, style: tokens.time, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Community: 1:35 PM" under a stale verified time.
class _CommunityLine extends StatelessWidget {
  const _CommunityLine({required this.time, required this.style});

  final ClockTime time;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('${AppLocalizations.of(context).communityPrefix} ', style: style),
      TimeText(time, style: style),
    ],
  );
}
