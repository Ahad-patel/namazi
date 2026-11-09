import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../entities/masjid.dart';
import '../entities/new_masjid.dart';
import '../entities/nearby_masjid.dart';
import '../entities/prayer_time.dart';

abstract class MasjidRepository {
  Future<Either<Failure, List<NearbyMasjid>>> nearby(
    GeoPoint origin,
    int radiusM,
  );

  /// Soonest jamat anywhere in the radius, null when none has times.
  Future<Either<Failure, NearbyMasjid?>> nextJamatNearby(
    GeoPoint origin,
    int radiusM,
  );

  Future<Either<Failure, Masjid>> bySlug(String slug);

  Future<Either<Failure, List<PrayerTime>>> times(
    String masjidId, {
    bool refresh = false,
  });

  /// Adds a pending masjid; returns its id.
  Future<Either<Failure, String>> add(NewMasjid masjid);
}
