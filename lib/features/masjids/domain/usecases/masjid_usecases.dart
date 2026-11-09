import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../entities/masjid.dart';
import '../entities/new_masjid.dart';
import '../entities/nearby_masjid.dart';
import '../entities/prayer_time.dart';
import '../repositories/masjid_repository.dart';

class NearbyParams extends Equatable {
  const NearbyParams(this.origin, this.radiusM);
  final GeoPoint origin;
  final int radiusM;
  @override
  List<Object?> get props => [origin, radiusM];
}

class TimesParams extends Equatable {
  const TimesParams(this.masjidId, {this.refresh = false});
  final String masjidId;
  final bool refresh;
  @override
  List<Object?> get props => [masjidId, refresh];
}

class GetNearbyMasjids implements UseCase<List<NearbyMasjid>, NearbyParams> {
  GetNearbyMasjids(this._repo);
  final MasjidRepository _repo;
  @override
  Future<Either<Failure, List<NearbyMasjid>>> call(NearbyParams p) =>
      _repo.nearby(p.origin, p.radiusM);
}

class GetNextJamatNearby implements UseCase<NearbyMasjid?, NearbyParams> {
  GetNextJamatNearby(this._repo);
  final MasjidRepository _repo;
  @override
  Future<Either<Failure, NearbyMasjid?>> call(NearbyParams p) =>
      _repo.nextJamatNearby(p.origin, p.radiusM);
}

class GetMasjidBySlug implements UseCase<Masjid, String> {
  GetMasjidBySlug(this._repo);
  final MasjidRepository _repo;
  @override
  Future<Either<Failure, Masjid>> call(String slug) => _repo.bySlug(slug);
}

class GetMasjidTimes implements UseCase<List<PrayerTime>, TimesParams> {
  GetMasjidTimes(this._repo);
  final MasjidRepository _repo;
  @override
  Future<Either<Failure, List<PrayerTime>>> call(TimesParams p) =>
      _repo.times(p.masjidId, refresh: p.refresh);
}

class AddMasjid implements UseCase<String, NewMasjid> {
  AddMasjid(this._repo);
  final MasjidRepository _repo;
  @override
  Future<Either<Failure, String>> call(NewMasjid m) => _repo.add(m);
}
