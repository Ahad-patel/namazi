import 'package:equatable/equatable.dart';

import 'masjid.dart';
import 'prayer_time.dart';

class NearbyMasjid extends Equatable {
  const NearbyMasjid({
    required this.masjid,
    required this.distanceM,
    this.next,
  });

  final Masjid masjid;
  final double distanceM;

  /// Soonest upcoming jamat at this masjid, null when it has no times.
  final PrayerTime? next;

  @override
  List<Object?> get props => [masjid, distanceM, next];
}
