import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:namazi/features/auth/data/models/app_user_model.dart';
import 'package:namazi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:namazi/features/auth/domain/entities/app_user.dart';

class _Ds extends Mock implements AuthRemoteDataSource {}

void main() {
  late _Ds ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = _Ds();
    repo = AuthRepositoryImpl(ds);
  });

  test('sessionChanges: distinct ids, errors become SignInFailure', () async {
    final c = StreamController<String?>();
    when(() => ds.userIdChanges).thenAnswer((_) => c.stream);
    c
      ..add(null)
      ..add('u1')
      ..add('u1') // token refresh
      ..addError(Exception('oauth denied'))
      ..add(null);
    unawaited(c.close());
    final out = await repo.sessionChanges.toList();
    expect(out.length, 4);
    expect(out[0], const Right<Failure, String?>(null));
    expect(out[1], const Right<Failure, String?>('u1'));
    expect(out[2].isLeft(), isTrue);
    expect(out[3], const Right<Failure, String?>(null));
  });

  test('profile row parses role and consent', () async {
    when(() => ds.profile()).thenAnswer(
      (_) async => AppUserModel.fromJson(const {
        'id': 'u1',
        'display_name': 'Admin',
        'role': 'super_admin',
        'is_banned': false,
        'is_adult': true,
        'terms_version': 't1',
        'terms_accepted_at': '2026-11-01T00:00:00+00:00',
      }, email: 'a@b.co'),
    );
    final u = (await repo.currentUser()).getOrElse(() => fail('Right'))!;
    expect(u.role, UserRole.superAdmin);
    expect(u.email, 'a@b.co');
    expect(u.hasConsented('t1'), isTrue);
  });

  test('wrong OTP surfaces as SignInFailure', () async {
    when(() => ds.verifyEmailCode('a@b.co', '1'))
        .thenThrow(SignInException('invalid'));
    final r = await repo.verifyEmailCode('a@b.co', '1');
    expect(r.fold((f) => f, (_) => null), isA<SignInFailure>());
  });
}
