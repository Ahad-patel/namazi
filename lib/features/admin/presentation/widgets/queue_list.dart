import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/admin_queue.dart';
import '../bloc/admin_queue_bloc.dart';

/// The [AdminQueueBloc] of [T] above this widget, as a paged list: loading,
/// empty, error and loaded states, "Load more" at the end, and a snackbar
/// for every action that succeeds or fails.
class QueueList<T> extends StatelessWidget {
  const QueueList({
    super.key,
    required this.itemBuilder,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage,
    this.shrinkWrap = false,
  });

  final Widget Function(BuildContext context, T item, bool busy) itemBuilder;
  final IconData emptyIcon;
  final String? emptyMessage;

  /// For a list inside another scroll view (masjid admin inbox).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void snack(BuildContext context, String text) =>
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
    return MultiBlocListener(
      listeners: [
        BlocListener<AdminQueueBloc<T>, AdminQueueState<T>>(
          listenWhen: (a, b) => a.done != b.done,
          listener: (context, _) => snack(context, l10n.actionDone),
        ),
        BlocListener<AdminQueueBloc<T>, AdminQueueState<T>>(
          listenWhen: (a, b) => a.failures != b.failures,
          listener: (context, s) => snack(
            context,
            ErrorView.messageFor(
              l10n,
              s.actionFailure ?? const ServerFailure(),
            ),
          ),
        ),
      ],
      child: BlocBuilder<AdminQueueBloc<T>, AdminQueueState<T>>(
        builder: (context, s) {
          final bloc = context.read<AdminQueueBloc<T>>();
          return switch (s.status) {
            AdminQueueStatus.initial || AdminQueueStatus.loading =>
              const LoadingView(shape: SkeletonShape.row, count: 4),
            AdminQueueStatus.error => Center(
              child: ErrorView(
                failure: s.failure ?? const ServerFailure(),
                onRetry: () => bloc.add(const AdminQueueRequested()),
              ),
            ),
            AdminQueueStatus.empty => Center(
              child: EmptyState(
                icon: emptyIcon,
                message: emptyMessage ?? l10n.emptyQueue,
              ),
            ),
            AdminQueueStatus.loaded => ListView.builder(
              shrinkWrap: shrinkWrap,
              physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.sm,
              ),
              itemCount: s.items.length + (s.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == s.items.length) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: s.loadingMore
                            ? null
                            : () => bloc.add(const AdminQueueMoreRequested()),
                        child: Text(l10n.loadMore),
                      ),
                    ),
                  );
                }
                return itemBuilder(context, s.items[i], s.busy);
              },
            ),
          };
        },
      ),
    );
  }
}

/// Sends [action] to the nearest [AdminQueueBloc] of [T].
void perform<T>(BuildContext context, AdminAction action) =>
    context.read<AdminQueueBloc<T>>().add(AdminActionRequested(action));
