import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/postgrest_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<void> expectThrows<T>(Object error) =>
      expectLater(pg<void>(() async => throw error), throwsA(isA<T>()));

  test('maps Postgres codes', () async {
    await expectThrows<PermissionException>(
      const PostgrestException(message: 'rls', code: '42501'),
    );
    await expectThrows<NotFoundException>(
      const PostgrestException(message: '0 rows', code: 'PGRST116'),
    );
    await expectThrows<RateLimitException>(
      const PostgrestException(
        message: 'daily suggestion limit reached',
        code: 'MT429',
      ),
    );
    await expectThrows<NotFoundException>(
      const PostgrestException(message: 'claim not pending', code: 'P0002'),
    );
    await expectThrows<ConflictException>(
      const PostgrestException(message: '3 admins', code: 'MT409'),
    );
    await expectThrows<ValidationException>(
      const PostgrestException(message: 'outside window', code: 'MT422'),
    );
    await expectThrows<SessionExpiredException>(
      const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
    );
    await expectThrows<ServerException>(
      const PostgrestException(message: 'check', code: '23514'),
    );
  });

  test('maps auth errors', () async {
    await expectThrows<RateLimitException>(
      const AuthException('slow down', statusCode: '429'),
    );
    await expectThrows<SignInException>(
      const AuthException('Token has expired or is invalid', statusCode: '403'),
    );
    await expectThrows<NetworkException>(
      AuthRetryableFetchException(message: 'offline'),
    );
  });

  test('maps Edge Function errors', () async {
    await expectThrows<SessionExpiredException>(
      const FunctionException(status: 401, details: 'unauthorized'),
    );
    await expectThrows<ServerException>(
      const FunctionException(status: 500, details: 'boom'),
    );
  });
}
