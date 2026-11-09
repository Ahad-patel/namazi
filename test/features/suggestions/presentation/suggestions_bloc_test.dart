import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/suggestions/domain/entities/suggestion.dart';
import 'package:namazi/features/suggestions/domain/usecases/suggestion_usecases.dart';
import 'package:namazi/features/suggestions/presentation/bloc/suggestions_bloc.dart';

import '../../../helpers/fixtures.dart';

class _Get extends Mock implements GetSuggestions {}

class _Submit extends Mock implements SubmitSuggestion {}

class _Vote extends Mock implements VoteOnSuggestion {}

void main() {
  late _Get get;
  late _Submit submit;
  late _Vote vote;

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
  });

  SuggestionsBloc build() =>
      SuggestionsBloc(getSuggestions: get, submit: submit, vote: vote);

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
}
