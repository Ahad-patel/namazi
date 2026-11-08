import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

enum SkeletonShape { card, row }

/// Skeleton placeholders shaped like the real content (DESIGN.md: no
/// full-screen spinners).
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.shape = SkeletonShape.card,
    this.count = 6,
  });

  final SkeletonShape shape;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: List.generate(
          count,
          (_) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: shape == SkeletonShape.card
                ? const _SkeletonCard()
                : const _SkeletonRow(),
          ),
        ),
      ),
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final c = context.tokens.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.outline),
      ),
      child: const Row(
        children: [
          _Bone(width: AppSpacing.leadingTile, height: AppSpacing.leadingTile),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: 0.7, child: _Bone()),
                SizedBox(height: AppSpacing.sm),
                FractionallySizedBox(widthFactor: 0.4, child: _Bone()),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          _Bone(width: AppSpacing.xxl * 2),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: AppSpacing.rowHeight,
    child: Row(
      children: [
        Expanded(flex: 3, child: _Bone()),
        SizedBox(width: AppSpacing.xl),
        Expanded(flex: 2, child: _Bone()),
        SizedBox(width: AppSpacing.xl),
        Expanded(flex: 2, child: _Bone()),
      ],
    ),
  );
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, this.height = AppSpacing.skeletonLine});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.tokens.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );
}
