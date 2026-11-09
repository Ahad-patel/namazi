import 'package:namazi/features/auth/domain/entities/app_user.dart';
import 'package:namazi/features/location/domain/entities/geo_point.dart';
import 'package:namazi/features/masjids/domain/entities/masjid.dart';
import 'package:namazi/features/masjids/domain/entities/nearby_masjid.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/masjids/domain/entities/prayer_time.dart';
import 'package:namazi/features/suggestions/domain/entities/suggestion.dart';

const origin = GeoPoint(19.0760, 72.8777);

const masjidLatin = Masjid(
  id: 'm1',
  slug: 'test-masjid-colaba',
  name: 'Test Masjid Colaba with a fairly long name that wraps onto two lines',
  location: GeoPoint(18.9067, 72.8311),
  timezone: 'Asia/Kolkata',
  address: 'Colaba, Mumbai',
);

const masjidUrdu = Masjid(
  id: 'm2',
  slug: 'test-masjid-noor',
  name: 'Test Masjid-e-Noor',
  nameLocal: 'مسجد نور',
  nameScript: NameScript.urdu,
  location: GeoPoint(18.9562, 72.8347),
  timezone: 'Asia/Kolkata',
);

final now = DateTime.now();

PrayerTime time(Prayer p, int h, int m, {Duration? inFuture}) => PrayerTime(
  prayer: p,
  azaan: ClockTime(h, m == 0 ? 0 : m - 1),
  jamat: ClockTime(h, m),
  source: TimeSource.verified,
  updatedAt: DateTime(2026, 11, 3),
  nextAt: inFuture == null ? null : now.add(inFuture),
);

final fullTimes = [
  time(Prayer.fajr, 5, 45, inFuture: const Duration(hours: 17)),
  time(Prayer.zuhr, 13, 30, inFuture: const Duration(minutes: 90)),
  time(Prayer.asr, 17, 15, inFuture: const Duration(hours: 5)),
  time(Prayer.maghrib, 18, 35, inFuture: const Duration(hours: 6)),
  time(Prayer.isha, 20, 30, inFuture: const Duration(hours: 8)),
];

final nearbyList = [
  NearbyMasjid(
    masjid: masjidUrdu,
    distanceM: 420,
    next: time(Prayer.zuhr, 13, 30, inFuture: const Duration(minutes: 18)),
  ),
  const NearbyMasjid(masjid: masjidLatin, distanceM: 2300),
];

/// Trust-rule variants: a stale verified time with a community line and
/// differing reports, plus a community-sourced time.
final trustTimes = [
  PrayerTime(
    prayer: Prayer.fajr,
    jamat: const ClockTime(5, 45),
    source: TimeSource.verified,
    updatedAt: DateTime(2026, 5, 1),
    nextAt: now.add(const Duration(hours: 17)),
    stale: true,
    communityJamat: const ClockTime(5, 50),
    communityNetVotes: 3,
    differingReports: 4,
  ),
  PrayerTime(
    prayer: Prayer.maghrib,
    jamat: const ClockTime(18, 40),
    source: TimeSource.community,
    updatedAt: DateTime(2026, 11, 6),
    nextAt: now.add(const Duration(hours: 6)),
    netVotes: 2,
  ),
];

final suggestionList = [
  Suggestion(
    id: 's1',
    prayer: Prayer.zuhr,
    jamat: const ClockTime(13, 45),
    azaan: const ClockTime(13, 15),
    note: 'From the notice board at the gate, updated this week',
    netVotes: 3,
    createdAt: DateTime(2026, 11, 7),
    myVote: 1,
  ),
  Suggestion(
    id: 's2',
    prayer: Prayer.isha,
    jamat: const ClockTime(20, 45),
    netVotes: -1,
    createdAt: DateTime(2026, 11, 6),
    isMine: true,
  ),
];

const signedInUser = AppUser(
  id: 'u1',
  email: 'user@test.local',
  displayName: 'Test User',
  isAdult: true,
  termsVersion: 't1',
);
