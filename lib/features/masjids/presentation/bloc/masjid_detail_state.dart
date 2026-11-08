part of 'masjid_detail_bloc.dart';

enum MasjidDetailStatus { initial, loading, loaded, empty, error }

class MasjidDetailState extends Equatable {
  const MasjidDetailState({
    this.status = MasjidDetailStatus.initial,
    this.masjid,
    this.times = const [],
    this.failure,
  });

  final MasjidDetailStatus status;
  final Masjid? masjid;
  final List<PrayerTime> times;
  final Failure? failure;

  MasjidDetailState copyWith({
    MasjidDetailStatus? status,
    Masjid? masjid,
    List<PrayerTime>? times,
    Failure? failure,
  }) => MasjidDetailState(
    status: status ?? this.status,
    masjid: masjid ?? this.masjid,
    times: times ?? this.times,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, masjid, times, failure];
}
