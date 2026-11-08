import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/data/datasources/masjid_remote_ds.dart';
import 'package:namazi/features/masjids/data/models/masjid_models.dart';
import 'package:namazi/features/masjids/data/repositories/masjid_repository_impl.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';

import '../../../helpers/fixtures.dart';

class _MockDs extends Mock implements MasjidRemoteDataSource {}

void main() {
  late _MockDs ds;
  late DateTime clock;
  late MasjidRepositoryImpl repo;

  final row = PrayerTimeModel.fromJson(const {
    'prayer': 'fajr',
    'azaan_time': '05:15:00',
    'jamat_time': '05:30:00',
    'source': 'verified',
    'updated_at': '2026-11-03T10:00:00+00:00',
    'next_at': '2026-11-09T00:00:00+00:00',
  });

  setUp(() {
    ds = _MockDs();
    clock = DateTime(2026, 11, 8, 12);
    repo = MasjidRepositoryImpl(ds, clock: () => clock);
  });

  test('times: parses and returns rows', () async {
    when(() => ds.times('m1')).thenAnswer((_) async => [row]);
    final r = await repo.times('m1');
    final list = r.getOrElse(() => fail('expected Right'));
    expect(list.single.prayer, Prayer.fajr);
    expect(list.single.jamat, const ClockTime(5, 30));
    expect(list.single.azaan, const ClockTime(5, 15));
  });

  test('times: cached for 5 minutes, refresh bypasses the cache', () async {
    when(() => ds.times('m1')).thenAnswer((_) async => [row]);
    await repo.times('m1');
    clock = clock.add(const Duration(minutes: 4));
    await repo.times('m1');
    verify(() => ds.times('m1')).called(1);

    await repo.times('m1', refresh: true);
    verify(() => ds.times('m1')).called(1);

    clock = clock.add(const Duration(minutes: 6));
    await repo.times('m1');
    verify(() => ds.times('m1')).called(1);
  });

  test('bySlug: NotFoundException becomes NotFoundFailure', () async {
    when(() => ds.bySlug('x')).thenThrow(NotFoundException('masjid x'));
    final r = await repo.bySlug('x');
    expect(r.fold((f) => f, (_) => null), isA<NotFoundFailure>());
  });

  test('nearby: RLS denial becomes PermissionFailure', () async {
    when(() => ds.nearby(any(), any(), any()))
        .thenThrow(PermissionException('42501'));
    final r = await repo.nearby(origin, 3000);
    expect(r.fold((f) => f, (_) => null), isA<PermissionFailure>());
  });

  test('NearbyMasjidModel parses a row without a next jamat', () {
    final m = NearbyMasjidModel.fromJson(const {
      'id': 'm1',
      'slug': 's',
      'name': 'N',
      'name_local': 'مسجد',
      'name_script': 'urdu',
      'address': null,
      'timezone': 'Asia/Kolkata',
      'latitude': 19.0,
      'longitude': 72.8,
      'distance_m': 512.3,
      'next_prayer': null,
      'next_jamat_time': null,
      'next_source': null,
      'next_updated_at': null,
      'next_at': null,
    });
    expect(m.next, isNull);
    expect(m.distanceM, 512.3);
  });
}
