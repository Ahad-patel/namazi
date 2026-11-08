import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/masjids/domain/entities/masjid.dart';
import '../../features/masjids/presentation/pages/masjid_detail_page.dart';
import '../../features/masjids/presentation/pages/nearby_page.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/empty_state.dart';

/// Phase 1 routes. Auth redirects arrive with AuthBloc in Phase 2.
GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const NearbyPage()),
    GoRoute(
      path: '/m/:slug',
      builder: (_, state) => MasjidDetailPage(
        slug: state.pathParameters['slug']!,
        known: state.extra is Masjid ? state.extra! as Masjid : null,
      ),
    ),
  ],
  errorBuilder: (context, _) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: EmptyState(
          icon: Icons.explore_off_outlined,
          message: l10n.pageNotFound,
          actionLabel: l10n.backToNearby,
          onAction: () => context.go('/'),
        ),
      ),
    );
  },
);
