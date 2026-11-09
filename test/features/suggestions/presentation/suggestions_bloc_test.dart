import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/suggestions/domain/entities/prayer_window.dart';
import 'package:namazi/features/suggestions/domain/entities/suggestion.dart';
import 'package:namazi/features/suggestions/domain/usecases/suggestion_usecases.dart';
import 'package:namazi/features/suggestions/presentation/bloc/suggestions_bloc.dart';

import '../../../helpers/fixtures.dart';

class _Get extends Mock implements GetSuggestions {}

class _Submit extends Mock implements SubmitSuggestion {}

class _Vote extends Mock implements VoteOnSuggestion {}

class _Windows extends Mock implements GetPrayerWindows {}

void main() {
  late _Get get;
  late _Submit submit;
  late _Vote vote;
  late _Windows windows;

  const draft = SuggestionDraft(
    masjidId: 'm1',
    prayer: Prayer.asr,
    jamat: ClockTime(17, 15),
  );

  setUpAll(() {
    registerFallbackValue(draft);
    registerFallbackValue(const VoteParams('', 0));
  });

  setUp(() {
    get = _Get();
    submit = _Submit();
    vote = _Vote();
    windows = _Windows();
  });

  SuggestionsBloc build() => SuggestionsBloc(
    getSuggestions: get,
    submit: submit,
    vote: vote,
    getWindows: windows,
  );

  final loaded = SuggestionsState(
    status: SuggestionsStatus.loaded,
    masjidId: 'm1',
    items: suggestionList,
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'loads, empty when none',
    setUp: () => when(() => get('m1')).thenAnswer((_) async => const Right([])),
    build: build,
    act: (b) => b.add(const SuggestionsRequested('m1')),
    expect: () => [
      const SuggestionsState(status: SuggestionsStatus.loading, masjidId: 'm1'),
      const SuggestionsState(status: SuggestionsStatus.empty, masjidId: 'm1'),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'load error',
    setUp: () =>
        when(() => get('m1'))
            .thenAnswer((_) async => const Left(NetworkFailure('x'))),
    build: build,
    act: (b) => b.add(const SuggestionsRequested('m1')),
    skip: 1,
    expect: () => [
      const SuggestionsState(
        status: SuggestionsStatus.error,
        masjidId: 'm1',
        failure: NetworkFailure('x'),
      ),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'vote is optimistic and bumps changes on success',
    setUp: () =>
        when(() => vote(const VoteParams('s1', -1)))
            .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => loaded,
    act: (b) => b.add(const SuggestionVoted('s1', -1)),
    expect: () {
      final voted = [suggestionList[0].withVote(-1), suggestionList[1]];
      return [
        loaded.copyWith(items: voted),
        loaded.copyWith(items: voted, changes: 1),
      ];
    },
    verify: (b) {
      // was +1 with 3 net votes; switching to -1 moves it by 2
      expect(b.state.items.first.netVotes, 1);
      expect(b.state.items.first.myVote, -1);
    },
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'vote rolls back with a failure on error',
    setUp: () =>
        when(() => vote(any()))
            .thenAnswer((_) async => const Left(PermissionFailure('rls'))),
    build: build,
    seed: () => loaded,
    act: (b) => b.add(const SuggestionVoted('s1', 0)),
    expect: () => [
      loaded.copyWith(
        items: [suggestionList[0].withVote(0), suggestionList[1]],
      ),
      loaded.copyWith(voteFailure: const PermissionFailure('rls')),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'submit: success, then reloads the list',
    setUp: () {
      when(() => submit(draft)).thenAnswer((_) async => const Right(unit));
      when(() => get('m1')).thenAnswer((_) async => Right(suggestionList));
    },
    build: build,
    seed: () =>
        const SuggestionsState(status: SuggestionsStatus.empty, masjidId: 'm1'),
    act: (b) => b.add(const SuggestionSubmitted(draft)),
    expect: () => [
      const SuggestionsState(
        status: SuggestionsStatus.empty,
        masjidId: 'm1',
        submitStatus: SubmitStatus.submitting,
      ),
      const SuggestionsState(
        status: SuggestionsStatus.empty,
        masjidId: 'm1',
        submitStatus: SubmitStatus.success,
        changes: 1,
      ),
      SuggestionsState(
        status: SuggestionsStatus.loaded,
        masjidId: 'm1',
        items: suggestionList,
        submitStatus: SubmitStatus.success,
        changes: 1,
      ),
    ],
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'submit over the daily limit: failure, list untouched',
    setUp: () =>
        when(() => submit(any()))
            .thenAnswer((_) async => const Left(RateLimitFailure('MT429'))),
    build: build,
    seed: () => loaded,
    act: (b) => b.add(const SuggestionSubmitted(draft)),
    skip: 1,
    expect: () => [
      loaded.copyWith(
        submitStatus: SubmitStatus.failure,
        submitFailure: const RateLimitFailure('MT429'),
      ),
    ],
  );

  const fajr = PrayerWindow(
    prayer: Prayer.fajr,
    starts: ClockTime(5, 17),
    ends: ClockTime(6, 53),
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'opening the sheet loads windows once',
    setUp: () =>
        when(() => windows('m1')).thenAnswer((_) async => const Right([fajr])),
    build: build,
    seed: () => loaded,
    act: (b) => b
      ..add(const SuggestionFormOpened())
      ..add(const SuggestionFormOpened()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      loaded.copyWith(windows: [fajr]),
    ],
    verify: (b) {
      verify(() => windows('m1')).called(1);
      expect(b.state.windowFor(Prayer.fajr), fajr);
      expect(b.state.windowFor(Prayer.isha), isNull);
    },
  );

  blocTest<SuggestionsBloc, SuggestionsState>(
    'windows failing leaves the sheet usable (server still validates)',
    setUp: () =>
        when(() => windows('m1'))
            .thenAnswer((_) async => const Left(NetworkFailure('x'))),
    build: build,
    seed: () => loaded,
    act: (b) => b.add(const SuggestionFormOpened()),
    expect: () => <SuggestionsState>[],
  );

  test('PrayerWindow.contains, including isha past midnight', () {
    expect(fajr.contains(const ClockTime(5, 17)), isTrue);
    expect(fajr.contains(const ClockTime(6, 53)), isTrue);
    expect(fajr.contains(const ClockTime(18, 0)), isFalse);
    const isha = PrayerWindow(
      prayer: Prayer.isha,
      starts: ClockTime(19, 7),
      ends: ClockTime(5, 38),
    );
    expect(isha.contains(const ClockTime(23, 30)), isTrue);
    expect(isha.contains(const ClockTime(2, 0)), isTrue);
    expect(isha.contains(const ClockTime(12, 0)), isFalse);
  });
}
