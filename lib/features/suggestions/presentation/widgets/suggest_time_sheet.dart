import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../masjids/domain/entities/prayer.dart';
import '../../../masjids/presentation/widgets/formatters.dart';
import '../../../masjids/presentation/widgets/time_text.dart';
import '../../domain/entities/suggestion.dart';
import '../bloc/suggestions_bloc.dart';

/// Opens the sheet on [context]'s [SuggestionsBloc]. Call after
/// `ensureContributor`.
Future<void> showSuggestSheet(
  BuildContext context, {
  required String masjidId,
  Prayer? prayer,
}) {
  final bloc = context.read<SuggestionsBloc>()
    ..add(const SuggestionFormOpened());
  final messenger = ScaffoldMessenger.of(context);
  final thanks = AppLocalizations.of(context).suggestionThanks;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: SuggestTimeSheet(
        masjidId: masjidId,
        initialPrayer: prayer,
        onDone: () => messenger.showSnackBar(SnackBar(content: Text(thanks))),
      ),
    ),
  );
}

class SuggestTimeSheet extends StatefulWidget {
  const SuggestTimeSheet({
    super.key,
    required this.masjidId,
    this.initialPrayer,
    this.onDone,
  });

  final String masjidId;
  final Prayer? initialPrayer;
  final VoidCallback? onDone;

  @override
  State<SuggestTimeSheet> createState() => _SuggestTimeSheetState();
}

class _SuggestTimeSheetState extends State<SuggestTimeSheet> {
  static const _noteMax = 200;

  late Prayer _prayer = widget.initialPrayer ?? Prayer.fajr;
  ClockTime? _jamat;
  ClockTime? _azaan;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _azaanAfterJamat =>
      _azaan != null && _jamat != null && _azaan!.compareTo(_jamat!) > 0;

  Future<ClockTime?> _pick(ClockTime? current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 13,
        minute: current?.minute ?? 0,
      ),
    );
    return t == null ? null : ClockTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return BlocConsumer<SuggestionsBloc, SuggestionsState>(
      listenWhen: (a, b) =>
          a.submitStatus != b.submitStatus &&
          b.submitStatus == SubmitStatus.success,
      listener: (context, _) {
        Navigator.of(context).pop();
        widget.onDone?.call();
      },
      builder: (context, s) {
        final busy = s.submitStatus == SubmitStatus.submitting;
        final jamat = _jamat;
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
                l10n.suggestTime,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.suggestTimeBody,
                style: tokens.caption.copyWith(
                  color: tokens.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final p in Prayer.values)
                    ChoiceChip(
                      label: Text(prayerName(l10n, p)),
                      selected: _prayer == p,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => _prayer = p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimeField(
                label: l10n.jamatTime,
                value: jamat,
                onPick: busy
                    ? null
                    : () async {
                        final t = await _pick(jamat);
                        if (t != null) setState(() => _jamat = t);
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              _TimeField(
                label: l10n.azaanTimeOptional,
                value: _azaan,
                onPick: busy
                    ? null
                    : () async {
                        final t = await _pick(_azaan ?? jamat);
                        if (t != null) setState(() => _azaan = t);
                      },
                onClear: busy || _azaan == null
                    ? null
                    : () => setState(() => _azaan = null),
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
              TextField(
                controller: _note,
                enabled: !busy,
                maxLength: _noteMax,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.noteOptional),
              ),
              if (s.submitStatus == SubmitStatus.failure &&
                  s.submitFailure != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      ErrorView.messageFor(l10n, s.submitFailure!),
                      style: tokens.label.copyWith(color: tokens.colors.error),
                    ),
                  ),
                ),
              FilledButton(
                onPressed: busy || jamat == null || _azaanAfterJamat
                    ? null
                    : () => context.read<SuggestionsBloc>().add(
                        SuggestionSubmitted(
                          SuggestionDraft(
                            masjidId: widget.masjidId,
                            prayer: _prayer,
                            jamat: jamat,
                            azaan: _azaan,
                            note: _note.text,
                          ),
                        ),
                      ),
                child: Text(busy ? l10n.sending : l10n.submit),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final ClockTime? value;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = value;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
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
          ),
        ),
        if (onClear != null)
          IconButton(
            tooltip: l10n.clear,
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
