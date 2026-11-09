import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../masjids/presentation/widgets/formatters.dart';
import '../../../masjids/presentation/widgets/time_text.dart';
import '../../domain/entities/suggestion.dart';

/// Namaz · jamat (azaan, note), net votes with up/down. No vote buttons on
/// your own suggestion (RLS rejects it anyway).
class SuggestionTile extends StatelessWidget {
  const SuggestionTile({
    super.key,
    required this.suggestion,
    required this.onVote,
  });

  final Suggestion suggestion;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final theme = Theme.of(context);
    final s = suggestion;
    final caption = tokens.caption.copyWith(color: c.onSurfaceVariant);
    final note = s.note;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      prayerName(l10n, s.prayer),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: tokens.label.fontWeight,
                      ),
                    ),
                    TimeText(s.jamat, style: tokens.time, color: c.onSurface),
                  ],
                ),
                if (s.azaan != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${l10n.azaan} ', style: caption),
                      TimeText(s.azaan!, style: caption),
                    ],
                  ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(note, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.isMine
                      ? l10n.suggestedOnYours(shortDate(l10n, s.createdAt))
                      : l10n.suggestedOn(shortDate(l10n, s.createdAt)),
                  style: caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!s.isMine)
                IconButton(
                  tooltip: l10n.upvote,
                  isSelected: s.myVote == 1,
                  onPressed: () => onVote(1),
                  icon: const Icon(Icons.arrow_upward),
                  selectedIcon: Icon(Icons.arrow_upward, color: c.primary),
                ),
              Semantics(
                label: l10n.netVotesSemantics(s.netVotes),
                excludeSemantics: true,
                child: Text('${s.netVotes}', style: tokens.label),
              ),
              if (!s.isMine)
                IconButton(
                  tooltip: l10n.downvote,
                  isSelected: s.myVote == -1,
                  onPressed: () => onVote(-1),
                  icon: const Icon(Icons.arrow_downward),
                  selectedIcon: Icon(Icons.arrow_downward, color: c.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
