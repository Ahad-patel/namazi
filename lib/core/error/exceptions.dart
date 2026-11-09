/// Thrown inside `data/` only. Repositories turn these into Failures; nothing
/// above the repository layer ever sees a thrown exception.
class ServerException implements Exception {
  ServerException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => 'ServerException($code): $message';
}

/// An RLS policy or storage policy said no.
class PermissionException implements Exception {
  PermissionException(this.message);
  final String message;
  @override
  String toString() => 'PermissionException: $message';
}

class NotFoundException implements Exception {
  NotFoundException(this.message);
  final String message;
  @override
  String toString() => 'NotFoundException: $message';
}

class SessionExpiredException implements Exception {
  SessionExpiredException(this.message);
  final String message;
  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Timeout or no connection.
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

enum LocationProblem { denied, deniedForever, serviceDisabled, unavailable }

class LocationException implements Exception {
  LocationException(this.problem);
  final LocationProblem problem;
  @override
  String toString() => 'LocationException: ${problem.name}';
}

/// A server-side limit: the 10-a-day suggestion trigger (`MT429`) or auth
/// rate limiting (HTTP 429).
class RateLimitException implements Exception {
  RateLimitException(this.message);
  final String message;
  @override
  String toString() => 'RateLimitException: $message';
}

/// Supabase Auth said no: wrong or expired code, provider error.
class SignInException implements Exception {
  SignInException(this.message);
  final String message;
  @override
  String toString() => 'SignInException: $message';
}
