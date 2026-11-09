import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

/// The sign-in page: Google, or email → 6-digit code. Success here only means
/// the request went through; the session itself arrives in [AuthBloc].
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({
    required this._google,
    required this._sendCode,
    required this._verifyCode,
  }) : super(const SignInState()) {
    on<SignInGoogleRequested>(_onGoogle, transformer: droppable());
    on<SignInEmailSubmitted>(_onEmail, transformer: droppable());
    on<SignInCodeSubmitted>(_onCode, transformer: droppable());
    on<SignInEmailChangeRequested>((_, emit) => emit(const SignInState()));
  }

  final SignInWithGoogle _google;
  final SendEmailCode _sendCode;
  final VerifyEmailCode _verifyCode;

  Future<void> _onGoogle(
    SignInGoogleRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(status: SignInStatus.submitting));
    final result = await _google(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(status: SignInStatus.failure, failure: f)),
      (_) => emit(state.copyWith(status: SignInStatus.idle)),
    );
  }

  Future<void> _onEmail(
    SignInEmailSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    final email = event.email.trim();
    emit(state.copyWith(status: SignInStatus.submitting, email: email));
    final result = await _sendCode(email);
    result.fold(
      (f) => emit(state.copyWith(status: SignInStatus.failure, failure: f)),
      (_) => emit(
        state.copyWith(status: SignInStatus.idle, step: SignInStep.code),
      ),
    );
  }

  Future<void> _onCode(
    SignInCodeSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(status: SignInStatus.submitting));
    final result = await _verifyCode(
      VerifyCodeParams(state.email, event.code.trim()),
    );
    result.fold(
      (f) => emit(state.copyWith(status: SignInStatus.failure, failure: f)),
      (_) => emit(state.copyWith(status: SignInStatus.success)),
    );
  }
}
