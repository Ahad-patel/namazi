import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../features/admin/presentation/pages/masjid_admin_page.dart'
    deferred as masjid_admin;
import '../../features/admin/presentation/pages/super_admin_page.dart'
    deferred as super_admin;
import '../../features/auth/presentation/pages/consent_page.dart';
import '../../features/claims/presentation/pages/claim_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/location/domain/entities/geo_point.dart';
import '../../features/masjids/domain/entities/masjid.dart';
import '../../features/masjids/presentation/pages/add_masjid_page.dart';
import '../../features/masjids/presentation/pages/landing_page.dart';
import '../../features/masjids/presentation/pages/masjid_detail_page.dart';
import '../../features/masjids/presentation/pages/nearby_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../l10n/gen/app_localizations.dart';
import '../config/env.dart';
import '../widgets/empty_state.dart';
import 'deferred_page.dart';

/// No auth redirects: browsing never needs an account, and contributing
/// goes through `ensureContributor`, which pushes /sign-in and /consent.
GoRouter createRouter() => GoRouter(
  observers: [if (Env.sentryEnabled) SentryNavigatorObserver()],
  routes: [
    // Web opens on a landing page; the app goes straight to nearby.
    GoRoute(
      path: '/',
      builder: (_, _) => kIsWeb ? const LandingPage() : const NearbyPage(),
    ),
    GoRoute(
      path: '/nearby',
      builder: (_, state) =>
          NearbyPage(initialQuery: state.uri.queryParameters['q']),
    ),
    GoRoute(
      path: '/m/:slug',
      builder: (_, state) => MasjidDetailPage(
        slug: state.pathParameters['slug']!,
        known: _masjid(state),
      ),
      routes: [
        // The form needs the masjid; a reload (no extra) goes back to detail.
        GoRoute(
          path: 'claim',
          redirect: (_, state) => _masjid(state) == null
              ? '/m/${state.pathParameters['slug']}'
              : null,
          builder: (_, state) => ClaimPage(masjid: _masjid(state)!),
        ),
        GoRoute(
          path: 'admin',
          builder: (_, state) => DeferredPage(
            load: masjid_admin.loadLibrary,
            builder: () => masjid_admin.MasjidAdminPage(
              slug: state.pathParameters['slug']!,
              known: _masjid(state),
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (_, _) => DeferredPage(
        load: super_admin.loadLibrary,
        builder: () => super_admin.SuperAdminPage(),
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
          onAction: () => context.go('/nearby'),
        ),
      ),
    );
  },
);

Masjid? _masjid(GoRouterState state) =>
    state.extra is Masjid ? state.extra! as Masjid : null;
