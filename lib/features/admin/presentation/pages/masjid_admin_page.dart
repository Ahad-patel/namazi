import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/confirm_destructive_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../masjids/domain/entities/masjid.dart';
import '../../../masjids/domain/entities/prayer.dart';
import '../../../masjids/domain/entities/prayer_time.dart';
import '../../../masjids/presentation/bloc/masjid_detail_bloc.dart';
import '../../../masjids/presentation/widgets/formatters.dart';
import '../../../masjids/presentation/widgets/masjid_name.dart';
import '../../../masjids/presentation/widgets/time_text.dart';
import '../../domain/entities/admin_items.dart';
import '../../domain/entities/admin_queue.dart';
import '../bloc/admin_queue_bloc.dart';
import '../widgets/queue_list.dart';
import '../widgets/set_time_sheet.dart';

/// `/m/:slug/admin`: verified times + the inbox of differing suggestions.
/// Approved admin of this masjid or super admin; the RPCs enforce it.
class MasjidAdminPage extends StatelessWidget {
  const MasjidAdminPage({super.key, required this.slug, this.known});

  final String slug;
  final Masjid? known;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        sl<MasjidDetailBloc>()..add(MasjidDetailRequested(slug, known: known)),
    child: BlocBuilder<MasjidDetailBloc, MasjidDetailState>(
      buildWhen: (a, b) => a.masjid?.id != b.masjid?.id,
      builder: (context, s) {
        final m = s.masjid;
        if (m == null) return MasjidAdminView(slug: slug);
        return BlocProvider(
          // ponytail: built here (generic bloc), see queueProvider.
          create: (_) => AdminQueueBloc<InboxItem>(
            queue: InboxQueue(m.id),
            load: sl(),
            perform: sl(),
          )..add(const AdminQueueRequested()),
          child: MasjidAdminView(slug: slug),
        );
      },
    ),
  );
}

class MasjidAdminView extends StatelessWidget {
  const MasjidAdminView({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = context.watch<MasjidDetailBloc>().state;
    final masjid = detail.masjid;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageTimes),
        leading: IconButton(
          tooltip: l10n.back,
          icon: const BackButtonIcon(),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/m/$slug'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.wideBreakpoint,
          ),
          child: switch (detail.status) {
            MasjidDetailStatus.initial || MasjidDetailStatus.loading =>
              const LoadingView(shape: SkeletonShape.row, count: 6),
            MasjidDetailStatus.error when masjid == null => Center(
              child: ErrorView(
                failure: detail.failure ?? const ServerFailure(),
                onRetry: () => context.read<MasjidDetailBloc>().add(
                  const MasjidDetailRefreshed(),
                ),
              ),
            ),
            _ =>
              BlocListener<
                AdminQueueBloc<InboxItem>,
                AdminQueueState<InboxItem>
              >(
                // A saved time or accepted suggestion changes what shows.
                listenWhen: (a, b) => a.done != b.done,
                listener: (context, _) => context.read<MasjidDetailBloc>().add(
                  const MasjidDetailRefreshed(),
                ),
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    0,
                    AppSpacing.lg,
                    0,
                    AppSpacing.xl,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.page,
                      ),
                      child: MasjidName(
                        masjid!,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final p in Prayer.values)
                      _TimeRow(
                        masjidId: masjid.id,
                        prayer: p,
                        time: detail.times
                            .where((t) => t.prayer == p)
                            .firstOrNull,
                      ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.page,
                        AppSpacing.xl,
                        AppSpacing.page,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        l10n.inbox,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    QueueList<InboxItem>(
                      shrinkWrap: true,
                      emptyMessage: l10n.inboxEmpty,
                      itemBuilder: (_, item, busy) =>
                          _InboxTile(item: item, busy: busy),
                    ),
                  ],
                ),
              ),
          },
        ),
      ),
    );
  }
}

/// Current verified time (if any) and a Set button.
class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.masjidId, required this.prayer, this.time});

  final String masjidId;
  final Prayer prayer;
  final PrayerTime? time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = time;
    final verified = t != null && t.source == TimeSource.verified;
    final azaan = t?.azaan;
    final busy = context.select<AdminQueueBloc<InboxItem>, bool>(
      (b) => b.state.busy,
    );
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.page,
      ),
      title: Text(prayerName(l10n, prayer)),
      subtitle: verified
          ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (azaan != null) ...[
                  Text('${l10n.azaan} '),
                  TimeText(azaan),
                  const Text(' · '),
                ],
                Text('${l10n.jamat} '),
                TimeText(t.jamat),
              ],
            )
          : Text(l10n.notAvailable),
      trailing: OutlinedButton(
        onPressed: busy
            ? null
            : () async {
                final action = await showSetTimeSheet(
                  context,
                  masjidId: masjidId,
                  prayer: prayer,
                  current: verified ? t : null,
                );
                if (action != null && context.mounted) {
                  perform<InboxItem>(context, action);
                }
              },
        child: Text(l10n.setTime),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.busy});

  final InboxItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final caption = tokens.caption.copyWith(
      color: tokens.colors.onSurfaceVariant,
    );
    final note = item.note;
    final verified = item.verifiedJamat;
    return Card(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${prayerName(l10n, item.prayer)} · ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TimeText(item.jamat, style: tokens.time),
              ],
            ),
            if (verified != null)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${l10n.yourTime} ', style: caption),
                  TimeText(verified, style: caption),
                ],
              ),
            if (note != null && note.isNotEmpty) Text(note),
            Text(
              '${l10n.netVotes(item.netVotes)} · ${shortDate(l10n, item.createdAt)}',
              style: caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => perform<InboxItem>(
                          context,
                          AcceptSuggestion(item.id),
                        ),
                  child: Text(l10n.accept),
                ),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final r = await askReason(
                            context,
                            title: l10n.rejectTitle,
                            actionLabel: l10n.reject,
                          );
                          if (r == null || !context.mounted) return;
                          perform<InboxItem>(
                            context,
                            RejectSuggestion(
                              item.id,
                              reason: r.isEmpty ? null : r,
                            ),
                          );
                        },
                  child: Text(l10n.reject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
