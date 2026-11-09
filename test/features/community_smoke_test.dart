import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/theme/theme_cubit.dart';
import 'package:namazi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:namazi/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:namazi/features/auth/presentation/pages/consent_page.dart';
import 'package:namazi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/masjids/presentation/bloc/add_masjid_bloc.dart';
import 'package:namazi/features/masjids/presentation/pages/add_masjid_page.dart';
import 'package:namazi/features/settings/presentation/pages/settings_page.dart';
import 'package:namazi/features/suggestions/presentation/bloc/suggestions_bloc.dart';
import 'package:namazi/features/suggestions/presentation/widgets/suggest_time_sheet.dart';
import 'package:namazi/features/suggestions/presentation/widgets/suggestion_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _SignIn extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

class _Add extends MockBloc<AddMasjidEvent, AddMasjidState>
    implements AddMasjidBloc {}

class _Suggestions extends MockBloc<SuggestionsEvent, SuggestionsState>
    implements SuggestionsBloc {}

B _mock<B extends BlocBase<S>, S>(B bloc, S state) {
  whenListen(bloc, Stream<S>.empty(), initialState: state);
  return bloc;
}

const _signedOut = AuthState(status: AuthStatus.unauthenticated);
const _signedIn = AuthState(
  status: AuthStatus.authenticated,
  user: signedInUser,
);

late ThemeCubit _theme;

Widget _withAuth(AuthState auth, Widget child) => MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>.value(value: _mock(_Auth(), auth)),
    BlocProvider<ThemeCubit>.value(value: _theme),
  ],
  child: child,
);

Map<String, Widget Function()> _screens() => {
  'SignIn email': () => _withAuth(
    _signedOut,
    BlocProvider<SignInBloc>.value(
      value: _mock(_SignIn(), const SignInState()),
      child: const SignInView(),
    ),
  ),
  'SignIn code + error': () => _withAuth(
    const AuthState(
      status: AuthStatus.unauthenticated,
      failure: SignInFailure('oauth'),
    ),
    BlocProvider<SignInBloc>.value(
      value: _mock(
        _SignIn(),
        const SignInState(
          step: SignInStep.code,
          email: 'someone.with.a.long.address@example.com',
          status: SignInStatus.failure,
          failure: SignInFailure('Token has expired or is invalid'),
        ),
      ),
      child: const SignInView(),
    ),
  ),
  'SignIn submitting': () => _withAuth(
    _signedOut,
    BlocProvider<SignInBloc>.value(
      value: _mock(
        _SignIn(),
        const SignInState(status: SignInStatus.submitting),
      ),
      child: const SignInView(),
    ),
  ),
  'Consent': () => _withAuth(
    const AuthState(status: AuthStatus.authenticated),
    const ConsentPage(termsVersion: 't2'),
  ),
  'Consent error': () => _withAuth(
    const AuthState(
      status: AuthStatus.authenticated,
      failure: NetworkFailure('x'),
    ),
    const ConsentPage(termsVersion: 't2'),
  ),
  'Settings signed out': () =>
      _withAuth(_signedOut, SettingsView(version: Future.value('1.0.0+1'))),
  'Settings signed in': () =>
      _withAuth(_signedIn, SettingsView(version: Future.value('1.0.0+1'))),
  'Settings loading': () =>
      _withAuth(const AuthState(), SettingsView(version: Future.value('1'))),
  'AddMasjid editing': () => BlocProvider<AddMasjidBloc>.value(
    value: _mock(_Add(), const AddMasjidState()),
    child: const AddMasjidView(center: origin, mapTilerKey: ''),
  ),
  'AddMasjid error': () => BlocProvider<AddMasjidBloc>.value(
    value: _mock(
      _Add(),
      const AddMasjidState(
        pin: origin,
        status: AddMasjidStatus.error,
        failure: PermissionFailure('42501'),
      ),
    ),
    child: const AddMasjidView(center: origin, mapTilerKey: ''),
  ),
  'AddMasjid success': () => BlocProvider<AddMasjidBloc>.value(
    value: _mock(_Add(), const AddMasjidState(status: AddMasjidStatus.success)),
    child: const AddMasjidView(center: origin, mapTilerKey: ''),
  ),
  'SuggestTimeSheet': () => BlocProvider<SuggestionsBloc>.value(
    value: _mock(
      _Suggestions(),
      const SuggestionsState(
        submitStatus: SubmitStatus.failure,
        submitFailure: RateLimitFailure('MT429'),
      ),
    ),
    child: const Scaffold(
      body: SuggestTimeSheet(masjidId: 'm1', initialPrayer: Prayer.jummah),
    ),
  ),
  'SuggestionTiles': () => Scaffold(
    body: ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (_, i) =>
          SuggestionTile(suggestion: suggestionList[i], onVote: (_) {}),
    ),
  ),
};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _theme = ThemeCubit(await SharedPreferences.getInstance());
  });

  for (final size in smokeSizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 2.0]) {
        final tag =
            '${size.width.toInt()}x${size.height.toInt()} '
            '${mode.name} @${scale}x';
        for (final MapEntry(key: name, value: build) in _screens().entries) {
          testWidgets('$name $tag', (tester) async {
            await tester.pumpApp(
              build(),
              size: size,
              mode: mode,
              textScale: scale,
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('consent: Continue stays disabled until both boxes are ticked', (
    tester,
  ) async {
    await tester.pumpApp(_screens()['Consent']!(), size: smokeSizes[1]);
    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(button().onPressed, isNull);
    await tester.tap(find.text('I am 18 or older'));
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.tap(find.text('I agree to the Terms and Privacy Policy'));
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('own suggestion has no vote buttons', (tester) async {
    await tester.pumpApp(_screens()['SuggestionTiles']!(), size: smokeSizes[1]);
    expect(find.byTooltip('Upvote'), findsOneWidget);
    expect(find.byTooltip('Downvote'), findsOneWidget);
  });
}
