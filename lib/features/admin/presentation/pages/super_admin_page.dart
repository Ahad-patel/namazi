import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../claims/domain/entities/claim.dart';
import '../../domain/entities/admin_items.dart';
import '../../domain/entities/admin_queue.dart';
import '../bloc/admin_queue_bloc.dart';
import '../widgets/admin_tiles.dart';
import '../widgets/queue_list.dart';

/// A fresh [AdminQueueBloc] for [queue], loading page 0. Keyed by the queue
/// so switching a segment starts a new list.
// ponytail: built here, not registered in get_it, because get_it can't key a
// factory by a generic type argument. Use cases still come from `sl`.
Widget queueProvider<T>(AdminQueue<T> queue, Widget child) =>
    BlocProvider<AdminQueueBloc<T>>(
      key: ValueKey(queue),
      create: (_) =>
          AdminQueueBloc<T>(queue: queue, load: sl(), perform: sl())
            ..add(const AdminQueueRequested()),
      child: child,
    );

/// Super admin only. The router shows it to anyone who types `/admin`, but
/// every RPC behind it refuses non-super-admins (42501 → permission error).
class SuperAdminPage extends StatelessWidget {
  const SuperAdminPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (l10n.tabClaims, const _ClaimsTab()),
      (l10n.tabMasjids, const _MasjidsTab()),
      (l10n.tabSuggestions, const _SuggestionsTab()),
      (l10n.tabAdmins, const _AdminsTab()),
      (l10n.tabHidden, const _HiddenTab()),
      (l10n.tabLog, const _LogTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.superAdmin),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.wideBreakpoint,
            ),
            child: TabBarView(children: [for (final (_, body) in tabs) body]),
          ),
        ),
      ),
    );
  }
}

class _ClaimsTab extends StatelessWidget {
  const _ClaimsTab();

  @override
  Widget build(BuildContext context) => queueProvider(
    const ClaimsQueue(ClaimStatus.pending),
    QueueList<ClaimItem>(
      emptyIcon: Icons.verified_user_outlined,
      itemBuilder: (_, item, busy) => ClaimTile(item: item, busy: busy),
    ),
  );
}

class _AdminsTab extends StatelessWidget {
  const _AdminsTab();

  @override
  Widget build(BuildContext context) => queueProvider(
    const ClaimsQueue(ClaimStatus.approved),
    QueueList<ClaimItem>(
      emptyIcon: Icons.admin_panel_settings_outlined,
      itemBuilder: (_, item, busy) => AdminRightTile(item: item, busy: busy),
    ),
  );
}

class _SuggestionsTab extends StatelessWidget {
  const _SuggestionsTab();

  @override
  Widget build(BuildContext context) => queueProvider(
    const OpenSuggestionsQueue(),
    QueueList<SuggestionItem>(
      emptyIcon: Icons.forum_outlined,
      itemBuilder: (_, item, busy) =>
          ModerationSuggestionTile(item: item, hidden: false, busy: busy),
    ),
  );
}

class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) => queueProvider(
    const ModerationLogQueue(),
    QueueList<LogEntry>(
      emptyIcon: Icons.history,
      itemBuilder: (_, item, _) => LogEntryTile(item: item),
    ),
  );
}

/// Pending (review) or active (search, then hide).
class _MasjidsTab extends StatefulWidget {
  const _MasjidsTab();

  @override
  State<_MasjidsTab> createState() => _MasjidsTabState();
}

class _MasjidsTabState extends State<_MasjidsTab> {
  var _status = MasjidModeration.pending;
  String? _query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status;
    return Column(
      children: [
        _Segments<MasjidModeration>(
          selected: status,
          options: [
            (MasjidModeration.pending, l10n.segPending),
            (MasjidModeration.active, l10n.segActive),
          ],
          onChanged: (s) => setState(() => _status = s),
        ),
        if (status == MasjidModeration.active)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.page,
            ),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.searchByName,
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (q) => setState(() => _query = q.trim()),
            ),
          ),
        Expanded(
          child: queueProvider(
            MasjidsQueue(
              status,
              query: status == MasjidModeration.active ? _query : null,
            ),
            QueueList<ModerationMasjid>(
              emptyIcon: Icons.mosque_outlined,
              itemBuilder: (_, item, busy) =>
                  ModerationMasjidTile(item: item, status: status, busy: busy),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Hidden { masjids, suggestions, banned }

class _HiddenTab extends StatefulWidget {
  const _HiddenTab();

  @override
  State<_HiddenTab> createState() => _HiddenTabState();
}

class _HiddenTabState extends State<_HiddenTab> {
  var _which = _Hidden.masjids;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _Segments<_Hidden>(
          selected: _which,
          options: [
            (_Hidden.masjids, l10n.segMasjids),
            (_Hidden.suggestions, l10n.segSuggestions),
            (_Hidden.banned, l10n.segBanned),
          ],
          onChanged: (s) => setState(() => _which = s),
        ),
        Expanded(
          child: switch (_which) {
            _Hidden.masjids => queueProvider(
              const MasjidsQueue(MasjidModeration.hidden),
              QueueList<ModerationMasjid>(
                emptyIcon: Icons.visibility_off_outlined,
                itemBuilder: (_, item, busy) => ModerationMasjidTile(
                  item: item,
                  status: MasjidModeration.hidden,
                  busy: busy,
                ),
              ),
            ),
            _Hidden.suggestions => queueProvider(
              const HiddenSuggestionsQueue(),
              QueueList<SuggestionItem>(
                emptyIcon: Icons.visibility_off_outlined,
                itemBuilder: (_, item, busy) => ModerationSuggestionTile(
                  item: item,
                  hidden: true,
                  busy: busy,
                ),
              ),
            ),
            _Hidden.banned => queueProvider(
              const BannedUsersQueue(),
              QueueList<BannedUser>(
                emptyIcon: Icons.person_off_outlined,
                itemBuilder: (_, item, busy) =>
                    BannedUserTile(item: item, busy: busy),
              ),
            ),
          },
        ),
      ],
    );
  }
}

class _Segments<S> extends StatelessWidget {
  const _Segments({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final S selected;
  final List<(S, String)> options;
  final ValueChanged<S> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
    child: SegmentedButton<S>(
      segments: [
        for (final (v, label) in options)
          ButtonSegment(value: v, label: Text(label)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    ),
  );
}
