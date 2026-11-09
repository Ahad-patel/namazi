import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/suggestions/data/datasources/suggestion_remote_ds.dart';
import 'package:namazi/features/suggestions/data/models/suggestion_model.dart';
import 'package:namazi/features/suggestions/data/repositories/suggestion_repository_impl.dart';
import 'package:namazi/features/suggestions/domain/entities/suggestion.dart';

class _Ds extends Mock implements SuggestionRemoteDataSource {}

void main() {
  late _Ds ds;
  late SuggestionRepositoryImpl repo;

  const draft = SuggestionDraft(
    masjidId: 'm1',
    prayer: Prayer.zuhr,
    jamat: ClockTime(13, 5),
    azaan: ClockTime(12, 45),
    note: '  ',
  );

  setUpAll(() => registerFallbackValue(draft));

  setUp(() {
    ds = _Ds();
    repo = SuggestionRepositoryImpl(ds);
  });

  test('parses masjid_suggestions rows', () async {
    when(() => ds.list('m1')).thenAnswer(
      (_) async => [
        SuggestionModel.fromJson(const {
          'id': 's1',
          'prayer': 'zuhr',
          'azaan_time': null,
          'jamat_time': '13:45:00',
          'note': 'board',
          'net_votes': 2,
          'created_at': '2026-11-07T10:00:00+00:00',
          'is_mine': false,
          'my_vote': -1,
        }),
      ],
    );
    final s = (await repo.list('m1')).getOrElse(() => fail('Right')).single;
    expect(s.jamat, const ClockTime(13, 45));
    expect(s.azaan, isNull);
    expect(s.myVote, -1);
    expect(s.netVotes, 2);
  });

  test('draft payload: HH:MM times, blank note becomes null', () {
    expect(SuggestionModel.draftToJson(draft), {
      'masjid_id': 'm1',
      'prayer': 'zuhr',
      'jamat_time': '13:05',
      'azaan_time': '12:45',
      'note': null,
    });
  });

  test('the 10-a-day trigger surfaces as RateLimitFailure', () async {
    when(() => ds.submit(any())).thenThrow(RateLimitException('MT429'));
    final r = await repo.submit(draft);
    expect(r.fold((f) => f, (_) => null), isA<RateLimitFailure>());
  });

  test(
    'voting on own suggestion (RLS) surfaces as PermissionFailure',
    () async {
      when(() => ds.vote('s1', 1)).thenThrow(PermissionException('42501'));
      final r = await repo.vote('s1', 1);
      expect(r.fold((f) => f, (_) => null), isA<PermissionFailure>());
    },
  );

  test('withVote moves net votes by the difference', () {
    final s = Suggestion(
      id: 's',
      prayer: Prayer.fajr,
      jamat: const ClockTime(5, 30),
      netVotes: 4,
      createdAt: DateTime(2026),
      myVote: 1,
    );
    expect(s.withVote(-1).netVotes, 2);
    expect(s.withVote(0).netVotes, 3);
    expect(s.withVote(1).netVotes, 4);
  });
}
