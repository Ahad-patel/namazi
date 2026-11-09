import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'failures.dart';

/// One place that turns thrown data-layer exceptions into Failures. Every
/// repository mixes this in, so no `try` leaks above `data/`.
mixin RepositoryGuard {
  Future<Either<Failure, T>> guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on SignInException catch (e) {
      return Left(SignInFailure(e.message));
    } on LocationException catch (e) {
      return Left(LocationFailure(e.problem));
    } on ServerException catch (e) {
      return Left(ServerFailure('${e.code ?? '-'}: ${e.message}'));
    } on TimeoutException catch (e) {
      return Left(NetworkFailure('$e'));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure('$e'));
    } catch (e, stack) {
      // SocketException is dart:io only, so match it by text (web-safe).
      if (_looksOffline('$e')) return Left(NetworkFailure('$e'));
      debugPrint('Unexpected repository error: $e');
      debugPrintStack(stackTrace: stack);
      return Left(ServerFailure('$e'));
    }
  }

  static bool _looksOffline(String s) {
    final m = s.toLowerCase();
    return m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('clientexception');
  }
}
