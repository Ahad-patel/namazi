import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/app_version.dart';
import '../../../../core/utils/share_file.dart';
import '../../../../core/widgets/confirm_destructive_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/legal_links.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => sl<AccountBloc>(),
      child: SettingsView(
        version: appVersion().then(
          (v) => v.patch == null
              ? v.build
              : l10n.versionWithPatch(v.build, v.patch!),
        ),
      ),
    );
  }
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
              SelectableText(l10n.contactLine(AppConstants.contactEmail)),
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
            if (user?.role == UserRole.superAdmin) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: Text(l10n.superAdminTools),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: s.busy
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
              child: Text(l10n.signOut),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _DataActions(),
          ],
        );
      },
    );
  }
}

/// Download my data + Delete my account, as easy to find as Sign out.
class _DataActions extends StatelessWidget {
  const _DataActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, s) {
        final messenger = ScaffoldMessenger.of(context);
        switch (s.status) {
          case AccountStatus.exported:
            shareTextFile('masjid-timer-my-data.json', s.export!);
          case AccountStatus.deleted:
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.accountDeleted)),
            );
          case AccountStatus.error:
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  ErrorView.messageFor(
                    l10n,
                    s.failure ?? const ServerFailure(),
                  ),
                ),
              ),
            );
          case AccountStatus.idle ||
              AccountStatus.exporting ||
              AccountStatus.deleting:
            break;
        }
      },
      builder: (context, s) {
        final bloc = context.read<AccountBloc>();
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: s.busy
                  ? null
                  : () => bloc.add(const AccountExportRequested()),
              icon: const Icon(Icons.download_outlined),
              label: Text(
                s.status == AccountStatus.exporting
                    ? l10n.loading
                    : l10n.downloadMyData,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: tokens.colors.error),
              onPressed: s.busy
                  ? null
                  : () async {
                      final ok = await confirmDestructive(
                        context,
                        title: l10n.deleteAccountTitle,
                        body: l10n.deleteAccountBody,
                        confirmText: l10n.deleteConfirmWord,
                        actionLabel: l10n.delete,
                      );
                      if (ok) bloc.add(const AccountDeleteRequested());
                    },
              icon: const Icon(Icons.delete_outline),
              label: Text(
                s.status == AccountStatus.deleting
                    ? l10n.loading
                    : l10n.deleteMyAccount,
              ),
            ),
          ],
        );
      },
    );
  }
}
