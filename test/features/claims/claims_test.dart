import 'dart:math';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/claims/data/datasources/claims_remote_ds.dart';
import 'package:namazi/features/claims/data/models/claim_models.dart';
import 'package:namazi/features/claims/data/repositories/claims_repository_impl.dart';
import 'package:namazi/features/claims/domain/entities/claim.dart';
import 'package:namazi/features/claims/domain/usecases/claims_usecases.dart';
import 'package:namazi/features/claims/presentation/bloc/claims_bloc.dart';

class _Ds extends Mock implements ClaimsRemoteDataSource {}

class _Access extends Mock implements GetMasjidAccess {}

class _Submit extends Mock implements SubmitClaim {}

const _draft = ClaimDraft(
  masjidId: 'm1',
  role: ClaimRole.imam,
  phone: '+91 98000 00000',
);

void main() {
  setUpAll(() => registerFallbackValue(_draft));

  group('data', () {
    test('normalisePhone keeps digits and a leading +', () {
      expect(normalisePhone(' +91 98000-00000 '), '+919800000000');
      expect(normalisePhone('098000 00000'), '09800000000');
    });

    test('MasjidAccessModel parses null claim', () {
      final a = MasjidAccessModel.fromJson(const {
        'can_manage': false,
        'claim_status': null,
      });
      expect(a.canManage, isFalse);
      expect(a.claimStatus, isNull);
      expect(
        MasjidAccessModel.fromJson(const {
          'can_manage': true,
          'claim_status': 'approved',
        }).claimStatus,
        ClaimStatus.approved,
      );
    });

    test('uuidV4 is a valid v4 uuid', () {
      expect(
        uuidV4(Random0()),
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('repository maps a storage 403 to PermissionFailure', () async {
      final ds = _Ds();
      when(() => ds.submit(any())).thenThrow(PermissionException('403'));
      final r = await ClaimsRepositoryImpl(ds).submit(_draft);
      expect(r.fold((f) => f, (_) => null), isA<PermissionFailure>());
    });
  });

  group('ClaimsBloc', () {
    late _Access access;
    late _Submit submit;
    setUp(() {
      access = _Access();
      submit = _Submit();
    });
    ClaimsBloc build() => ClaimsBloc(getAccess: access, submit: submit);

    blocTest<ClaimsBloc, ClaimsState>(
      'signed out: no access without a call',
      build: build,
      act: (b) => b.add(const ClaimsAccessRequested(null)),
      expect: () => [const ClaimsState(status: AccessStatus.loaded)],
      verify: (_) => verifyNever(() => access(any())),
    );

    blocTest<ClaimsBloc, ClaimsState>(
      'loads access',
      build: () {
        when(
          () => access('m1'),
        ).thenAnswer((_) async => const Right(MasjidAccess(canManage: true)));
        return build();
      },
      act: (b) => b.add(const ClaimsAccessRequested('m1')),
      expect: () => [
        const ClaimsState(status: AccessStatus.loading),
        const ClaimsState(
          status: AccessStatus.loaded,
          access: MasjidAccess(canManage: true),
        ),
      ],
    );

    blocTest<ClaimsBloc, ClaimsState>(
      'access error',
      build: () {
        when(() => access('m1'))
            .thenAnswer((_) async => const Left(NetworkFailure('x')));
        return build();
      },
      act: (b) => b.add(const ClaimsAccessRequested('m1')),
      skip: 1,
      expect: () => [
        const ClaimsState(
          status: AccessStatus.error,
          failure: NetworkFailure('x'),
        ),
      ],
    );

    blocTest<ClaimsBloc, ClaimsState>(
      'submit success marks the claim pending',
      build: () {
        when(() => submit(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (b) => b.add(const ClaimSubmitted(_draft)),
      expect: () => [
        const ClaimsState(submitStatus: ClaimSubmitStatus.submitting),
        const ClaimsState(
          submitStatus: ClaimSubmitStatus.success,
          access: MasjidAccess(
            canManage: false,
            claimStatus: ClaimStatus.pending,
          ),
        ),
      ],
    );

    blocTest<ClaimsBloc, ClaimsState>(
      'submit failure',
      build: () {
        when(() => submit(any()))
            .thenAnswer((_) async => const Left(PermissionFailure('42501')));
        return build();
      },
      act: (b) => b.add(
        ClaimSubmitted(
          ClaimDraft(
            masjidId: 'm1',
            role: ClaimRole.committee,
            phone: '9800000000',
            photo: Uint8List(3),
          ),
        ),
      ),
      skip: 1,
      expect: () => [
        const ClaimsState(
          submitStatus: ClaimSubmitStatus.failure,
          submitFailure: PermissionFailure('42501'),
        ),
      ],
    );
  });
}

/// Deterministic Random for uuidV4.
class Random0 implements Random {
  int _n = 0;
  @override
  int nextInt(int max) => (_n++ * 37) % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
