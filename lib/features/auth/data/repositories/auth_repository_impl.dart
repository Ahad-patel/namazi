import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';

class AuthRepositoryImpl with RepositoryGuard implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<Either<Failure, String?>> get sessionChanges => _remote.userIdChanges
      .distinct()
      .map<Either<Failure, String?>>(Right.new)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (e, _, sink) => sink.add(Left(SignInFailure('$e'))),
        ),
      );

  @override
  Future<Either<Failure, AppUser?>> currentUser() => guard(_remote.profile);

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() =>
      guard(() => _remote.signInWithGoogle().then((_) => unit));

  @override
  Future<Either<Failure, Unit>> sendEmailCode(String email) =>
      guard(() => _remote.sendEmailCode(email).then((_) => unit));

  @override
  Future<Either<Failure, Unit>> verifyEmailCode(String email, String code) =>
      guard(() => _remote.verifyEmailCode(email, code).then((_) => unit));

  @override
  Future<Either<Failure, Unit>> signOut() =>
      guard(() => _remote.signOut().then((_) => unit));

  @override
  Future<Either<Failure, Unit>> acceptTerms(String version) =>
      guard(() => _remote.acceptTerms(version).then((_) => unit));
}
