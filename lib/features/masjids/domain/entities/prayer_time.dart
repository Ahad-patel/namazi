import 'package:equatable/equatable.dart';

import 'prayer.dart';

/// What the `masjid_times` RPC says to display for one namaz.
class PrayerTime extends Equatable {
  const PrayerTime({
    required this.prayer,
    required this.jamat,
    required this.source,
    required this.updatedAt,
    required this.nextAt,
    this.azaan,
    this.netVotes,
    this.differingReports = 0,
    this.stale = false,
    this.communityAzaan,
    this.communityJamat,
    this.communityNetVotes,
  });

  final Prayer prayer;
  final ClockTime? azaan;
  final ClockTime jamat;
  final TimeSource source;
  final DateTime updatedAt;

  /// The next real instant this jamat happens (computed server side in the
  /// masjid's timezone). Drives the countdown and the "next" highlight.
  final DateTime? nextAt;

  /// Community rows only.
  final int? netVotes;

  /// "N people report a different time"; 0 unless the server says >= 2.
  final int differingReports;

  /// Verified time not updated for 120 days ("May be outdated").
  final bool stale;

  /// The top community suggestion, set only when [stale].
  final ClockTime? communityAzaan;
  final ClockTime? communityJamat;
  final int? communityNetVotes;

  @override
  List<Object?> get props => [
    prayer,
    azaan,
    jamat,
    source,
    updatedAt,
    nextAt,
    netVotes,
    differingReports,
    stale,
    communityAzaan,
    communityJamat,
    communityNetVotes,
  ];
}

/// The row to highlight: the soonest upcoming jamat after [now], if any.
PrayerTime? nextOf(Iterable<PrayerTime> times, DateTime now) {
  PrayerTime? best;
  for (final t in times) {
    final at = t.nextAt;
    if (at == null || !at.isAfter(now)) continue;
    if (best == null || at.isBefore(best.nextAt!)) best = t;
  }
  return best;
}
