import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_constants.dart';
import 'exceptions.dart';

/// Wraps every Supabase call in `data/`: adds the 10 s timeout and maps
/// Supabase errors onto the app's exceptions. `42501` is Postgres for
/// "insufficient privilege", i.e. an RLS policy said no.
Future<T> pg<T>(Future<T> Function() body) async {
  try {
    return await body().timeout(AppConstants.requestTimeout);
  } on TimeoutException catch (e) {
    throw NetworkException('$e');
  } on PostgrestException catch (e) {
    if (e.code == '42501') throw PermissionException(e.message);
    if (e.code == 'PGRST116') throw NotFoundException(e.message);
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
  }
}

bool _isJwtExpired(String? code, String message) =>
    code == 'PGRST301' || message.toLowerCase().contains('jwt expired');
