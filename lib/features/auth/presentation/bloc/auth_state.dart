part of 'auth_bloc.dart';

/// unknown = loading (session not read yet), unauthenticated = empty,
/// authenticated = loaded; [failure] = error.
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.failure,
  });

  final AuthStatus status;

  /// Null while signed out, or when signed in but the profile failed to load.
  final AppUser? user;

  /// Sign-out or consent request in flight.
  final bool busy;
  final Failure? failure;

  bool get isSignedIn => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    busy: busy ?? this.busy,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, user, busy, failure];
}
