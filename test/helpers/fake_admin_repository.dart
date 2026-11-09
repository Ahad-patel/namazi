import 'package:dartz/dartz.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/admin/domain/entities/admin_items.dart';
import 'package:namazi/features/admin/domain/entities/admin_queue.dart';
import 'package:namazi/features/admin/domain/repositories/admin_repository.dart';
import 'package:namazi/features/claims/domain/entities/claim.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';

final _at = DateTime.utc(2026, 11, 8, 10);

final fakeClaims = [
  ClaimItem(
    id: 'c1',
    masjidName: 'Test Masjid Colaba with a fairly long name that wraps',
    masjidSlug: 'colaba',
    role: ClaimRole.mutawalli,
    createdAt: _at,
    userName: 'Abdul Rahman',
    phone: '+919800000000',
    proofPath: 'u1/c1.jpg',
  ),
  ClaimItem(
    id: 'c2',
    masjidName: 'Masjid-e-Noor',
    masjidSlug: 'noor',
    role: ClaimRole.imam,
    createdAt: _at,
  ),
];

final fakeMasjids = [
  ModerationMasjid(
    id: 'm1',
    slug: 'noor',
    name: 'Test Masjid-e-Noor',
    nameLocal: 'مسجد نور',
    lat: 18.95,
    lng: 72.83,
    createdAt: _at,
    createdByName: 'Someone',
  ),
];

final fakeSuggestions = [
  SuggestionItem(
    id: 's1',
    masjidName: 'Masjid-e-Noor',
    prayer: Prayer.zuhr,
    jamat: const ClockTime(13, 30),
    createdAt: _at,
    note: 'Board outside says 1:30',
    netVotes: -3,
    authorName: 'Spammer',
  ),
];

final fakeLog = [
  LogEntry(
    id: 1,
    action: 'ban_user',
    targetTable: 'profiles',
    createdAt: _at,
    reason: 'spam',
  ),
  LogEntry(id: 2, action: 'something_new', targetTable: 'x', createdAt: _at),
];

final fakeInbox = [
  InboxItem(
    id: 's2',
    prayer: Prayer.fajr,
    jamat: const ClockTime(5, 50),
    netVotes: 3,
    createdAt: _at,
    note: 'Changed from Monday',
    verifiedJamat: const ClockTime(5, 40),
  ),
];

/// In-memory [AdminRepository]: fixed rows per queue, [failWith] makes every
/// call fail, [pages] counts how many rows to return per page.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.failWith, this.empty = false});

  Failure? failWith;
  bool empty;
  final performed = <AdminAction>[];
  final loads = <(AdminQueue<dynamic>, int)>[];

  List<Object> _rows(AdminQueue<dynamic> q) => switch (q) {
    ClaimsQueue() => fakeClaims,
    MasjidsQueue() => fakeMasjids,
    OpenSuggestionsQueue() || HiddenSuggestionsQueue() => fakeSuggestions,
    BannedUsersQueue() => const [BannedUser(id: 'u4', displayName: 'Spammer')],
    ModerationLogQueue() => fakeLog,
    InboxQueue() => fakeInbox,
  };

  @override
  Future<Either<Failure, List<T>>> load<T>(
    AdminQueue<T> queue,
    int page,
  ) async {
    loads.add((queue, page));
    final f = failWith;
    if (f != null) return Left(f);
    if (empty || page > 0) return const Right([]);
    return Right(_rows(queue).cast<T>());
  }

  @override
  Future<Either<Failure, Unit>> perform(AdminAction action) async {
    performed.add(action);
    final f = failWith;
    return f == null ? const Right(unit) : Left(f);
  }

  @override
  Future<Either<Failure, SuggestionAuthor>> suggestionAuthor(String id) async =>
      const Right(
        SuggestionAuthor(displayName: 'Spammer', openCount: 7, isBanned: false),
      );

  @override
  Future<Either<Failure, String>> proofUrl(String path) async =>
      const Left(NetworkFailure('no network in tests'));
}
