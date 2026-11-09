part of 'sign_in_bloc.dart';

enum SignInStep { email, code }

/// idle = waiting for input, submitting = loading, success = code accepted,
/// failure = error.
enum SignInStatus { idle, submitting, success, failure }

class SignInState extends Equatable {
  const SignInState({
    this.step = SignInStep.email,
    this.status = SignInStatus.idle,
    this.email = '',
    this.failure,
  });

  final SignInStep step;
  final SignInStatus status;
  final String email;
  final Failure? failure;

  SignInState copyWith({
    SignInStep? step,
    SignInStatus? status,
    String? email,
    Failure? failure,
  }) => SignInState(
    step: step ?? this.step,
    status: status ?? this.status,
    email: email ?? this.email,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [step, status, email, failure];
}
