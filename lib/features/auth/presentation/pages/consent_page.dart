import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/widgets/legal_links.dart';

/// First contribution (and again after a TERMS_VERSION change): two unticked
/// boxes, Continue disabled until both are ticked. Browsing never needs this.
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key, this.termsVersion = Env.termsVersion});

  final String termsVersion;

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _adult = false;
  bool _terms = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) =>
          !(a.user?.hasConsented(widget.termsVersion) ?? false) &&
          (b.user?.hasConsented(widget.termsVersion) ?? false),
      listener: (context, _) =>
          context.canPop() ? context.pop() : context.go('/'),
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: Text(l10n.consentTitle)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.formMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.page),
              children: [
                Text(l10n.consentBody),
                const SizedBox(height: AppSpacing.lg),
                CheckboxListTile(
                  value: _adult,
                  onChanged: s.busy
                      ? null
                      : (v) => setState(() => _adult = v ?? false),
                  title: Text(l10n.consentAdult),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsetsDirectional.zero,
                ),
                CheckboxListTile(
                  value: _terms,
                  onChanged: s.busy
                      ? null
                      : (v) => setState(() => _terms = v ?? false),
                  title: Text(l10n.consentTerms),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsetsDirectional.zero,
                ),
                const LegalLinks(),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _adult && _terms && !s.busy
                      ? () => context.read<AuthBloc>().add(
                          const AuthTermsAccepted(),
                        )
                      : null,
                  child: Text(l10n.continueLabel),
                ),
                if (s.failure != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      ErrorView.messageFor(l10n, s.failure!),
                      style: context.tokens.label.copyWith(
                        color: context.tokens.colors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
