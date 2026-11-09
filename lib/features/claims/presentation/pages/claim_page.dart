import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../masjids/domain/entities/masjid.dart';
import '../../domain/entities/claim.dart';
import '../bloc/claims_bloc.dart';

/// Resized on device before upload (CHECKLISTS: 1600 px, JPEG 80).
Future<Uint8List?> pickProofPhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  return file?.readAsBytes();
}

/// Reached through `ensureContributor`.
class ClaimPage extends StatelessWidget {
  const ClaimPage({super.key, required this.masjid});

  final Masjid masjid;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ClaimsBloc>(),
    child: ClaimView(masjid: masjid),
  );
}

class ClaimView extends StatefulWidget {
  const ClaimView({
    super.key,
    required this.masjid,
    this.pickPhoto = pickProofPhoto,
  });

  final Masjid masjid;
  final Future<Uint8List?> Function() pickPhoto;

  @override
  State<ClaimView> createState() => _ClaimViewState();
}

class _ClaimViewState extends State<ClaimView> {
  final _phone = TextEditingController();
  ClaimRole? _role;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  static bool _phoneOk(String s) =>
      RegExp(r'^\+?[0-9]{8,15}$').hasMatch(s.replaceAll(RegExp(r'[\s-]'), ''));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.claimTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: BlocBuilder<ClaimsBloc, ClaimsState>(
            builder: (context, s) => switch (s.submitStatus) {
              ClaimSubmitStatus.success => Center(
                child: EmptyState(
                  icon: Icons.check_circle_outline,
                  message: l10n.claimThanks,
                  actionLabel: l10n.back,
                  onAction: () => context.canPop()
                      ? context.pop()
                      : context.go('/m/${widget.masjid.slug}'),
                ),
              ),
              ClaimSubmitStatus.idle ||
              ClaimSubmitStatus.submitting ||
              ClaimSubmitStatus.failure => _form(context, s),
            },
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, ClaimsState s) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final busy = s.submitStatus == ClaimSubmitStatus.submitting;
    final role = _role;
    final canSubmit = !busy && role != null && _phoneOk(_phone.text);
    final caption = tokens.caption.copyWith(color: c.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.page),
      children: [
        Text(widget.masjid.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.claimBody),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.claimRoleLabel, style: tokens.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (r, label) in [
              (ClaimRole.imam, l10n.roleImam),
              (ClaimRole.mutawalli, l10n.roleMutawalli),
              (ClaimRole.committee, l10n.roleCommittee),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _role == r,
                onSelected: busy ? null : (_) => setState(() => _role = r),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _phone,
          enabled: !busy,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: l10n.phoneLabel,
            helperText: l10n.phoneHelper,
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.proofLabel, style: tokens.label),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.proofHelper, style: caption),
        const SizedBox(height: AppSpacing.sm),
        if (_photo == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final p = await widget.pickPhoto();
                      if (p != null) setState(() => _photo = p);
                    },
              icon: const Icon(Icons.photo_outlined),
              label: Text(l10n.addPhoto),
            ),
          )
        else
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Icon(Icons.check, color: c.verified, size: AppSpacing.icon),
              Text(l10n.photoAdded),
              TextButton(
                onPressed: busy ? null : () => setState(() => _photo = null),
                child: Text(l10n.remove),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.claimPrivacy, style: caption),
        if (s.submitStatus == ClaimSubmitStatus.failure &&
            s.submitFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              ErrorView.messageFor(l10n, s.submitFailure!),
              style: tokens.label.copyWith(color: c.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: canSubmit
              ? () => context.read<ClaimsBloc>().add(
                  ClaimSubmitted(
                    ClaimDraft(
                      masjidId: widget.masjid.id,
                      role: role,
                      phone: _phone.text,
                      photo: _photo,
                    ),
                  ),
                )
              : null,
          child: Text(busy ? l10n.sending : l10n.sendClaim),
        ),
      ],
    );
  }
}
