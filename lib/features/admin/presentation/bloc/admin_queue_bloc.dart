import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_queue.dart';
import '../../domain/usecases/admin_usecases.dart';

part 'admin_queue_event.dart';
part 'admin_queue_state.dart';

/// One paged admin list ([queue]) and the one-id actions taken from it. After
/// an action succeeds the list reloads from page 0, so a row that left the
/// queue disappears and the server stays the only source of truth.
class AdminQueueBloc<T> extends Bloc<AdminQueueEvent, AdminQueueState<T>> {
  AdminQueueBloc({
    required this.queue,
    required this._load,
    required this._perform,
  }) : super(AdminQueueState<T>()) {
    on<AdminQueueRequested>(_onRequested, transformer: restartable());
    on<AdminQueueMoreRequested>(_onMore, transformer: droppable());
    on<AdminActionRequested>(_onAction, transformer: sequential());
  }

  final AdminQueue<T> queue;
  final LoadAdminQueue _load;
  final PerformAdminAction _perform;

  Future<void> _onRequested(
    AdminQueueRequested event,
    Emitter<AdminQueueState<T>> emit,
  ) async {
    if (!event.silent || state.status != AdminQueueStatus.loaded) {
      emit(state.copyWith(status: AdminQueueStatus.loading));
    }
    final result = await _load<T>(queue, 0);
    emit(
      result.fold(
        (f) => state.copyWith(status: AdminQueueStatus.error, failure: f),
        (items) => state.copyWith(
          status: items.isEmpty
              ? AdminQueueStatus.empty
              : AdminQueueStatus.loaded,
          items: items,
          page: 0,
          hasMore: items.length == AppConstants.pageSize,
        ),
      ),
    );
  }

  Future<void> _onMore(
    AdminQueueMoreRequested event,
    Emitter<AdminQueueState<T>> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    final next = state.page + 1;
    final result = await _load<T>(queue, next);
    emit(
      result.fold(
        (f) => state.copyWith(loadingMore: false, actionFailure: f),
        (items) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...items],
          page: next,
          hasMore: items.length == AppConstants.pageSize,
        ),
      ),
    );
  }

  Future<void> _onAction(
    AdminActionRequested event,
    Emitter<AdminQueueState<T>> emit,
  ) async {
    emit(state.copyWith(busy: true));
    final Either<Failure, Unit> result = await _perform(event.action);
    await result.fold(
      (f) async => emit(
        state.copyWith(
          busy: false,
          actionFailure: f,
          failures: state.failures + 1,
        ),
      ),
      (_) async {
        emit(state.copyWith(busy: false, done: state.done + 1));
        await _onRequested(const AdminQueueRequested(silent: true), emit);
      },
    );
  }
}
