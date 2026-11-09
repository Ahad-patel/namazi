import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Typed confirmation for high-impact actions (DESIGN.md): the error-coloured
/// button stays disabled until [confirmText] is typed exactly. Cancel has the
/// default focus. Returns true when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmText,
  required String actionLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDestructiveDialog(
        title: title,
        body: body,
        confirmText: confirmText,
        actionLabel: actionLabel,
      ),
    ) ??
    false;

class ConfirmDestructiveDialog extends StatefulWidget {
  const ConfirmDestructiveDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmText,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final String confirmText;
  final String actionLabel;

  @override
  State<ConfirmDestructiveDialog> createState() =>
      _ConfirmDestructiveDialogState();
}

class _ConfirmDestructiveDialogState extends State<ConfirmDestructiveDialog> {
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final matches = _typed.text.trim() == widget.confirmText.trim();
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _typed,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.typeToConfirm(widget.confirmText),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

/// Optional-reason prompt for reversible decisions (reject, hide). Returns
/// null on cancel, else the trimmed reason ('' when left empty).
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(title: title, actionLabel: actionLabel),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  static const _max = 300; // masjid_admins.reason / log reason check
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reason,
        maxLength: _max,
        maxLines: 3,
        decoration: InputDecoration(labelText: l10n.reasonOptional),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
