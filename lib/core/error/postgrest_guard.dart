import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_constants.dart';
import 'exceptions.dart';

/// Wraps every Supabase call in `data/`: adds the 10 s timeout and maps
/// Supabase errors onto the app's exceptions. `42501` is Postgres for
/// "insufficient privilege", i.e. an RLS policy said no. `MT429` is our own
/// SQLSTATE for the 10-suggestions-a-day trigger, `MT422` for a time outside
/// its namaz window.
Future<T> pg<T>(Future<T> Function() body) async {
  try {
    return await body().timeout(AppConstants.requestTimeout);
  } on TimeoutException catch (e) {
    throw NetworkException('$e');
  } on PostgrestException catch (e) {
    if (e.code == '42501') throw PermissionException(e.message);
    // PGRST116: 0 rows for .single(); P0002: our RPCs' "not found / not in
    // that state any more".
    if (e.code == 'PGRST116' || e.code == 'P0002') {
      throw NotFoundException(e.message);
    }
    if (e.code == 'MT409') throw ConflictException(e.message);
    if (e.code == 'MT429') throw RateLimitException(e.message);
    if (e.code == 'MT422') throw ValidationException(e.message);
    if (_isJwtExpired(e.code, e.message)) {
      throw SessionExpiredException(e.message);
    }
    throw ServerException(e.message, code: e.code);
  } on StorageException catch (e) {
    if (e.statusCode == '403') throw PermissionException(e.message);
    if (_isJwtExpired(e.statusCode, e.message)) {
      throw SessionExpiredException(e.message);
    }
    throw ServerException(e.message, code: e.statusCode);
  } on FunctionException catch (e) {
    // Edge Functions (delete-account): 401 = the session is gone.
    if (e.status == 401) throw SessionExpiredException('${e.details}');
    throw ServerException(
      '${e.reasonPhrase}: ${e.details}',
      code: '${e.status}',
    );
  } on AuthException catch (e) {
    if (e.statusCode == '429' || e.code == 'over_email_send_rate_limit') {
      throw RateLimitException(e.message);
    }
    if (e is AuthRetryableFetchException) throw NetworkException(e.message);
    throw SignInException(e.message);
  }
}

bool _isJwtExpired(String? code, String message) =>
    code == 'PGRST301' || message.toLowerCase().contains('jwt expired');
