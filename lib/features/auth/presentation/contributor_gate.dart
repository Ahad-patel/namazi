import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'bloc/auth_bloc.dart';

/// Call before suggesting, voting or adding a masjid. Walks the user through
/// sign-in and consent if needed and returns whether they may go ahead.
/// UI only: RLS (`app.can_contribute()`) is the real check.
Future<bool> ensureContributor(
  BuildContext context, {
  String termsVersion = Env.termsVersion,
}) async {
  final auth = context.read<AuthBloc>();
  if (!auth.state.isSignedIn) {
    await context.push('/sign-in');
    if (!context.mounted || !auth.state.isSignedIn) return false;
  }
  final user = auth.state.user;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  if (user == null) {
    final f = auth.state.failure;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          f == null ? l10n.errorServer : ErrorView.messageFor(l10n, f),
        ),
      ),
    );
    auth.add(const AuthProfileRefreshed());
    return false;
  }
  if (user.isBanned) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.bannedNotice)));
    return false;
  }
  if (user.hasConsented(termsVersion)) return true;
  await context.push('/consent');
  if (!context.mounted) return false;
  return auth.state.user?.hasConsented(termsVersion) ?? false;
}
