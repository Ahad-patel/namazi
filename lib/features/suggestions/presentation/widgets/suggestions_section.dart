import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/contributor_gate.dart';
import '../../../masjids/domain/entities/prayer.dart';
import '../bloc/suggestions_bloc.dart';
import 'suggestion_tile.dart';

/// "Community suggestions" on the masjid detail page, as one sliver group.
class SuggestionsSection extends StatelessWidget {
  const SuggestionsSection({super.key, required this.onSuggest});

  /// Opens the suggest sheet (after the contributor gate).
  final ValueChanged<Prayer?> onSuggest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SuggestionsBloc>();
    return BlocConsumer<SuggestionsBloc, SuggestionsState>(
      listenWhen: (a, b) =>
          b.voteFailure != null && a.voteFailure != b.voteFailure,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.voteFailed(ErrorView.messageFor(l10n, s.voteFailure!)),
          ),
        ),
      ),
      builder: (context, s) => SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.sm,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    l10n.communitySuggestions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => onSuggest(null),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.suggestTime),
                  ),
                ],
              ),
            ),
          ),
          switch (s.status) {
            SuggestionsStatus.initial ||
            SuggestionsStatus.loading => const SliverToBoxAdapter(
              child: LoadingView(shape: SkeletonShape.row, count: 2),
            ),
            SuggestionsStatus.empty => SliverToBoxAdapter(
              child: Text(
                l10n.noSuggestions,
                style: context.tokens.caption.copyWith(
                  color: context.tokens.colors.onSurfaceVariant,
                ),
              ),
            ),
            SuggestionsStatus.error => SliverToBoxAdapter(
              child: ErrorView(
                failure: s.failure!,
                onRetry: () => bloc.add(const SuggestionsRequested()),
              ),
            ),
            SuggestionsStatus.loaded => SliverList.separated(
              itemCount: s.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = s.items[i];
                return SuggestionTile(
                  suggestion: item,
                  onVote: (v) async {
                    if (!await ensureContributor(context)) return;
                    bloc.add(
                      SuggestionVoted(item.id, item.myVote == v ? 0 : v),
                    );
                  },
                );
              },
            ),
          },
        ],
      ),
    );
  }
}
