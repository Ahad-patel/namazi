import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/suggestion.dart';
import '../repositories/suggestion_repository.dart';

class GetSuggestions implements UseCase<List<Suggestion>, String> {
  GetSuggestions(this._repo);
  final SuggestionRepository _repo;
  @override
  Future<Either<Failure, List<Suggestion>>> call(String masjidId) =>
      _repo.list(masjidId);
}

class SubmitSuggestion implements UseCase<Unit, SuggestionDraft> {
  SubmitSuggestion(this._repo);
  final SuggestionRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(SuggestionDraft d) => _repo.submit(d);
}

class VoteParams extends Equatable {
  const VoteParams(this.suggestionId, this.value);
  final String suggestionId;
  final int value;
  @override
  List<Object?> get props => [suggestionId, value];
}

class VoteOnSuggestion implements UseCase<Unit, VoteParams> {
  VoteOnSuggestion(this._repo);
  final SuggestionRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(VoteParams p) =>
      _repo.vote(p.suggestionId, p.value);
}
