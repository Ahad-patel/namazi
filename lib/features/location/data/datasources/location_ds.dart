import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_constants.dart';
import '../../../../core/config/env.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/geo_point.dart';

/// Device location via geolocator. The position stays on the device and is
/// only ever sent as a query parameter.
class DeviceLocationDataSource {
  Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(LocationProblem.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(LocationProblem.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(LocationProblem.denied);
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: AppConstants.locationTimeout,
        ),
      );
      return GeoPoint(p.latitude, p.longitude);
    } on TimeoutException {
      final last = await _lastKnown();
      if (last != null) return last;
      throw LocationException(LocationProblem.unavailable);
    }
  }

  // Not supported on web; treat any failure as "no last position".
  Future<GeoPoint?> _lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// Area search through MapTiler Geocoding (same key as the map tiles).
class GeocodingRemoteDataSource {
  GeocodingRemoteDataSource(this._client);

  final http.Client _client;

  Future<Place?> search(String query) async {
    final uri = Uri.https(
      'api.maptiler.com',
      '/geocoding/${Uri.encodeComponent(query)}.json',
      {'key': Env.mapTilerKey, 'limit': '1', 'country': 'in'},
    );
    final res = await _client
        .get(uri)
        .timeout(AppConstants.requestTimeout, onTimeout: _timeout);
    if (res.statusCode != 200) {
      throw ServerException(res.body, code: '${res.statusCode}');
    }
    final features = (jsonDecode(res.body) as Map)['features'] as List;
    if (features.isEmpty) return null;
    final f = features.first as Map;
    final center = (f['center'] as List).cast<num>();
    return Place(
      f['place_name'] as String? ?? query,
      GeoPoint(center[1].toDouble(), center[0].toDouble()),
    );
  }

  static Never _timeout() => throw NetworkException('geocoding timeout');
}
