import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/config/app_constants.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/usecase/usecase.dart';
import 'package:namazi/features/location/domain/entities/geo_point.dart';
import 'package:namazi/features/location/domain/usecases/location_usecases.dart';
import 'package:namazi/features/masjids/domain/entities/nearby_masjid.dart';
import 'package:namazi/features/masjids/domain/usecases/masjid_usecases.dart';
import 'package:namazi/features/masjids/presentation/bloc/nearby_bloc.dart';

import '../../../helpers/fixtures.dart';

class _Locate extends Mock implements GetCurrentLocation {}

class _Search extends Mock implements SearchArea {}

class _Nearby extends Mock implements GetNearbyMasjids {}

class _Next extends Mock implements GetNextJamatNearby {}

void main() {
  late _Locate locate;
  late _Search search;
  late _Nearby nearby;
  late _Next next;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const NearbyParams(origin, 0));
  });

  setUp(() {
    locate = _Locate();
    search = _Search();
    nearby = _Nearby();
    next = _Next();
    when(() => next(any())).thenAnswer((_) async => Right(nearbyList.first));
  });

  NearbyBloc build() => NearbyBloc(
    getCurrentLocation: locate,
    searchArea: search,
    getNearby: nearby,
    getNextJamat: next,
    debounce: Duration.zero,
  );

  blocTest<NearbyBloc, NearbyState>(
    'located: loads list and banner in parallel',
    setUp: () {
      when(() => locate(any())).thenAnswer((_) async => const Right(origin));
      when(() => nearby(any())).thenAnswer((_) async => Right(nearbyList));
    },
    build: build,
    act: (b) => b.add(const NearbyLocateRequested()),
    expect: () => [
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.locating,
      ),
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.loading,
      ),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.loaded)
          .having((s) => s.masjids, 'masjids', nearbyList)
          .having((s) => s.next, 'next', nearbyList.first)
          .having((s) => s.origin, 'origin', origin),
    ],
    verify: (_) {
      verify(
        () => nearby(const NearbyParams(origin, AppConstants.nearbyRadiusM)),
      ).called(1);
      verify(() => next(const NearbyParams(origin, AppConstants.nearbyRadiusM)))
          .called(1);
    },
  );

  blocTest<NearbyBloc, NearbyState>(
    'location denied: asks for an area, no error',
    setUp: () => when(() => locate(any())).thenAnswer(
      (_) async => const Left(LocationFailure(LocationProblem.denied)),
    ),
    build: build,
    act: (b) => b.add(const NearbyLocateRequested()),
    expect: () => [
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.locating,
      ),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.needsArea)
          .having(
            (s) => s.failure,
            'failure',
            const LocationFailure(LocationProblem.denied),
          ),
    ],
  );

  blocTest<NearbyBloc, NearbyState>(
    'area search: geocodes then loads; label shown',
    setUp: () {
      when(() => search('Bandra')).thenAnswer(
        (_) async => const Right(Place('Bandra West', GeoPoint(19.06, 72.83))),
      );
      when(() => nearby(any())).thenAnswer((_) async => Right(nearbyList));
    },
    build: build,
    act: (b) => b.add(const NearbyAreaQueryChanged('Bandra')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.loading,
      ),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.loading)
          .having((s) => s.areaLabel, 'label', 'Bandra West'),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.loaded)
          .having((s) => s.origin, 'origin', const GeoPoint(19.06, 72.83)),
    ],
  );

  blocTest<NearbyBloc, NearbyState>(
    'area search: typing again cancels the previous search',
    setUp: () {
      when(() => search(any())).thenAnswer(
        (_) async => const Right(Place('Kurla', GeoPoint(19.07, 72.88))),
      );
      when(() => nearby(any())).thenAnswer((_) async => Right(nearbyList));
    },
    build: () => NearbyBloc(
      getCurrentLocation: locate,
      searchArea: search,
      getNearby: nearby,
      getNextJamat: next,
      debounce: const Duration(milliseconds: 20),
    ),
    act: (b) {
      b.add(const NearbyAreaQueryChanged('Ku'));
      b.add(const NearbyAreaQueryChanged('Kurla'));
    },
    wait: const Duration(milliseconds: 60),
    verify: (_) {
      verifyNever(() => search('Ku'));
      verify(() => search('Kurla')).called(1);
    },
  );

  blocTest<NearbyBloc, NearbyState>(
    'area not found',
    setUp: () =>
        when(() => search('zzz')).thenAnswer((_) async => const Right(null)),
    build: build,
    act: (b) => b.add(const NearbyAreaQueryChanged('zzz')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.loading,
      ),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.areaNotFound)
          .having((s) => s.areaQuery, 'query', 'zzz'),
    ],
  );

  blocTest<NearbyBloc, NearbyState>(
    'empty, then "search a wider area" uses the wide radius',
    setUp: () {
      when(() => locate(any())).thenAnswer((_) async => const Right(origin));
      when(() => nearby(any()))
          .thenAnswer((_) async => const Right(<NearbyMasjid>[]));
      when(() => next(any())).thenAnswer((_) async => const Right(null));
    },
    build: build,
    act: (b) async {
      b.add(const NearbyLocateRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const NearbyWiderRequested());
    },
    wait: const Duration(milliseconds: 10),
    skip: 2,
    expect: () => [
      isA<NearbyState>().having((s) => s.status, 'status', NearbyStatus.empty),
      isA<NearbyState>().having(
        (s) => s.status,
        'status',
        NearbyStatus.loading,
      ),
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.empty)
          .having((s) => s.radiusM, 'radius', AppConstants.wideRadiusM)
          .having((s) => s.canWiden, 'canWiden', false),
    ],
  );

  blocTest<NearbyBloc, NearbyState>(
    'server error surfaces as error state',
    setUp: () {
      when(() => locate(any())).thenAnswer((_) async => const Right(origin));
      when(() => nearby(any()))
          .thenAnswer((_) async => const Left(NetworkFailure('timeout')));
    },
    build: build,
    act: (b) => b.add(const NearbyLocateRequested()),
    skip: 2,
    expect: () => [
      isA<NearbyState>()
          .having((s) => s.status, 'status', NearbyStatus.error)
          .having((s) => s.failure, 'failure', const NetworkFailure('timeout')),
    ],
  );
}
