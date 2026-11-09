part of 'account_bloc.dart';

/// idle = nothing asked yet (the "empty" state); exporting / deleting =
/// loading; exported / deleted = loaded; error.
enum AccountStatus { idle, exporting, exported, deleting, deleted, error }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.idle,
    this.export,
    this.failure,
  });

  final AccountStatus status;

  /// The my_data() JSON, set once with [AccountStatus.exported].
  final String? export;
  final Failure? failure;

  bool get busy =>
      status == AccountStatus.exporting || status == AccountStatus.deleting;

  @override
  List<Object?> get props => [status, export, failure];
}
