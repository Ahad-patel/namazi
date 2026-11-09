import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/admin_items.dart';
import '../../domain/entities/admin_queue.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_ds.dart';

class AdminRepositoryImpl with RepositoryGuard implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<T>>> load<T>(AdminQueue<T> queue, int page) =>
      guard(() async => (await _remote.load(queue, page)).cast<T>());

  @override
  Future<Either<Failure, Unit>> perform(AdminAction action) =>
      guard(() => _remote.perform(action).then((_) => unit));

  @override
  Future<Either<Failure, SuggestionAuthor>> suggestionAuthor(
    String suggestionId,
  ) => guard(() => _remote.suggestionAuthor(suggestionId));

  @override
  Future<Either<Failure, String>> proofUrl(String path) =>
      guard(() => _remote.proofUrl(path));
}
