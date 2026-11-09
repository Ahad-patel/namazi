import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/directions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/contributor_gate.dart';
import '../../../suggestions/presentation/bloc/suggestions_bloc.dart';
import '../../../suggestions/presentation/widgets/suggest_time_sheet.dart';
import '../../../suggestions/presentation/widgets/suggestions_section.dart';
import '../../domain/entities/masjid.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_time.dart';
import '../bloc/masjid_detail_bloc.dart';
import '../widgets/masjid_name.dart';
import '../widgets/prayer_row.dart';

class MasjidDetailPage extends StatelessWidget {
  const MasjidDetailPage({super.key, required this.slug, this.known});

  final String slug;
  final Masjid? known;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            sl<MasjidDetailBloc>()
              ..add(MasjidDetailRequested(slug, known: known)),
      ),
      BlocProvider(create: (_) => sl<SuggestionsBloc>()),
    ],
    child: const MasjidDetailView(),
  );
}

class MasjidDetailView extends StatelessWidget {
  const MasjidDetailView({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          icon: const BackButtonIcon(),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // Suggestions load once the masjid id is known (a shared link
          // only has the slug).
          BlocListener<MasjidDetailBloc, MasjidDetailState>(
            listenWhen: (a, b) =>
                b.masjid != null && a.masjid?.id != b.masjid?.id,
            listener: (context, s) => context.read<SuggestionsBloc>().add(
              SuggestionsRequested(s.masjid!.id),
            ),
          ),
          // A submit or vote can change what masjid_times displays.
          BlocListener<SuggestionsBloc, SuggestionsState>(
            listenWhen: (a, b) => a.changes != b.changes,
            listener: (context, _) => context.read<MasjidDetailBloc>().add(
              const MasjidDetailRefreshed(),
            ),
          ),
        ],
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.wideBreakpoint,
            ),
            child: BlocBuilder<MasjidDetailBloc, MasjidDetailState>(
              builder: (context, s) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (s.masjid != null) _Header(masjid: s.masjid!),
                        const SizedBox(height: AppSpacing.lg),
                        ..._body(context, s),
                      ],
                    ),
                  ),
                  if (s.masjid != null &&
                      (s.status == MasjidDetailStatus.loaded ||
                          s.status == MasjidDetailStatus.empty))
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.page,
                      ),
                      sliver: SuggestionsSection(
                        onSuggest: (p) => _suggest(context, s.masjid!, p),
                      ),
                    ),
                  if (s.status == MasjidDetailStatus.loaded ||
                      s.status == MasjidDetailStatus.empty)
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.page,
                        0,
                        AppSpacing.page,
                        AppSpacing.xl,
                      ),
                      sliver: SliverToBoxAdapter(child: _Footer()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _suggest(
    BuildContext context,
    Masjid masjid,
    Prayer? prayer,
  ) async {
    if (!await ensureContributor(context)) return;
    if (!context.mounted) return;
    await showSuggestSheet(context, masjidId: masjid.id, prayer: prayer);
  }

  List<Widget> _body(BuildContext context, MasjidDetailState s) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<MasjidDetailBloc>();
    return switch (s.status) {
      MasjidDetailStatus.initial || MasjidDetailStatus.loading => [
        const LoadingView(shape: SkeletonShape.row, count: 6),
      ],
      MasjidDetailStatus.error => [
        if (s.failure is NotFoundFailure)
          EmptyState(
            icon: Icons.search_off,
            message: l10n.masjidNotFound,
            actionLabel: l10n.backToNearby,
            onAction: () => context.go('/'),
          )
        else
          ErrorView(
            failure: s.failure ?? const ServerFailure(),
            onRetry: () => bloc.add(const MasjidDetailRefreshed()),
          ),
      ],
      MasjidDetailStatus.empty => [
        EmptyState(
          icon: Icons.schedule,
          message: l10n.emptyTimes,
          actionLabel: l10n.suggestTime,
          onAction: () => _suggest(context, s.masjid!, null),
        ),
      ],
      MasjidDetailStatus.loaded => [
        _TimesTable(
          times: s.times,
          now: clock(),
          onPassed: () => bloc.add(const MasjidDetailRefreshed()),
          onSuggest: (p) => _suggest(context, s.masjid!, p),
        ),
      ],
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.masjid});

  final Masjid masjid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final address = masjid.address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MasjidName(masjid, style: theme.textTheme.headlineSmall),
        if (address != null && address.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            address,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => launchUrl(
            directionsUri(
              masjid.location.lat,
              masjid.location.lng,
              defaultTargetPlatform,
            ),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.directions_outlined),
          label: Text(l10n.directions),
        ),
      ],
    );
  }
}

class _TimesTable extends StatelessWidget {
  const _TimesTable({
    required this.times,
    required this.now,
    required this.onPassed,
    required this.onSuggest,
  });

  final List<PrayerTime> times;
  final DateTime now;
  final VoidCallback onPassed;
  final ValueChanged<Prayer> onSuggest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final headerStyle = tokens.caption.copyWith(
      color: tokens.colors.onSurfaceVariant,
    );
    final byPrayer = {for (final t in times) t.prayer: t};
    final next = nextOf(times, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(l10n.namaz, style: headerStyle)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 2, child: Text(l10n.azaan, style: headerStyle)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.jamat,
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        // Fixed six rows, not a data list, so a Column is fine.
        for (final p in Prayer.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
            child: PrayerRow(
              prayer: p,
              time: byPrayer[p],
              isNext: next != null && next.prayer == p,
              onPassed: onPassed,
              onSuggest: () => onSuggest(p),
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = context.tokens.caption.copyWith(
      color: context.tokens.colors.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.detailFooter, style: style),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.mapAttribution, style: style),
        ],
      ),
    );
  }
}
