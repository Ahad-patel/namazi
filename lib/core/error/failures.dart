import 'package:equatable/equatable.dart';

import 'exceptions.dart';

export 'exceptions.dart' show LocationProblem;

/// What the layers above `data/` see. The user-facing text comes from the ARB
/// files (see `ErrorView`); [detail] is the raw technical message, shown only
/// behind "Technical details".
sealed class Failure extends Equatable {
  const Failure([this.detail]);

  final String? detail;

  @override
  List<Object?> get props => [detail];

  @override
  String toString() => '$runtimeType($detail)';
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.detail]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.detail]);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.detail]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.detail]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.detail]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([super.detail]);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.detail]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.detail]);
}

class SignInFailure extends Failure {
  const SignInFailure([super.detail]);
}

class LocationFailure extends Failure {
  const LocationFailure(this.problem) : super(null);

  final LocationProblem problem;

  @override
  List<Object?> get props => [problem];
}
