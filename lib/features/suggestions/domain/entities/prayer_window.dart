import 'package:equatable/equatable.dart';

import '../../../masjids/domain/entities/prayer.dart';

/// When a jamat for [prayer] may be at this masjid today, from the
/// `prayer_windows` RPC (sun position at the masjid). Isha wraps past
/// midnight. The server trigger is the real check; this only lets the sheet
/// say so before sending.
class PrayerWindow extends Equatable {
  const PrayerWindow({
    required this.prayer,
    required this.starts,
    required this.ends,
  });

  final Prayer prayer;
  final ClockTime starts;
  final ClockTime ends;

  bool contains(ClockTime t) => starts.compareTo(ends) <= 0
      ? t.compareTo(starts) >= 0 && t.compareTo(ends) <= 0
      : t.compareTo(starts) >= 0 || t.compareTo(ends) <= 0;

  @override
  List<Object?> get props => [prayer, starts, ends];
}
