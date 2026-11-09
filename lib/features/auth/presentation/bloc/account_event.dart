part of 'account_bloc.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();
  @override
  List<Object?> get props => const [];
}

final class AccountExportRequested extends AccountEvent {
  const AccountExportRequested();
}

final class AccountDeleteRequested extends AccountEvent {
  const AccountDeleteRequested();
}
