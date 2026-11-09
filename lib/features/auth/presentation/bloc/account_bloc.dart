import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'account_event.dart';
part 'account_state.dart';

/// Settings → Download my data / Delete my account. The session change after
/// a delete reaches AuthBloc through its own auth-state stream.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({required this._export, required this._delete})
    : super(const AccountState()) {
    on<AccountExportRequested>(_onExport, transformer: droppable());
    on<AccountDeleteRequested>(_onDelete, transformer: droppable());
  }

  final ExportMyData _export;
  final DeleteAccount _delete;

  Future<void> _onExport(
    AccountExportRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountState(status: AccountStatus.exporting));
    final r = await _export(const NoParams());
    emit(
      r.fold(
        (f) => AccountState(status: AccountStatus.error, failure: f),
        (json) => AccountState(status: AccountStatus.exported, export: json),
      ),
    );
  }

  Future<void> _onDelete(
    AccountDeleteRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountState(status: AccountStatus.deleting));
    final r = await _delete(const NoParams());
    emit(
      r.fold(
        (f) => AccountState(status: AccountStatus.error, failure: f),
        (_) => const AccountState(status: AccountStatus.deleted),
      ),
    );
  }
}
