part of 'nearby_bloc.dart';

enum NearbyStatus {
  initial,
  locating,
  loading,
  loaded,
  empty,
  error,

  /// Location denied/unavailable: the page shows the area search prompt.
  needsArea,
  areaNotFound,
}

const _unset = Object();

class NearbyState extends Equatable {
  const NearbyState({
    this.status = NearbyStatus.initial,
    this.origin,
    this.radiusM = AppConstants.nearbyRadiusM,
    this.areaLabel,
    this.areaQuery,
    this.masjids = const [],
    this.next,
    this.failure,
  });

  final NearbyStatus status;
  final GeoPoint? origin;
  final int radiusM;

  /// Name of the searched area; null means "near you".
  final String? areaLabel;
  final String? areaQuery;
  final List<NearbyMasjid> masjids;
  final NearbyMasjid? next;
  final Failure? failure;

  bool get canWiden => origin != null && radiusM < AppConstants.wideRadiusM;

  NearbyState copyWith({
    NearbyStatus? status,
    GeoPoint? origin,
    int? radiusM,
    Object? areaLabel = _unset,
    String? areaQuery,
    List<NearbyMasjid>? masjids,
    Object? next = _unset,
    Failure? failure,
  }) => NearbyState(
    status: status ?? this.status,
    origin: origin ?? this.origin,
    radiusM: radiusM ?? this.radiusM,
    areaLabel: identical(areaLabel, _unset)
        ? this.areaLabel
        : areaLabel as String?,
    areaQuery: areaQuery ?? this.areaQuery,
    masjids: masjids ?? this.masjids,
    next: identical(next, _unset) ? this.next : next as NearbyMasjid?,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    origin,
    radiusM,
    areaLabel,
    areaQuery,
    masjids,
    next,
    failure,
  ];
}
