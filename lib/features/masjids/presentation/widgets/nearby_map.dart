import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../../domain/entities/nearby_masjid.dart';
import 'formatters.dart';

/// Masjid pins on MapTiler tiles. Never tile.openstreetmap.org.
class NearbyMap extends StatefulWidget {
  const NearbyMap({
    super.key,
    required this.center,
    required this.masjids,
    required this.onOpen,
    this.mapTilerKey = Env.mapTilerKey,
  });

  final GeoPoint center;
  final List<NearbyMasjid> masjids;
  final ValueChanged<NearbyMasjid> onOpen;

  /// Empty = no tile layer (tests, misconfigured builds).
  final String mapTilerKey;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double by) {
    final cam = _controller.camera;
    _controller.move(cam.center, cam.zoom + by);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.tokens.colors;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: LatLng(widget.center.lat, widget.center.lng),
            initialZoom: 14,
            backgroundColor: c.surfaceVariant,
          ),
          children: [
            if (widget.mapTilerKey.isNotEmpty)
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}',
                additionalOptions: {'key': widget.mapTilerKey},
                userAgentPackageName: 'com.ska.namazi',
              ),
            MarkerLayer(
              markers: [
                for (final m in widget.masjids)
                  Marker(
                    point: LatLng(m.masjid.location.lat, m.masjid.location.lng),
                    width: AppSpacing.touchTarget,
                    height: AppSpacing.touchTarget,
                    child: Semantics(
                      button: true,
                      label: l10n.mapPinSemantics(
                        m.masjid.name,
                        distanceText(l10n, m.distanceM),
                      ),
                      excludeSemantics: true,
                      child: Tooltip(
                        message: m.masjid.name,
                        child: InkResponse(
                          onTap: () => widget.onOpen(m),
                          child: Icon(
                            Icons.location_on,
                            size: AppSpacing.pin,
                            color: c.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
                TextSourceAttribution('MapTiler'),
              ],
            ),
          ],
        ),
        PositionedDirectional(
          top: AppSpacing.md,
          end: AppSpacing.md,
          child: Column(
            children: [
              IconButton.filledTonal(
                tooltip: l10n.zoomIn,
                onPressed: () => _zoom(1),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(height: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: l10n.zoomOut,
                onPressed: () => _zoom(-1),
                icon: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
