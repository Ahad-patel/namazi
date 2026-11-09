import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../datasources/suggestion_remote_ds.dart';

class SuggestionRepositoryImpl
    with RepositoryGuard
    implements SuggestionRepository {
  SuggestionRepositoryImpl(this._remote);

  final SuggestionRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Suggestion>>> list(String masjidId) =>
      guard(() => _remote.list(masjidId));

  @override
  Future<Either<Failure, Unit>> submit(SuggestionDraft draft) =>
      guard(() => _remote.submit(draft).then((_) => unit));

  @override
  Future<Either<Failure, Unit>> vote(String suggestionId, int value) =>
      guard(() => _remote.vote(suggestionId, value).then((_) => unit));
}
