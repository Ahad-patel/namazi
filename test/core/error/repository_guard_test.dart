import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/error/repository_guard.dart';

class _Repo with RepositoryGuard {}

void main() {
  final repo = _Repo();

  Future<Failure> failureOf(Object error) async {
    final r = await repo.guard<int>(() async => throw error);
    return r.fold((f) => f, (_) => fail('expected Left'));
  }

  test('success is Right', () async {
    expect(await repo.guard(() async => 1), const Right<Failure, int>(1));
  });

  test('maps each exception to its Failure', () async {
    expect(
      await failureOf(PermissionException('rls')),
      isA<PermissionFailure>(),
    );
    expect(await failureOf(NotFoundException('x')), isA<NotFoundFailure>());
    expect(
      await failureOf(SessionExpiredException('jwt')),
      isA<SessionExpiredFailure>(),
    );
    expect(await failureOf(NetworkException('t')), isA<NetworkFailure>());
    expect(await failureOf(TimeoutException('t')), isA<NetworkFailure>());
    expect(
      await failureOf(http.ClientException('offline')),
      isA<NetworkFailure>(),
    );
    expect(
      await failureOf(LocationException(LocationProblem.denied)),
      const LocationFailure(LocationProblem.denied),
    );
    expect(
      await failureOf(ServerException('boom', code: '500')),
      isA<ServerFailure>(),
    );
    expect(await failureOf(StateError('?')), isA<ServerFailure>());
  });

  test('failure keeps the technical detail', () async {
    final f = await failureOf(ServerException('boom', code: 'P0001'));
    expect(f.detail, contains('boom'));
    expect(f.detail, contains('P0001'));
  });
}
