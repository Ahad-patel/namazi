import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/config/env.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/contributor_gate.dart';
import '../../domain/entities/nearby_masjid.dart';
import '../bloc/nearby_bloc.dart';
import '../widgets/masjid_card.dart';
import '../widgets/nearby_map.dart';
import '../widgets/next_jamat_banner.dart';

class NearbyPage extends StatelessWidget {
  const NearbyPage({super.key, this.initialQuery});

  /// `/nearby?q=…` from the web landing page: search that area instead of
  /// asking for the location.
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    final q = initialQuery?.trim() ?? '';
    return BlocProvider(
      create: (_) => sl<NearbyBloc>()
        ..add(
          q.isEmpty ? const NearbyLocateRequested() : NearbyAreaQueryChanged(q),
        ),
      child: NearbyView(initialQuery: q.isEmpty ? null : q),
    );
  }
}

class NearbyView extends StatefulWidget {
  const NearbyView({super.key, this.mapTilerKey, this.initialQuery});

  final String? initialQuery;

  /// Overrides the build-time key (tests pass '' to skip tile requests).
  final String? mapTilerKey;

  @override
  State<NearbyView> createState() => _NearbyViewState();
}

class _NearbyViewState extends State<NearbyView> {
  bool _showMap = false;

  void _open(NearbyMasjid m) =>
      context.push('/m/${m.masjid.slug}', extra: m.masjid);

  Future<void> _addMasjid() async {
    final origin = context.read<NearbyBloc>().state.origin;
    if (!await ensureContributor(context)) return;
    if (!mounted) return;
    await context.push('/add-masjid', extra: origin);
  }

  /// Labelled buttons from the wide breakpoint, icon buttons below (DESIGN).
  Widget _action({
    required bool wide,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => wide
      ? TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        )
      : IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide =
        MediaQuery.sizeOf(context).width >= AppConstants.wideBreakpoint;
    final map = BlocBuilder<NearbyBloc, NearbyState>(
      buildWhen: (a, b) => a.origin != b.origin || a.masjids != b.masjids,
      builder: (context, s) => NearbyMap(
        key: ValueKey(s.origin),
        center: s.origin ?? defaultMapCenter,
        masjids: s.masjids,
        onOpen: _open,
        mapTilerKey: widget.mapTilerKey ?? Env.mapTilerKey,
      ),
    );
    final list = _ListPane(onOpen: _open, initialQuery: widget.initialQuery);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          if (!wide)
            IconButton(
              tooltip: _showMap ? l10n.showList : l10n.showMap,
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            ),
          _action(
            wide: wide,
            label: l10n.addMasjid,
            icon: Icons.add_location_alt_outlined,
            onPressed: _addMasjid,
          ),
          _action(
            wide: wide,
            label: l10n.settings,
            icon: Icons.settings_outlined,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: wide
              ? Row(
                  children: [
                    SizedBox(width: AppSpacing.listPaneWidth, child: list),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: map,
                      ),
                    ),
                  ],
                )
              : (_showMap ? map : list),
        ),
      ),
    );
  }
}

class _ListPane extends StatelessWidget {
  const _ListPane({required this.onOpen, this.initialQuery});

  final String? initialQuery;

  final ValueChanged<NearbyMasjid> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<NearbyBloc>();
    return BlocBuilder<NearbyBloc, NearbyState>(
      builder: (context, s) {
        const pad = EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.page,
        );
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: _SearchBar(
                  initialQuery: initialQuery,
                  onChanged: (q) => bloc.add(NearbyAreaQueryChanged(q)),
                  onLocate: () => bloc.add(const NearbyLocateRequested()),
                ),
              ),
            ),
            if (s.status == NearbyStatus.loaded) ...[
              SliverPadding(
                padding: pad,
                sliver: SliverToBoxAdapter(
                  child: Text(
                    s.areaLabel == null
                        ? l10n.nearYou
                        : l10n.nearArea(s.areaLabel!),
                    style: context.tokens.label.copyWith(
                      color: context.tokens.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (s.next != null)
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: NextJamatBanner(
                      next: s.next!,
                      onTap: () => onOpen(s.next!),
                      onPassed: () => bloc.add(const NearbyRefreshed()),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: s.masjids.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => MasjidCard(
                    item: s.masjids[i],
                    index: i,
                    onTap: () => onOpen(s.masjids[i]),
                  ),
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  padding: pad,
                  child: _StatusBody(state: s),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.state});

  final NearbyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<NearbyBloc>();
    final s = state;
    return switch (s.status) {
      NearbyStatus.initial ||
      NearbyStatus.locating ||
      NearbyStatus.loading => const LoadingView(),
      NearbyStatus.loaded => const SizedBox.shrink(),
      NearbyStatus.empty => EmptyState(
        icon: Icons.location_searching,
        message: l10n.emptyNearby(s.radiusM ~/ 1000),
        actionLabel: s.canWiden ? l10n.searchWider : null,
        onAction: () => bloc.add(const NearbyWiderRequested()),
      ),
      NearbyStatus.needsArea => EmptyState(
        icon: Icons.location_off_outlined,
        message: switch (s.failure) {
          LocationFailure(problem: LocationProblem.serviceDisabled) =>
            l10n.locationServiceOff,
          _ => l10n.locationDeniedBody,
        },
      ),
      NearbyStatus.areaNotFound => EmptyState(
        icon: Icons.search_off,
        message: l10n.areaNotFound(s.areaQuery ?? ''),
      ),
      NearbyStatus.error => ErrorView(
        failure: s.failure ?? const ServerFailure(),
        onRetry: () => bloc.add(const NearbyRefreshed()),
      ),
    };
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.onLocate,
    this.initialQuery,
  });

  final String? initialQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      initialValue: initialQuery,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.searchAreaHint,
        labelText: l10n.searchAreaLabel,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: l10n.useMyLocation,
          onPressed: onLocate,
          icon: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
