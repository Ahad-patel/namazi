import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/usecase/usecase.dart';
import 'package:namazi/features/auth/domain/entities/app_user.dart';
import 'package:namazi/features/auth/domain/repositories/auth_repository.dart';
import 'package:namazi/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namazi/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../helpers/fixtures.dart';

class _Repo extends Mock implements AuthRepository {}

class _Get extends Mock implements GetCurrentUser {}

class _SignOut extends Mock implements SignOut {}

class _Accept extends Mock implements AcceptTerms {}

void main() {
  late _Repo repo;
  late _Get get;
  late _SignOut signOut;
  late _Accept accept;
  late StreamController<Either<Failure, String?>> sessions;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    repo = _Repo();
    get = _Get();
    signOut = _SignOut();
    accept = _Accept();
    sessions = StreamController.broadcast();
    when(() => repo.sessionChanges).thenAnswer((_) => sessions.stream);
  });

  tearDown(() => sessions.close());

  AuthBloc build() => AuthBloc(
    repository: repo,
    getCurrentUser: get,
    signOut: signOut,
    acceptTerms: accept,
    termsVersion: 't1',
  );

  const noConsent = AppUser(id: 'u1', email: 'user@test.local');

  blocTest<AuthBloc, AuthState>(
    'no session: unauthenticated',
    build: build,
    act: (_) => sessions.add(const Right(null)),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
  );

  blocTest<AuthBloc, AuthState>(
    'session: authenticated only once the profile is loaded',
    setUp: () =>
        when(() => get(any()))
            .thenAnswer((_) async => const Right(signedInUser)),
    build: build,
    act: (_) => sessions.add(const Right('u1')),
    expect: () => [
      const AuthState(status: AuthStatus.authenticated, user: signedInUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'profile fails: authenticated with a failure, no user',
    setUp: () =>
        when(() => get(any()))
            .thenAnswer((_) async => const Left(NetworkFailure('x'))),
    build: build,
    act: (_) => sessions.add(const Right('u1')),
    expect: () => [
      const AuthState(
        status: AuthStatus.authenticated,
        failure: NetworkFailure('x'),
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'auth error from the session stream is kept as a failure',
    build: build,
    act: (_) => sessions.add(const Left(SignInFailure('oauth'))),
    expect: () => [const AuthState(failure: SignInFailure('oauth'))],
  );

  blocTest<AuthBloc, AuthState>(
    'accept terms: records version, then reloads the profile',
    setUp: () {
      when(() => accept('t1')).thenAnswer((_) async => const Right(unit));
      when(() => get(any())).thenAnswer((_) async => const Right(signedInUser));
    },
    build: build,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, user: noConsent),
    act: (b) => b.add(const AuthTermsAccepted()),
    expect: () => [
      const AuthState(
        status: AuthStatus.authenticated,
        user: noConsent,
        busy: true,
      ),
      const AuthState(status: AuthStatus.authenticated, user: signedInUser),
    ],
    verify: (_) => verify(() => accept('t1')).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'accept terms fails: stays, with the failure',
    setUp: () =>
        when(() => accept('t1'))
            .thenAnswer((_) async => const Left(PermissionFailure('rls'))),
    build: build,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, user: noConsent),
    act: (b) => b.add(const AuthTermsAccepted()),
    skip: 1,
    expect: () => [
      const AuthState(
        status: AuthStatus.authenticated,
        user: noConsent,
        failure: PermissionFailure('rls'),
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sign out',
    setUp: () =>
        when(() => signOut(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, user: signedInUser),
    act: (b) => b.add(const AuthSignOutRequested()),
    expect: () => [
      const AuthState(
        status: AuthStatus.authenticated,
        user: signedInUser,
        busy: true,
      ),
      const AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  test('hasConsented needs adult, accepted and the current version', () {
    final at = DateTime(2026, 11, 1);
    expect(
      AppUser(
        id: 'u',
        isAdult: true,
        termsVersion: 't1',
        termsAcceptedAt: at,
      ).hasConsented('t1'),
      isTrue,
    );
    expect(
      AppUser(
        id: 'u',
        isAdult: true,
        termsVersion: 't0',
        termsAcceptedAt: at,
      ).hasConsented('t1'),
      isFalse,
      reason: 'a new TERMS_VERSION asks again',
    );
    expect(
      AppUser(
        id: 'u',
        termsVersion: 't1',
        termsAcceptedAt: at,
      ).hasConsented('t1'),
      isFalse,
    );
    expect(
      const AppUser(
        id: 'u',
        isAdult: true,
        termsVersion: 't1',
      ).hasConsented('t1'),
      isFalse,
    );
  });
}
