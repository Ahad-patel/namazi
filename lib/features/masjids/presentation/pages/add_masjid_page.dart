import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/env.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../../domain/entities/masjid.dart';
import '../../domain/entities/new_masjid.dart';
import '../bloc/add_masjid_bloc.dart';
import '../widgets/nearby_map.dart';

/// Drop a pin + name. Reached only through `ensureContributor`.
class AddMasjidPage extends StatelessWidget {
  const AddMasjidPage({super.key, this.center});

  /// Where the map opens: the nearby search origin, if any.
  final GeoPoint? center;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AddMasjidBloc>(),
    child: AddMasjidView(center: center ?? defaultMapCenter),
  );
}

class AddMasjidView extends StatefulWidget {
  const AddMasjidView({super.key, required this.center, this.mapTilerKey});

  final GeoPoint center;

  /// Overrides the build-time key (tests pass '').
  final String? mapTilerKey;

  @override
  State<AddMasjidView> createState() => _AddMasjidViewState();
}

class _AddMasjidViewState extends State<AddMasjidView> {
  static const _nameMin = 2;
  static const _nameMax = 120;

  final _map = MapController();
  final _name = TextEditingController();
  final _local = TextEditingController();
  NameScript? _script;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _local.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _map.dispose();
    _name.dispose();
    _local.dispose();
    super.dispose();
  }

  void _drop(LatLng p) => context.read<AddMasjidBloc>().add(
    AddMasjidPinDropped(GeoPoint(p.latitude, p.longitude)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMasjid)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
          child: BlocBuilder<AddMasjidBloc, AddMasjidState>(
            builder: (context, s) => switch (s.status) {
              AddMasjidStatus.success => Center(
                child: EmptyState(
                  icon: Icons.check_circle_outline,
                  message: l10n.addMasjidThanks,
                  actionLabel: l10n.backToNearby,
                  onAction: () => context.go('/nearby'),
                ),
              ),
              AddMasjidStatus.editing ||
              AddMasjidStatus.submitting ||
              AddMasjidStatus.error => _form(context, s),
            },
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AddMasjidState s) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.colors;
    final busy = s.status == AddMasjidStatus.submitting;
    final pin = s.pin;
    final name = _name.text.trim();
    final canSubmit =
        !busy &&
        pin != null &&
        name.length >= _nameMin &&
        name.length <= _nameMax;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.page),
      children: [
        Text(l10n.addMasjidBody),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.addMasjidMapHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: LatLng(widget.center.lat, widget.center.lng),
                initialZoom: 16,
                backgroundColor: c.surfaceVariant,
                onTap: busy ? null : (_, p) => _drop(p),
              ),
              children: [
                ...baseMapLayers(widget.mapTilerKey ?? Env.mapTilerKey),
                if (pin != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(pin.lat, pin.lng),
                        width: AppSpacing.touchTarget,
                        height: AppSpacing.touchTarget,
                        child: Semantics(
                          label: l10n.pinDroppedSemantics,
                          child: Icon(
                            Icons.location_on,
                            size: AppSpacing.pin,
                            color: c.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                mapAttribution,
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              pin == null ? l10n.tapMapForPin : l10n.pinDropped,
              style: tokens.caption.copyWith(color: c.onSurfaceVariant),
            ),
            // Keyboard / switch users can't tap a map point.
            TextButton.icon(
              onPressed: busy ? null : () => _drop(_map.camera.center),
              icon: const Icon(Icons.center_focus_strong_outlined),
              label: Text(l10n.useMapCentre),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _name,
          enabled: !busy,
          maxLength: _nameMax,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.masjidNameLabel),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _local,
          enabled: !busy,
          maxLength: _nameMax,
          decoration: InputDecoration(labelText: l10n.masjidLocalNameLabel),
        ),
        if (_local.text.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final (script, label) in [
                (NameScript.arab, l10n.scriptArabic),
                (NameScript.urdu, l10n.scriptUrdu),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _script == script,
                  onSelected: busy
                      ? null
                      : (on) => setState(() => _script = on ? script : null),
                ),
            ],
          ),
        ],
        if (s.status == AddMasjidStatus.error && s.failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              ErrorView.messageFor(l10n, s.failure!),
              style: tokens.label.copyWith(color: c.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: canSubmit
              ? () => context.read<AddMasjidBloc>().add(
                  AddMasjidSubmitted(
                    NewMasjid(
                      name: name,
                      location: pin,
                      nameLocal: _local.text,
                      nameScript: _script,
                    ),
                  ),
                )
              : null,
          child: Text(busy ? l10n.sending : l10n.submitForReview),
        ),
      ],
    );
  }
}
