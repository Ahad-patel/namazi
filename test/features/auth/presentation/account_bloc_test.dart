import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/usecase/usecase.dart';
import 'package:namazi/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namazi/features/auth/presentation/bloc/account_bloc.dart';

class _Export extends Mock implements ExportMyData {}

class _Delete extends Mock implements DeleteAccount {}

void main() {
  late _Export export;
  late _Delete delete;

  setUpAll(() => registerFallbackValue(const NoParams()));
  setUp(() {
    export = _Export();
    delete = _Delete();
  });

  AccountBloc build() => AccountBloc(export: export, delete: delete);

  blocTest<AccountBloc, AccountState>(
    'export hands back the JSON',
    build: () {
      when(() => export(any())).thenAnswer((_) async => const Right('{}'));
      return build();
    },
    act: (b) => b.add(const AccountExportRequested()),
    expect: () => [
      const AccountState(status: AccountStatus.exporting),
      const AccountState(status: AccountStatus.exported, export: '{}'),
    ],
  );

  blocTest<AccountBloc, AccountState>(
    'delete success',
    build: () {
      when(() => delete(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (b) => b.add(const AccountDeleteRequested()),
    expect: () => [
      const AccountState(status: AccountStatus.deleting),
      const AccountState(status: AccountStatus.deleted),
    ],
  );

  blocTest<AccountBloc, AccountState>(
    'delete failure keeps the account and reports why',
    build: () {
      when(() => delete(any()))
          .thenAnswer((_) async => const Left(SessionExpiredFailure('401')));
      return build();
    },
    act: (b) => b.add(const AccountDeleteRequested()),
    expect: () => [
      const AccountState(status: AccountStatus.deleting),
      const AccountState(
        status: AccountStatus.error,
        failure: SessionExpiredFailure('401'),
      ),
    ],
  );
}
