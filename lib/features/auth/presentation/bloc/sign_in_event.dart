part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();
  @override
  List<Object?> get props => const [];
}

final class SignInGoogleRequested extends SignInEvent {
  const SignInGoogleRequested();
}

final class SignInEmailSubmitted extends SignInEvent {
  const SignInEmailSubmitted(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

final class SignInCodeSubmitted extends SignInEvent {
  const SignInCodeSubmitted(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

/// "Use a different email" on the code step.
final class SignInEmailChangeRequested extends SignInEvent {
  const SignInEmailChangeRequested();
}
