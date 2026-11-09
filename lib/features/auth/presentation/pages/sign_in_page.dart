import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/sign_in_bloc.dart';
import '../../../../core/widgets/legal_links.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<SignInBloc>(), child: const SignInView());
}

/// Pops once [AuthBloc] has a session (email code accepted, or back from the
/// Google redirect).
class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => !a.isSignedIn && b.isSignedIn,
      listener: (context, _) =>
          context.canPop() ? context.pop() : context.go('/'),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signIn)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.formMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.page),
              children: [
                Text(
                  l10n.signInTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.signInBody),
                const SizedBox(height: AppSpacing.xl),
                const _Form(),
                const SizedBox(height: AppSpacing.xl),
                const LegalLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  static bool _looksLikeEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SignInBloc>();
    final authFailure = context.select((AuthBloc b) => b.state.failure);
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, s) {
        final busy = s.status == SignInStatus.submitting;
        final failure = s.status == SignInStatus.failure
            ? s.failure
            : authFailure;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => bloc.add(const SignInGoogleRequested()),
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(l10n.continueWithGoogle),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(l10n.or),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (s.step == SignInStep.email) ...[
              TextField(
                controller: _email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                onSubmitted: (v) {
                  if (_looksLikeEmail(v)) bloc.add(SignInEmailSubmitted(v));
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _SubmitButton(
                label: l10n.emailMeCode,
                busy: busy,
                onPressed: _looksLikeEmail(_email.text)
                    ? () => bloc.add(SignInEmailSubmitted(_email.text))
                    : null,
              ),
            ] else ...[
              Text(l10n.codeSentTo(s.email)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _code,
                enabled: !busy,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.codeLabel),
                onSubmitted: (v) => bloc.add(SignInCodeSubmitted(v)),
              ),
              const SizedBox(height: AppSpacing.md),
              _SubmitButton(
                label: l10n.verifyCode,
                busy: busy,
                onPressed: _code.text.trim().length >= 6
                    ? () => bloc.add(SignInCodeSubmitted(_code.text))
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            _code.clear();
                            bloc.add(const SignInEmailChangeRequested());
                          },
                    child: Text(l10n.useDifferentEmail),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => bloc.add(SignInEmailSubmitted(s.email)),
                    child: Text(l10n.resendCode),
                  ),
                ],
              ),
            ],
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  ErrorView.messageFor(l10n, failure),
                  style: context.tokens.label.copyWith(
                    color: context.tokens.colors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? SizedBox.square(
            dimension: AppSpacing.icon,
            child: CircularProgressIndicator(
              strokeWidth: AppSpacing.focusRing,
              semanticsLabel: AppLocalizations.of(context).loading,
            ),
          )
        : Text(label),
  );
}
