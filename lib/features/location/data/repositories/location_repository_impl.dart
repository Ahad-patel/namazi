import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_ds.dart';

class LocationRepositoryImpl
    with RepositoryGuard
    implements LocationRepository {
  LocationRepositoryImpl(this._device, this._geocoding);

  final DeviceLocationDataSource _device;
  final GeocodingRemoteDataSource _geocoding;

  @override
  Future<Either<Failure, GeoPoint>> current() => guard(_device.current);

  @override
  Future<Either<Failure, Place?>> searchArea(String query) =>
      guard(() => _geocoding.search(query));
}
