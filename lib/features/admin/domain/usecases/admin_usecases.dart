import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_items.dart';
import '../entities/admin_queue.dart';
import '../repositories/admin_repository.dart';

/// Generic over the row type, so it can't implement `UseCase<R, P>`.
class LoadAdminQueue {
  LoadAdminQueue(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<T>>> call<T>(AdminQueue<T> q, int page) =>
      _repo.load(q, page);
}

class PerformAdminAction implements UseCase<Unit, AdminAction> {
  PerformAdminAction(this._repo);
  final AdminRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(AdminAction a) => _repo.perform(a);
}

class GetSuggestionAuthor implements UseCase<SuggestionAuthor, String> {
  GetSuggestionAuthor(this._repo);
  final AdminRepository _repo;
  @override
  Future<Either<Failure, SuggestionAuthor>> call(String id) =>
      _repo.suggestionAuthor(id);
}

class GetProofUrl implements UseCase<String, String> {
  GetProofUrl(this._repo);
  final AdminRepository _repo;
  @override
  Future<Either<Failure, String>> call(String path) => _repo.proofUrl(path);
}
