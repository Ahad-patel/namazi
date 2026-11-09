part of 'admin_queue_bloc.dart';

sealed class AdminQueueEvent extends Equatable {
  const AdminQueueEvent();
  @override
  List<Object?> get props => const [];
}

/// Load page 0. [silent] keeps the current rows on screen while reloading.
final class AdminQueueRequested extends AdminQueueEvent {
  const AdminQueueRequested({this.silent = false});
  final bool silent;
  @override
  List<Object?> get props => [silent];
}

final class AdminQueueMoreRequested extends AdminQueueEvent {
  const AdminQueueMoreRequested();
}

final class AdminActionRequested extends AdminQueueEvent {
  const AdminActionRequested(this.action);
  final AdminAction action;
  @override
  List<Object?> get props => [action];
}
