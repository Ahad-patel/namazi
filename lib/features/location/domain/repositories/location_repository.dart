import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/geo_point.dart';

abstract class LocationRepository {
  /// Device position, or a [LocationFailure] when denied/disabled/unavailable.
  Future<Either<Failure, GeoPoint>> current();

  /// Best match for a typed area name, or null when nothing matches.
  Future<Either<Failure, Place?>> searchArea(String query);
}
