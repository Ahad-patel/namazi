import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/nearby_masjid.dart';
import 'countdown.dart';
import 'formatters.dart';
import 'masjid_name.dart';
import 'time_text.dart';

/// The one gold-highlighted thing on the nearby screen: soonest jamat in the
/// radius, with a live countdown.
class NextJamatBanner extends StatelessWidget {
  const NextJamatBanner({
    super.key,
    required this.next,
    required this.onTap,
    required this.onPassed,
  });

  final NearbyMasjid next;
  final VoidCallback onTap;
  final VoidCallback onPassed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final time = next.next!;
    final prayer = prayerName(l10n, time.prayer);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: c.onSurface.withValues(alpha: 0.06),
            blurRadius: AppSpacing.lg,
          ),
        ],
      ),
      child: Material(
        color: c.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.nextJamat,
                        style: tokens.label.copyWith(color: c.onPrimary),
                      ),
                    ),
                    if (time.nextAt != null)
                      Countdown(
                        target: time.nextAt!,
                        onPassed: onPassed,
                        builder: (context, left) {
                          final d = countdownText(l10n, left);
                          return Semantics(
                            label: l10n.nextJamatSemantics(
                              prayer,
                              next.masjid.name,
                              d,
                            ),
                            excludeSemantics: true,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                d,
                                style: tokens.label.copyWith(color: c.onAccent),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      prayer,
                      style: tokens.timeLg.copyWith(color: c.onPrimary),
                    ),
                    TimeText(
                      time.jamat,
                      style: tokens.timeLg,
                      color: c.onPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                MasjidName(
                  next.masjid,
                  style: Theme.of(context).textTheme.bodyMedium,
                  color: c.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
