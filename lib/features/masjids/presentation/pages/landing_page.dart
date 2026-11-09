import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/legal_links.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Web `/`: "Use my location" or an area search, both into `/nearby`. Mobile
/// opens straight on the nearby screen.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    void search(String q) {
      final t = q.trim();
      if (t.isEmpty) return;
      context.go(Uri(path: '/nearby', queryParameters: {'q': t}).toString());
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.page),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.formMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.appName, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.landingTitle, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.landingBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => context.go('/nearby'),
                  icon: const Icon(Icons.my_location),
                  label: Text(l10n.useMyLocation),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.orSearchArea,
                  textAlign: TextAlign.center,
                  style: tokens.caption.copyWith(
                    color: tokens.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: search,
                  decoration: InputDecoration(
                    hintText: l10n.searchAreaHint,
                    labelText: l10n.searchAreaLabel,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const LegalLinks(withDeletion: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
