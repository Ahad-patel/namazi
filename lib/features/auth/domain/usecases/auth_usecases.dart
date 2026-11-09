import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser implements UseCase<AppUser?, NoParams> {
  GetCurrentUser(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, AppUser?>> call(NoParams _) => _repo.currentUser();
}

class SignInWithGoogle implements UseCase<Unit, NoParams> {
  SignInWithGoogle(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.signInWithGoogle();
}

class SendEmailCode implements UseCase<Unit, String> {
  SendEmailCode(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repo.sendEmailCode(email);
}

class VerifyCodeParams extends Equatable {
  const VerifyCodeParams(this.email, this.code);
  final String email;
  final String code;
  @override
  List<Object?> get props => [email, code];
}

class VerifyEmailCode implements UseCase<Unit, VerifyCodeParams> {
  VerifyEmailCode(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(VerifyCodeParams p) =>
      _repo.verifyEmailCode(p.email, p.code);
}

class SignOut implements UseCase<Unit, NoParams> {
  SignOut(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.signOut();
}

class AcceptTerms implements UseCase<Unit, String> {
  AcceptTerms(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(String version) =>
      _repo.acceptTerms(version);
}
