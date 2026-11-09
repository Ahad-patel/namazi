import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/usecase/usecase.dart';
import 'package:namazi/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namazi/features/auth/presentation/bloc/sign_in_bloc.dart';

class _Google extends Mock implements SignInWithGoogle {}

class _Send extends Mock implements SendEmailCode {}

class _Verify extends Mock implements VerifyEmailCode {}

void main() {
  late _Google google;
  late _Send send;
  late _Verify verifyCode;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const VerifyCodeParams('', ''));
  });

  setUp(() {
    google = _Google();
    send = _Send();
    verifyCode = _Verify();
  });

  SignInBloc build() =>
      SignInBloc(google: google, sendCode: send, verifyCode: verifyCode);

  blocTest<SignInBloc, SignInState>(
    'email: trims, sends the code, moves to the code step',
    setUp: () =>
        when(() => send('a@b.co')).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (b) => b.add(const SignInEmailSubmitted('  a@b.co ')),
    expect: () => [
      const SignInState(status: SignInStatus.submitting, email: 'a@b.co'),
      const SignInState(step: SignInStep.code, email: 'a@b.co'),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'code: verified against the stored email',
    setUp: () =>
        when(() => verifyCode(const VerifyCodeParams('a@b.co', '123456')))
            .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const SignInState(step: SignInStep.code, email: 'a@b.co'),
    act: (b) => b.add(const SignInCodeSubmitted(' 123456 ')),
    expect: () => [
      const SignInState(
        step: SignInStep.code,
        email: 'a@b.co',
        status: SignInStatus.submitting,
      ),
      const SignInState(
        step: SignInStep.code,
        email: 'a@b.co',
        status: SignInStatus.success,
      ),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'wrong code: failure, stays on the code step',
    setUp: () =>
        when(() => verifyCode(any()))
            .thenAnswer((_) async => const Left(SignInFailure('expired'))),
    build: build,
    seed: () => const SignInState(step: SignInStep.code, email: 'a@b.co'),
    act: (b) => b.add(const SignInCodeSubmitted('000000')),
    skip: 1,
    expect: () => [
      const SignInState(
        step: SignInStep.code,
        email: 'a@b.co',
        status: SignInStatus.failure,
        failure: SignInFailure('expired'),
      ),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'google: back to idle once the browser opened',
    setUp: () =>
        when(() => google(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (b) => b.add(const SignInGoogleRequested()),
    expect: () => [
      const SignInState(status: SignInStatus.submitting),
      const SignInState(),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'use a different email resets',
    build: build,
    seed: () => const SignInState(step: SignInStep.code, email: 'a@b.co'),
    act: (b) => b.add(const SignInEmailChangeRequested()),
    expect: () => [const SignInState()],
  );
}
