import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/geo_point.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocation implements UseCase<GeoPoint, NoParams> {
  GetCurrentLocation(this._repo);
  final LocationRepository _repo;

  @override
  Future<Either<Failure, GeoPoint>> call(NoParams params) => _repo.current();
}

class SearchArea implements UseCase<Place?, String> {
  SearchArea(this._repo);
  final LocationRepository _repo;

  @override
  Future<Either<Failure, Place?>> call(String query) => _repo.searchArea(query);
}
