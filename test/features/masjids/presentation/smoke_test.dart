import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/presentation/bloc/masjid_detail_bloc.dart';
import 'package:namazi/features/masjids/presentation/bloc/nearby_bloc.dart';
import 'package:namazi/features/masjids/presentation/pages/masjid_detail_page.dart';
import 'package:namazi/features/masjids/presentation/pages/nearby_page.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/pump_app.dart';

class _MockNearby extends MockBloc<NearbyEvent, NearbyState>
    implements NearbyBloc {}

class _MockDetail extends MockBloc<MasjidDetailEvent, MasjidDetailState>
    implements MasjidDetailBloc {}

final _nearbyStates = {
  'loading': const NearbyState(status: NearbyStatus.locating),
  'loaded': NearbyState(
    status: NearbyStatus.loaded,
    origin: origin,
    masjids: nearbyList,
    next: nearbyList.first,
  ),
  'empty': const NearbyState(status: NearbyStatus.empty, origin: origin),
  'needsArea': const NearbyState(
    status: NearbyStatus.needsArea,
    failure: LocationFailure(LocationProblem.denied),
  ),
  'error': const NearbyState(
    status: NearbyStatus.error,
    failure: NetworkFailure('SocketException: failed host lookup'),
  ),
};

final _detailStates = {
  'loading': const MasjidDetailState(status: MasjidDetailStatus.loading),
  'loaded': MasjidDetailState(
    status: MasjidDetailStatus.loaded,
    masjid: masjidUrdu,
    times: fullTimes,
  ),
  'empty': const MasjidDetailState(
    status: MasjidDetailStatus.empty,
    masjid: masjidLatin,
  ),
  'not found': const MasjidDetailState(
    status: MasjidDetailStatus.error,
    failure: NotFoundFailure('masjid x'),
  ),
  'error': const MasjidDetailState(
    status: MasjidDetailStatus.error,
    masjid: masjidLatin,
    failure: ServerFailure('500: boom'),
  ),
};

void main() {
  for (final size in smokeSizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 2.0]) {
        final tag =
            '${size.width.toInt()}x${size.height.toInt()} '
            '${mode.name} @${scale}x';

        for (final MapEntry(key: name, value: state) in _nearbyStates.entries) {
          testWidgets('NearbyView $name $tag', (tester) async {
            final bloc = _MockNearby();
            whenListen(
              bloc,
              const Stream<NearbyState>.empty(),
              initialState: state,
            );
            await tester.pumpApp(
              BlocProvider<NearbyBloc>.value(
                value: bloc,
                child: const NearbyView(mapTilerKey: ''),
              ),
              size: size,
              mode: mode,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          });
        }

        for (final MapEntry(key: name, value: state) in _detailStates.entries) {
          testWidgets('MasjidDetailView $name $tag', (tester) async {
            final bloc = _MockDetail();
            whenListen(
              bloc,
              const Stream<MasjidDetailState>.empty(),
              initialState: state,
            );
            await tester.pumpApp(
              BlocProvider<MasjidDetailBloc>.value(
                value: bloc,
                child: MasjidDetailView(clock: () => now),
              ),
              size: size,
              mode: mode,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('detail highlights exactly one next row', (tester) async {
    final bloc = _MockDetail();
    whenListen(
      bloc,
      const Stream<MasjidDetailState>.empty(),
      initialState: _detailStates['loaded']!,
    );
    await tester.pumpApp(
      BlocProvider<MasjidDetailBloc>.value(
        value: bloc,
        child: MasjidDetailView(clock: () => now),
      ),
      size: smokeSizes[1],
    );
    expect(find.textContaining('Next · in'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget); // no Jummah time
  });

  testWidgets('nearby banner has a countdown semantics label', (tester) async {
    final semantics = tester.ensureSemantics();
    final bloc = _MockNearby();
    whenListen(
      bloc,
      const Stream<NearbyState>.empty(),
      initialState: _nearbyStates['loaded']!,
    );
    await tester.pumpApp(
      BlocProvider<NearbyBloc>.value(
        value: bloc,
        child: const NearbyView(mapTilerKey: ''),
      ),
      size: smokeSizes[1],
    );
    expect(
      find.semantics.byLabel(
        RegExp(r'Next jamat Zuhr at Test Masjid-e-Noor in 1[78] min'),
      ),
      findsOne,
    );
    semantics.dispose();
  });
}
