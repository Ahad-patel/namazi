import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session + own profile. Lazy singleton (DI): every page that
/// gates a contribution reads it.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required this._getCurrentUser,
    required this._signOut,
    required this._acceptTerms,
    this.termsVersion = Env.termsVersion,
  }) : super(const AuthState()) {
    on<AuthSessionChanged>(_onSessionChanged);
    on<AuthProfileRefreshed>(_onProfileRefreshed);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthTermsAccepted>(_onTermsAccepted);
    _sub = repository.sessionChanges.listen((e) => add(AuthSessionChanged(e)));
  }

  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;
  final AcceptTerms _acceptTerms;
  final String termsVersion;
  late final StreamSubscription<Either<Failure, String?>> _sub;

  Future<void> _onSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    await event.change.fold((f) async => emit(state.copyWith(failure: f)), (
      id,
    ) async {
      if (id == null) {
        return emit(const AuthState(status: AuthStatus.unauthenticated));
      }
      await _loadProfile(emit);
    });
  }

  Future<void> _onProfileRefreshed(
    AuthProfileRefreshed event,
    Emitter<AuthState> emit,
  ) => _loadProfile(emit);

  /// Emits `authenticated` only once the profile is known (or failed), so a
  /// page waiting on sign-in sees consent and ban state straight away.
  Future<void> _loadProfile(Emitter<AuthState> emit) async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (f) => emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: state.user,
          failure: f,
        ),
      ),
      (user) => emit(
        user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
      ),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    final result = await _signOut(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(busy: false, failure: f)),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }

  Future<void> _onTermsAccepted(
    AuthTermsAccepted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    final result = await _acceptTerms(termsVersion);
    await result.fold(
      (f) async => emit(state.copyWith(busy: false, failure: f)),
      (_) => _loadProfile(emit),
    );
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
