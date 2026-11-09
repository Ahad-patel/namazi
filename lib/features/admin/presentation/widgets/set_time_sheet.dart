import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../masjids/domain/entities/prayer.dart';
import '../../../masjids/domain/entities/prayer_time.dart';
import '../../../masjids/presentation/widgets/formatters.dart';
import '../../../masjids/presentation/widgets/time_text.dart';
import '../../domain/entities/admin_queue.dart';

/// Azaan + jamat for one namaz, from today or a later date. Returns the
/// action to perform, or null when dismissed. The server checks the namaz
/// window (MT422) and the admin's rights.
// ponytail: no "window today" hint here (the suggest sheet has one); a time
// outside the window comes back as the server's validation error.
Future<SetJamatTime?> showSetTimeSheet(
  BuildContext context, {
  required String masjidId,
  required Prayer prayer,
  PrayerTime? current,
}) => showModalBottomSheet<SetJamatTime>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      SetTimeSheet(masjidId: masjidId, prayer: prayer, current: current),
);

class SetTimeSheet extends StatefulWidget {
  const SetTimeSheet({
    super.key,
    required this.masjidId,
    required this.prayer,
    this.current,
  });

  final String masjidId;
  final Prayer prayer;
  final PrayerTime? current;

  @override
  State<SetTimeSheet> createState() => _SetTimeSheetState();
}

class _SetTimeSheetState extends State<SetTimeSheet> {
  late ClockTime? _jamat = widget.current?.jamat;
  late ClockTime? _azaan = widget.current?.azaan;
  DateTime? _from; // null = the masjid's today

  bool get _azaanAfterJamat =>
      _azaan != null && _jamat != null && _azaan!.compareTo(_jamat!) > 0;

  Future<ClockTime?> _pick(ClockTime? start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: start?.hour ?? 13,
        minute: start?.minute ?? 0,
      ),
    );
    return t == null ? null : ClockTime(t.hour, t.minute);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _from = d == today ? null : d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final jamat = _jamat;
    final from = _from;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xl + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setTimeTitle(prayerName(l10n, widget.prayer)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _TimeButton(
            label: l10n.jamatTime,
            value: jamat,
            onPressed: () async {
              final t = await _pick(jamat ?? _azaan);
              if (t != null) setState(() => _jamat = t);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: l10n.azaanTimeOptional,
                  value: _azaan,
                  onPressed: () async {
                    final t = await _pick(_azaan ?? jamat);
                    if (t != null) setState(() => _azaan = t);
                  },
                ),
              ),
              if (_azaan != null)
                IconButton(
                  tooltip: l10n.clear,
                  onPressed: () => setState(() => _azaan = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          if (_azaanAfterJamat)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Text(
                l10n.azaanAfterJamat,
                style: tokens.caption.copyWith(color: tokens.colors.error),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  from == null
                      ? l10n.startingToday
                      : l10n.startingOn(shortDate(l10n, from)),
                ),
              ),
              TextButton(onPressed: _pickDate, child: Text(l10n.changeDate)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: jamat == null || _azaanAfterJamat
                ? null
                : () => Navigator.of(context).pop(
                    SetJamatTime(
                      masjidId: widget.masjidId,
                      prayer: widget.prayer,
                      jamat: jamat,
                      azaan: _azaan,
                      validFrom: from,
                    ),
                  ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final ClockTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule),
      label: Align(
        alignment: AlignmentDirectional.centerStart,
        child: v == null
            ? Text(label)
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [Text('$label  '), TimeText(v)],
              ),
      ),
    );
  }
}
