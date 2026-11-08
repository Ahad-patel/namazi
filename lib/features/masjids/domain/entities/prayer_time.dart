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
  });

  final Prayer prayer;
  final ClockTime? azaan;
  final ClockTime jamat;
  final TimeSource source;
  final DateTime updatedAt;

  /// The next real instant this jamat happens (computed server side in the
  /// masjid's timezone). Drives the countdown and the "next" highlight.
  final DateTime? nextAt;

  @override
  List<Object?> get props => [prayer, azaan, jamat, source, updatedAt, nextAt];
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
