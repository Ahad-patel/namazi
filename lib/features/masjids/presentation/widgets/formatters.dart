import 'package:intl/intl.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/prayer.dart';

String prayerName(AppLocalizations l10n, Prayer p) => switch (p) {
  Prayer.fajr => l10n.prayerFajr,
  Prayer.zuhr => l10n.prayerZuhr,
  Prayer.asr => l10n.prayerAsr,
  Prayer.maghrib => l10n.prayerMaghrib,
  Prayer.isha => l10n.prayerIsha,
  Prayer.jummah => l10n.prayerJummah,
};

String distanceText(AppLocalizations l10n, double metres) => metres < 1000
    ? l10n.distanceM((metres / 10).round() * 10)
    : l10n.distanceKm((metres / 1000).toStringAsFixed(1));

String distanceWalkText(AppLocalizations l10n, double metres) =>
    l10n.distanceWalk(
      distanceText(l10n, metres),
      (metres / AppConstants.walkingMetresPerMinute).ceil().clamp(1, 999),
    );

/// Minutes are rounded up, so "1 min" stays until the jamat actually starts.
String countdownText(AppLocalizations l10n, Duration left) {
  final minutes = (left.inSeconds / 60).ceil().clamp(0, 1 << 30);
  if (minutes < 60) return l10n.countdownMinutes(minutes);
  if (minutes < 24 * 60) {
    return l10n.countdownHours(minutes ~/ 60, minutes % 60);
  }
  return l10n.countdownDays(minutes ~/ (24 * 60), (minutes % (24 * 60)) ~/ 60);
}

String shortDate(AppLocalizations l10n, DateTime d) =>
    DateFormat('d MMM', l10n.localeName).format(d.toLocal());
