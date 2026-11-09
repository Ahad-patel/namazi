import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/features/admin/domain/entities/admin_items.dart';
import 'package:namazi/features/admin/domain/entities/admin_queue.dart';
import 'package:namazi/features/admin/domain/usecases/admin_usecases.dart';
import 'package:namazi/features/admin/presentation/bloc/admin_queue_bloc.dart';
import 'package:namazi/features/claims/domain/entities/claim.dart';

import '../../../helpers/fake_admin_repository.dart';

void main() {
  late FakeAdminRepository repo;
  const queue = ClaimsQueue(ClaimStatus.pending);

  setUp(() => repo = FakeAdminRepository());

  AdminQueueBloc<ClaimItem> build() => AdminQueueBloc<ClaimItem>(
    queue: queue,
    load: LoadAdminQueue(repo),
    perform: PerformAdminAction(repo),
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'loads page 0',
    build: build,
    act: (b) => b.add(const AdminQueueRequested()),
    expect: () => [
      const AdminQueueState<ClaimItem>(status: AdminQueueStatus.loading),
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
      ),
    ],
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'empty queue',
    build: () {
      repo.empty = true;
      return build();
    },
    act: (b) => b.add(const AdminQueueRequested()),
    skip: 1,
    expect: () => [
      const AdminQueueState<ClaimItem>(status: AdminQueueStatus.empty),
    ],
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'load error',
    build: () {
      repo.failWith = const PermissionFailure('42501');
      return build();
    },
    act: (b) => b.add(const AdminQueueRequested()),
    skip: 1,
    expect: () => [
      const AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.error,
        failure: PermissionFailure('42501'),
      ),
    ],
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'load more appends the next page and stops when it is short',
    build: build,
    seed: () => AdminQueueState<ClaimItem>(
      status: AdminQueueStatus.loaded,
      items: fakeClaims,
      hasMore: true,
    ),
    act: (b) => b.add(const AdminQueueMoreRequested()),
    expect: () => [
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
        hasMore: true,
        loadingMore: true,
      ),
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
        page: 1,
      ),
    ],
    verify: (_) => expect(repo.loads.single.$2, 1),
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'action success bumps done and silently reloads page 0',
    build: build,
    seed: () => AdminQueueState<ClaimItem>(
      status: AdminQueueStatus.loaded,
      items: fakeClaims,
    ),
    act: (b) =>
        b.add(const AdminActionRequested(ReviewClaim('c1', approve: true))),
    expect: () => [
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
        busy: true,
      ),
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
        done: 1,
      ),
    ],
    verify: (_) {
      expect(repo.performed, [const ReviewClaim('c1', approve: true)]);
      expect(repo.loads.single.$2, 0);
    },
  );

  blocTest<AdminQueueBloc<ClaimItem>, AdminQueueState<ClaimItem>>(
    'action failure keeps rows and reports the failure',
    build: () {
      repo.failWith = const ConflictFailure('MT409');
      return build();
    },
    seed: () => AdminQueueState<ClaimItem>(
      status: AdminQueueStatus.loaded,
      items: fakeClaims,
    ),
    act: (b) =>
        b.add(const AdminActionRequested(ReviewClaim('c1', approve: true))),
    skip: 1,
    expect: () => [
      AdminQueueState<ClaimItem>(
        status: AdminQueueStatus.loaded,
        items: fakeClaims,
        failures: 1,
        actionFailure: const ConflictFailure('MT409'),
      ),
    ],
    verify: (_) => expect(repo.loads, isEmpty),
  );
}
