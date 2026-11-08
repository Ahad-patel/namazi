import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/domain/entities/prayer_time.dart';
import 'package:namazi/features/masjids/domain/usecases/masjid_usecases.dart';
import 'package:namazi/features/masjids/presentation/bloc/masjid_detail_bloc.dart';

import '../../../helpers/fixtures.dart';

class _BySlug extends Mock implements GetMasjidBySlug {}

class _Times extends Mock implements GetMasjidTimes {}

void main() {
  late _BySlug bySlug;
  late _Times times;

  setUpAll(() => registerFallbackValue(const TimesParams('')));

  setUp(() {
    bySlug = _BySlug();
    times = _Times();
  });

  MasjidDetailBloc build() =>
      MasjidDetailBloc(getBySlug: bySlug, getTimes: times);

  blocTest<MasjidDetailBloc, MasjidDetailState>(
    'deep link: loads masjid by slug, then its times',
    setUp: () {
      when(() => bySlug(masjidUrdu.slug))
          .thenAnswer((_) async => const Right(masjidUrdu));
      when(() => times(any())).thenAnswer((_) async => Right(fullTimes));
    },
    build: build,
    act: (b) => b.add(MasjidDetailRequested(masjidUrdu.slug)),
    expect: () => [
      const MasjidDetailState(status: MasjidDetailStatus.loading),
      MasjidDetailState(
        status: MasjidDetailStatus.loaded,
        masjid: masjidUrdu,
        times: fullTimes,
      ),
    ],
  );

  blocTest<MasjidDetailBloc, MasjidDetailState>(
    'from the list: known masjid skips the slug lookup',
    setUp: () =>
        when(() => times(any()))
            .thenAnswer((_) async => const Right(<PrayerTime>[])),
    build: build,
    act: (b) =>
        b.add(MasjidDetailRequested(masjidUrdu.slug, known: masjidUrdu)),
    expect: () => [
      const MasjidDetailState(
        status: MasjidDetailStatus.loading,
        masjid: masjidUrdu,
      ),
      const MasjidDetailState(
        status: MasjidDetailStatus.empty,
        masjid: masjidUrdu,
      ),
    ],
    verify: (_) => verifyNever(() => bySlug(any())),
  );

  blocTest<MasjidDetailBloc, MasjidDetailState>(
    'unknown slug: error with NotFoundFailure; retry tries the slug again',
    setUp: () => when(() => bySlug('nope'))
        .thenAnswer((_) async => const Left(NotFoundFailure('masjid nope'))),
    build: build,
    act: (b) async {
      b.add(const MasjidDetailRequested('nope'));
      await Future<void>.delayed(Duration.zero);
      b.add(const MasjidDetailRefreshed());
    },
    expect: () => [
      const MasjidDetailState(status: MasjidDetailStatus.loading),
      const MasjidDetailState(
        status: MasjidDetailStatus.error,
        failure: NotFoundFailure('masjid nope'),
      ),
      const MasjidDetailState(
        status: MasjidDetailStatus.loading,
        failure: NotFoundFailure('masjid nope'),
      ),
      const MasjidDetailState(
        status: MasjidDetailStatus.error,
        failure: NotFoundFailure('masjid nope'),
      ),
    ],
    verify: (_) => verify(() => bySlug('nope')).called(2),
  );

  blocTest<MasjidDetailBloc, MasjidDetailState>(
    'refresh bypasses the times cache',
    setUp: () =>
        when(() => times(any())).thenAnswer((_) async => Right(fullTimes)),
    build: build,
    seed: () => MasjidDetailState(
      status: MasjidDetailStatus.loaded,
      masjid: masjidUrdu,
      times: fullTimes,
    ),
    act: (b) => b.add(const MasjidDetailRefreshed()),
    verify: (_) =>
        verify(() => times(TimesParams(masjidUrdu.id, refresh: true)))
            .called(1),
  );
}
