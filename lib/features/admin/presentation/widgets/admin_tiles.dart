import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/directions.dart';
import '../../../../core/widgets/confirm_destructive_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../claims/domain/entities/claim.dart';
import '../../../masjids/presentation/widgets/formatters.dart';
import '../../../masjids/presentation/widgets/time_text.dart';
import '../../domain/entities/admin_items.dart';
import '../../domain/entities/admin_queue.dart';
import '../bloc/admin_lookup_cubit.dart';
import 'queue_list.dart';

String roleName(AppLocalizations l10n, ClaimRole r) => switch (r) {
  ClaimRole.imam => l10n.roleImam,
  ClaimRole.mutawalli => l10n.roleMutawalli,
  ClaimRole.committee => l10n.roleCommittee,
};

/// Card with a title, caption lines and a row of actions.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.title,
    this.titleLocal,
    this.lines = const [],
    this.actions = const [],
  });

  final String title;

  /// Arabic/Urdu name, laid out RTL under the title.
  final String? titleLocal;
  final List<Widget> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = titleLocal;
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
            Text(
              title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (local != null && local.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(local, style: theme.textTheme.bodyMedium),
              ),
            for (final l in lines)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                child: l,
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.tokens.caption.copyWith(
      color: context.tokens.colors.onSurfaceVariant,
    ),
  );
}

Future<void> _withReason<T>(
  BuildContext context,
  String title,
  String label,
  AdminAction Function(String? reason) action,
) async {
  final reason = await askReason(context, title: title, actionLabel: label);
  if (reason == null || !context.mounted) return;
  perform<T>(context, action(reason.isEmpty ? null : reason));
}

// ---- claims ----

class ClaimTile extends StatelessWidget {
  const ClaimTile({super.key, required this.item, required this.busy});

  final ClaimItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final who = item.userName ?? l10n.unknownUser;
    final phone = item.phone;
    final proof = item.proofPath;
    return AdminCard(
      title: item.masjidName,
      lines: [
        Text('$who · ${roleName(l10n, item.role)}'),
        if (phone != null) SelectableText(phone),
        _Caption(shortDate(l10n, item.createdAt)),
      ],
      actions: [
        if (proof != null)
          TextButton.icon(
            onPressed: () => showProof(context, proof),
            icon: const Icon(Icons.photo_outlined),
            label: Text(l10n.viewProof),
          ),
        ...[
          FilledButton(
            onPressed: busy
                ? null
                : () => perform<ClaimItem>(
                    context,
                    ReviewClaim(item.id, approve: true),
                  ),
            child: Text(l10n.approve),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => _withReason<ClaimItem>(
                    context,
                    l10n.rejectTitle,
                    l10n.reject,
                    (r) => ReviewClaim(item.id, approve: false, reason: r),
                  ),
            child: Text(l10n.reject),
          ),
        ],
      ],
    );
  }
}

/// Approved admins: revoke with the claimant's name typed.
class AdminRightTile extends StatelessWidget {
  const AdminRightTile({super.key, required this.item, required this.busy});

  final ClaimItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final who = item.userName ?? item.masjidName;
    return AdminCard(
      title: item.masjidName,
      lines: [
        Text(
          '${item.userName ?? l10n.unknownUser} · ${roleName(l10n, item.role)}',
        ),
      ],
      actions: [
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final ok = await confirmDestructive(
                    context,
                    title: l10n.confirmRevokeTitle(who),
                    body: l10n.confirmRevokeBody(item.masjidName),
                    confirmText: who,
                    actionLabel: l10n.revoke,
                  );
                  if (ok && context.mounted) {
                    perform<ClaimItem>(context, RevokeAdmin(item.id));
                  }
                },
          child: Text(l10n.revoke),
        ),
      ],
    );
  }
}

Future<void> showProof(BuildContext context, String path) => showDialog<void>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => AdminLookupCubit(proofUrl: sl(), author: sl())..proof(path),
    child: const _ProofDialog(),
  ),
);

class _ProofDialog extends StatelessWidget {
  const _ProofDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.viewProof),
      content: BlocBuilder<AdminLookupCubit, AdminLookupState>(
        builder: (context, s) => switch (s) {
          AdminLookupLoading() || AuthorLoaded() => const Center(
            heightFactor: 2,
            child: CircularProgressIndicator(),
          ),
          AdminLookupError(:final failure) => Text(
            ErrorView.messageFor(l10n, failure),
          ),
          ProofLoaded(:final url) => InteractiveViewer(
            child: Image.network(
              url,
              semanticLabel: l10n.viewProof,
              errorBuilder: (context, _, _) =>
                  Text(ErrorView.messageFor(l10n, const NetworkFailure())),
            ),
          ),
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.back),
        ),
      ],
    );
  }
}

// ---- masjids ----

class ModerationMasjidTile extends StatelessWidget {
  const ModerationMasjidTile({
    super.key,
    required this.item,
    required this.status,
    required this.busy,
  });

