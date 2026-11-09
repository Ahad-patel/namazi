import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claims_repository.dart';

class GetMasjidAccess implements UseCase<MasjidAccess, String> {
  GetMasjidAccess(this._repo);
  final ClaimsRepository _repo;
  @override
  Future<Either<Failure, MasjidAccess>> call(String masjidId) =>
      _repo.access(masjidId);
}

class SubmitClaim implements UseCase<Unit, ClaimDraft> {
  SubmitClaim(this._repo);
  final ClaimsRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(ClaimDraft d) => _repo.submit(d);
}
