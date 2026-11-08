import 'package:dartz/dartz.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../../domain/entities/masjid.dart';
import '../../domain/entities/nearby_masjid.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/masjid_repository.dart';
import '../datasources/masjid_remote_ds.dart';

class MasjidRepositoryImpl with RepositoryGuard implements MasjidRepository {
  MasjidRepositoryImpl(this._remote, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final MasjidRemoteDataSource _remote;
  final DateTime Function() _now;

  /// ponytail: unbounded in-memory map, fine for one browsing session; add an
  /// LRU cap if users routinely open hundreds of masjids per session.
  final _timesCache = <String, (DateTime, List<PrayerTime>)>{};

  @override
  Future<Either<Failure, List<NearbyMasjid>>> nearby(
    GeoPoint origin,
    int radiusM,
  ) => guard(() => _remote.nearby(origin.lat, origin.lng, radiusM));

  @override
  Future<Either<Failure, NearbyMasjid?>> nextJamatNearby(
    GeoPoint origin,
    int radiusM,
  ) => guard(() => _remote.nextJamatNearby(origin.lat, origin.lng, radiusM));

  @override
  Future<Either<Failure, Masjid>> bySlug(String slug) =>
      guard(() => _remote.bySlug(slug));

  @override
  Future<Either<Failure, List<PrayerTime>>> times(
    String masjidId, {
    bool refresh = false,
  }) => guard(() async {
    final hit = _timesCache[masjidId];
    if (!refresh &&
        hit != null &&
        _now().difference(hit.$1) < AppConstants.timesCacheTtl) {
      return hit.$2;
    }
    final fresh = await _remote.times(masjidId);
    _timesCache[masjidId] = (_now(), fresh);
    return fresh;
  });
}
