part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

/// From [AuthRepository.sessionChanges]: a user id, null, or an auth error.
final class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged(this.change);
  final Either<Failure, String?> change;
  @override
  List<Object?> get props => [change];
}

/// Re-read the own profile (e.g. after it failed to load).
final class AuthProfileRefreshed extends AuthEvent {
  const AuthProfileRefreshed();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Consent screen: both boxes ticked, Continue pressed.
final class AuthTermsAccepted extends AuthEvent {
  const AuthTermsAccepted();
}
