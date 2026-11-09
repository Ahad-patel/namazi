import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/consent_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/location/domain/entities/geo_point.dart';
import '../../features/masjids/domain/entities/masjid.dart';
import '../../features/masjids/presentation/pages/add_masjid_page.dart';
import '../../features/masjids/presentation/pages/masjid_detail_page.dart';
import '../../features/masjids/presentation/pages/nearby_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/empty_state.dart';

/// No auth redirects: browsing never needs an account, and contributing
/// goes through `ensureContributor`, which pushes /sign-in and /consent.
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
    GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
    GoRoute(path: '/consent', builder: (_, _) => const ConsentPage()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    GoRoute(
      path: '/add-masjid',
      builder: (_, state) => AddMasjidPage(
        center: state.extra is GeoPoint ? state.extra! as GeoPoint : null,
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
