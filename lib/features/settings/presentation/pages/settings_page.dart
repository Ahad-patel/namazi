import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/legal_links.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => SettingsView(
    // ponytail: version+build only; the Shorebird patch number joins it once
    // shorebird_code_push is added in Phase 3.
    version: PackageInfo.fromPlatform().then(
      (i) => '${i.version}+${i.buildNumber}',
    ),
  );
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.version});

  final Future<String> version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final caption = tokens.caption.copyWith(
      color: tokens.colors.onSurfaceVariant,
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            children: [
              heading(l10n.theme),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) => SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      context.read<ThemeCubit>().set(s.first),
                ),
              ),
              heading(l10n.account),
              const _AccountSection(),
              heading(l10n.about),
              const LegalLinks(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                  ),
                  child: Text(l10n.licences),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FutureBuilder<String>(
                future: version,
                builder: (context, snap) => SelectableText(
                  l10n.versionLine(snap.data ?? '…'),
                  style: caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, s) {
        if (s.status == AuthStatus.unknown) {
          return const LinearProgressIndicator();
        }
        if (!s.isSignedIn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.signedOutBody),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.push('/sign-in'),
                child: Text(l10n.signIn),
              ),
            ],
          );
        }
        final user = s.user;
        final who = user?.email ?? user?.displayName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (who != null) Text(l10n.signedInAs(who)),
            if (s.failure != null)
              Text(
                ErrorView.messageFor(l10n, s.failure!),
                style: tokens.label.copyWith(color: tokens.colors.error),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: s.busy
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );
  }
}
