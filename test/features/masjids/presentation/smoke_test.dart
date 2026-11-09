import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:namazi/features/masjids/presentation/bloc/masjid_detail_bloc.dart';
import 'package:namazi/features/masjids/presentation/bloc/nearby_bloc.dart';
import 'package:namazi/features/masjids/presentation/pages/masjid_detail_page.dart';
import 'package:namazi/features/masjids/presentation/pages/nearby_page.dart';
import 'package:namazi/features/suggestions/presentation/bloc/suggestions_bloc.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/pump_app.dart';

class _MockNearby extends MockBloc<NearbyEvent, NearbyState>
    implements NearbyBloc {}

class _MockDetail extends MockBloc<MasjidDetailEvent, MasjidDetailState>
    implements MasjidDetailBloc {}

class _MockSuggestions extends MockBloc<SuggestionsEvent, SuggestionsState>
    implements SuggestionsBloc {}

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Detail view with its suggestions + auth blocs mocked.
Widget _detail(MasjidDetailState state, {SuggestionsState? suggestions}) {
  final bloc = _MockDetail();
  whenListen(
    bloc,
    const Stream<MasjidDetailState>.empty(),
    initialState: state,
  );
  final sBloc = _MockSuggestions();
  whenListen(
    sBloc,
    const Stream<SuggestionsState>.empty(),
    initialState:
        suggestions ??
        SuggestionsState(
          status: SuggestionsStatus.loaded,
          masjidId: 'm2',
          items: suggestionList,
        ),
  );
  final auth = _MockAuth();
  whenListen(
    auth,
    const Stream<AuthState>.empty(),
    initialState: const AuthState(status: AuthStatus.unauthenticated),
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<MasjidDetailBloc>.value(value: bloc),
      BlocProvider<SuggestionsBloc>.value(value: sBloc),
    ],
    child: MasjidDetailView(clock: () => now),
  );
}

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
  'trust rules': MasjidDetailState(
    status: MasjidDetailStatus.loaded,
    masjid: masjidLatin,
    times: trustTimes,
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
            await tester.pumpApp(
              _detail(state),
              size: size,
              mode: mode,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          });
        }

        for (final MapEntry(key: name, value: ss) in {
          'loading': const SuggestionsState(status: SuggestionsStatus.loading),
          'empty': const SuggestionsState(status: SuggestionsStatus.empty),
          'error': const SuggestionsState(
            status: SuggestionsStatus.error,
            failure: NetworkFailure('offline'),
          ),
        }.entries) {
          testWidgets('Detail suggestions $name $tag', (tester) async {
            await tester.pumpApp(
              _detail(_detailStates['loaded']!, suggestions: ss),
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

  testWidgets('trust rules: stale, differing reports, community', (
    tester,
  ) async {
    await tester.pumpApp(
      _detail(_detailStates['trust rules']!),
      size: smokeSizes[1],
    );
    expect(find.text('May be outdated'), findsOneWidget);
    expect(find.text('4 people report a different time'), findsOneWidget);
    expect(find.textContaining('Community ·'), findsOneWidget);
    expect(find.text('Suggest'), findsNWidgets(4)); // zuhr, asr, isha, jummah
  });

  testWidgets('detail highlights exactly one next row', (tester) async {
    await tester.pumpApp(
      _detail(_detailStates['loaded']!),
      size: smokeSizes[1],
    );
    expect(find.textContaining('Next · in'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget); // no Jummah time
    await tester.scrollUntilVisible(find.text('Your suggestion · 6 Nov'), 200);
    expect(find.text('Community suggestions'), findsOneWidget);
    // no vote buttons on your own suggestion
    expect(find.byTooltip('Upvote'), findsOneWidget);
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
