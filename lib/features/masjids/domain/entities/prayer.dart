import 'package:equatable/equatable.dart';

/// Order matches the display order on the detail page.
enum Prayer { fajr, zuhr, asr, maghrib, isha, jummah }

enum TimeSource { verified, community }

/// A local wall-clock time at the masjid (no date, no timezone).
class ClockTime extends Equatable implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  /// Parses Postgres `time` output: `HH:MM` or `HH:MM:SS`.
  factory ClockTime.parse(String s) {
    final parts = s.split(':');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  /// `HH:MM`, the form Postgres `time` accepts.
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) =>
      (hour * 60 + minute) - (other.hour * 60 + other.minute);

  @override
  List<Object?> get props => [hour, minute];
}
