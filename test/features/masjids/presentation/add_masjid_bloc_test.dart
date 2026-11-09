import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/domain/entities/new_masjid.dart';
import 'package:namazi/features/masjids/domain/usecases/masjid_usecases.dart';
import 'package:namazi/features/masjids/presentation/bloc/add_masjid_bloc.dart';

import '../../../helpers/fixtures.dart';

class _Add extends Mock implements AddMasjid {}

void main() {
  late _Add add;
  const m = NewMasjid(name: 'Masjid Test', location: origin);

  setUp(() => add = _Add());

  blocTest<AddMasjidBloc, AddMasjidState>(
    'pin, submit, success',
    setUp: () => when(() => add(m)).thenAnswer((_) async => const Right('id')),
    build: () => AddMasjidBloc(add: add),
    act: (b) => b
      ..add(const AddMasjidPinDropped(origin))
      ..add(const AddMasjidSubmitted(m)),
    expect: () => [
      const AddMasjidState(pin: origin),
      const AddMasjidState(pin: origin, status: AddMasjidStatus.submitting),
      const AddMasjidState(pin: origin, status: AddMasjidStatus.success),
    ],
  );

  blocTest<AddMasjidBloc, AddMasjidState>(
    'RLS says no (e.g. consent missing): error',
    setUp: () =>
        when(() => add(m))
            .thenAnswer((_) async => const Left(PermissionFailure('rls'))),
    build: () => AddMasjidBloc(add: add),
    seed: () => const AddMasjidState(pin: origin),
    act: (b) => b.add(const AddMasjidSubmitted(m)),
    skip: 1,
    expect: () => [
      const AddMasjidState(
        pin: origin,
        status: AddMasjidStatus.error,
        failure: PermissionFailure('rls'),
      ),
    ],
  );
}
