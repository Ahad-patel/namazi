import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/masjids/domain/entities/prayer_time.dart';

import '../../../helpers/fixtures.dart';

void main() {
  test('picks the soonest future jamat', () {
    expect(nextOf(fullTimes, now)?.prayer, Prayer.zuhr);
  });

  test('skips rows whose time already passed', () {
    final later = now.add(const Duration(hours: 2));
    expect(nextOf(fullTimes, later)?.prayer, Prayer.asr);
  });

  test('rows without nextAt are ignored; none left = null', () {
    expect(nextOf([time(Prayer.isha, 20, 30)], now), isNull);
    expect(nextOf(const [], now), isNull);
  });

  test('ClockTime parses Postgres time', () {
    expect(ClockTime.parse('05:30:00'), const ClockTime(5, 30));
    expect(ClockTime.parse('13:05'), const ClockTime(13, 5));
  });
}
