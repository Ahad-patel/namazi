part of 'admin_queue_bloc.dart';

enum AdminQueueStatus { initial, loading, empty, loaded, error }

class AdminQueueState<T> extends Equatable {
  const AdminQueueState({
    this.status = AdminQueueStatus.initial,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
    this.busy = false,
    this.done = 0,
    this.failures = 0,
    this.actionFailure,
  });

  final AdminQueueStatus status;
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// Why the list itself failed to load.
  final Failure? failure;

  /// An action is in flight (buttons disabled).
  final bool busy;

  /// Counters the page listens to: a snackbar per success / failure.
  final int done;
  final int failures;
  final Failure? actionFailure;

  AdminQueueState<T> copyWith({
    AdminQueueStatus? status,
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Failure? failure,
    bool? busy,
    int? done,
    int? failures,
    Failure? actionFailure,
  }) => AdminQueueState<T>(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure ?? this.failure,
    busy: busy ?? this.busy,
    done: done ?? this.done,
    failures: failures ?? this.failures,
    actionFailure: actionFailure ?? this.actionFailure,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasMore,
    loadingMore,
    failure,
    busy,
    done,
    failures,
    actionFailure,
  ];
}