  final ModerationMasjid item;
  final MasjidModeration status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final by = item.createdByName;
    void go(MasjidModeration to, {String? reason}) => perform<ModerationMasjid>(
      context,
      SetMasjidStatus(item.id, to, reason: reason),
    );
    return AdminCard(
      title: item.name,
      titleLocal: item.nameLocal,
      lines: [
        if (by != null) _Caption(l10n.byName(by)),
        _Caption(shortDate(l10n, item.createdAt)),
      ],
      actions: [
        TextButton.icon(
          onPressed: () => launchUrl(
            directionsUri(item.lat, item.lng, defaultTargetPlatform),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.openInMaps),
        ),
        ...switch (status) {
          MasjidModeration.pending => [
            FilledButton(
              onPressed: busy ? null : () => go(MasjidModeration.active),
              child: Text(l10n.approve),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => _withReason<ModerationMasjid>(
                      context,
                      l10n.rejectTitle,
                      l10n.reject,
                      (r) => SetMasjidStatus(
                        item.id,
                        MasjidModeration.hidden,
                        reason: r,
                      ),
                    ),
              child: Text(l10n.reject),
            ),
          ],
          MasjidModeration.active => [
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await confirmDestructive(
                        context,
                        title: l10n.confirmHideMasjidTitle(item.name),
                        body: l10n.confirmHideMasjidBody,
                        confirmText: item.name,
                        actionLabel: l10n.hide,
                      );
                      if (ok && context.mounted) go(MasjidModeration.hidden);
                    },
              child: Text(l10n.hide),
            ),
          ],
          MasjidModeration.hidden => [
            FilledButton(
              onPressed: busy ? null : () => go(MasjidModeration.active),
              child: Text(l10n.restore),
            ),
          ],
        },
      ],
    );
  }
}

// ---- suggestions ----

class ModerationSuggestionTile extends StatelessWidget {
  const ModerationSuggestionTile({
    super.key,
    required this.item,
    required this.hidden,
    required this.busy,
  });

  final SuggestionItem item;
  final bool hidden;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = item.note;
    final author = item.authorName;
    final votes = item.netVotes;
    return AdminCard(
      title: item.masjidName,
      lines: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${prayerName(l10n, item.prayer)} · '),
            TimeText(item.jamat),
          ],
        ),
        if (note != null && note.isNotEmpty) Text(note),
        _Caption(
          [
            ?author == null ? null : l10n.byName(author),
            ?votes == null ? null : l10n.netVotes(votes),
            shortDate(l10n, item.createdAt),
          ].join(' · '),
        ),
      ],
      actions: hidden
          ? [
              FilledButton(
                onPressed: busy
                    ? null
                    : () => perform<SuggestionItem>(
                        context,
                        RestoreSuggestion(item.id),
                      ),
                child: Text(l10n.restore),
              ),
            ]
          : [
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _withReason<SuggestionItem>(
                        context,
                        l10n.hide,
                        l10n.hide,
                        (r) => HideSuggestion(item.id, reason: r),
                      ),
                child: Text(l10n.hide),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => _ban(context),
                child: Text(l10n.banAuthor),
              ),
            ],
    );
  }

  /// Preview first ("hides N open suggestions by X"), then typed name.
  Future<void> _ban(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = AdminLookupCubit(proofUrl: sl(), author: sl());
    await cubit.author(item.id);
    final s = cubit.state;
    await cubit.close();
    if (!context.mounted) return;
    switch (s) {
      case AuthorLoaded(:final author):
        final name = author.displayName ?? l10n.unknownUser;
        final ok = await confirmDestructive(
          context,
          title: l10n.confirmBanTitle(name),
          body: l10n.confirmBanBody(author.openCount, name),
          confirmText: name,
          actionLabel: l10n.banAuthor,
        );
        if (ok && context.mounted) {
          perform<SuggestionItem>(context, BanAuthor(item.id));
        }
      case AdminLookupError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorView.messageFor(l10n, failure))),
        );
      case AdminLookupLoading() || ProofLoaded():
        break;
    }
  }
}

class BannedUserTile extends StatelessWidget {
  const BannedUserTile({super.key, required this.item, required this.busy});

  final BannedUser item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminCard(
      title: item.displayName ?? l10n.unknownUser,
      actions: [
        FilledButton(
          onPressed: busy
              ? null
              : () => perform<BannedUser>(context, UnbanUser(item.id)),
          child: Text(l10n.unban),
        ),
      ],
    );
  }
}

class LogEntryTile extends StatelessWidget {
  const LogEntryTile({super.key, required this.item});

  final LogEntry item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reason = item.reason;
    final when = item.createdAt.toLocal();
    return ListTile(
      title: Text(l10n.logAction(item.action)),
      subtitle: Text(
        [
          '${shortDate(l10n, when)} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(when))}',
          ?reason,
        ].join(' · '),
      ),
    );
  }
}
