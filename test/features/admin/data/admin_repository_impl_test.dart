import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:namazi/core/error/exceptions.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/admin/data/datasources/admin_remote_ds.dart';
import 'package:namazi/features/admin/data/models/admin_models.dart';
import 'package:namazi/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:namazi/features/admin/domain/entities/admin_items.dart';
import 'package:namazi/features/admin/domain/entities/admin_queue.dart';
import 'package:namazi/features/claims/domain/entities/claim.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';

class _Ds extends Mock implements AdminRemoteDataSource {}

void main() {
  late _Ds ds;
  late AdminRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(const ClaimsQueue(ClaimStatus.pending));
    registerFallbackValue(const RestoreSuggestion(''));
  });

  setUp(() {
    ds = _Ds();
    repo = AdminRepositoryImpl(ds);
  });

  test('load returns typed rows', () async {
    when(() => ds.load(any(), 0)).thenAnswer(
      (_) async => [
        ClaimItemModel.fromJson(const {
          'id': 'c1',
          'masjid_name': 'Noor',
          'masjid_slug': 'noor',
          'user_name': null,
          'role_at_masjid': 'committee',
          'phone': '+919800000000',
          'proof_path': null,
          'reason': null,
          'created_at': '2026-11-08T10:00:00+00:00',
        }),
      ],
    );
    final rows = (await repo.load(
      const ClaimsQueue(ClaimStatus.pending),
      0,
    )).getOrElse(() => fail('Right'));
    expect(rows, isA<List<ClaimItem>>());
    expect(rows.single.role, ClaimRole.committee);
    expect(rows.single.userName, isNull);
  });

  test('perform maps MT409 to ConflictFailure', () async {
    when(() => ds.perform(any())).thenThrow(ConflictException('3 admins'));
    final r = await repo.perform(const ReviewClaim('c1', approve: true));
    expect(r.fold((f) => f, (_) => null), isA<ConflictFailure>());
  });

  test('perform maps an RLS refusal to PermissionFailure', () async {
    when(() => ds.perform(any())).thenThrow(PermissionException('42501'));
    final r = await repo.perform(const HideSuggestion('s1'));
    expect(r.fold((f) => f, (_) => null), isA<PermissionFailure>());
  });

  test('models parse RPC rows', () {
    final s = SuggestionItemModel.fromJson(const {
      'id': 's1',
      'masjid_name': 'Noor',
      'prayer': 'isha',
      'jamat_time': '20:45:00',
      'note': null,
      'created_at': '2026-11-08T10:00:00+00:00',
    });
    expect(s.jamat, const ClockTime(20, 45));
    expect(s.netVotes, isNull);

    final i = InboxItemModel.fromJson(const {
      'id': 's2',
      'prayer': 'fajr',
      'azaan_time': '05:20:00',
      'jamat_time': '05:50:00',
      'note': 'x',
      'net_votes': 3,
      'created_at': '2026-11-08T10:00:00+00:00',
      'verified_jamat_time': null,
    });
    expect(i.azaan, const ClockTime(5, 20));
    expect(i.verifiedJamat, isNull);

    final m = ModerationMasjidModel.fromJson(const {
      'id': 'm1',
      'slug': 'noor',
      'name': 'Noor',
      'name_local': null,
      'latitude': 19,
      'longitude': 72.8,
      'created_by_name': null,
      'created_at': '2026-11-08T10:00:00+00:00',
    });
    expect(m.lat, 19.0);

    final l = LogEntryModel.fromJson(const {
      'id': 7,
      'action': 'hide_masjid',
      'target_table': 'masjids',
      'reason': null,
      'created_at': '2026-11-08T10:00:00+00:00',
    });
    expect(l.action, 'hide_masjid');
  });

  test('isoDate pads to yyyy-mm-dd', () {
    expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
