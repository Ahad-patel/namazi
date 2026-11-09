import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claims_repository.dart';
import '../datasources/claims_remote_ds.dart';

class ClaimsRepositoryImpl with RepositoryGuard implements ClaimsRepository {
  ClaimsRepositoryImpl(this._remote);

  final ClaimsRemoteDataSource _remote;

  @override
  Future<Either<Failure, MasjidAccess>> access(String masjidId) =>
      guard(() => _remote.access(masjidId));

  @override
  Future<Either<Failure, Unit>> submit(ClaimDraft draft) =>
      guard(() => _remote.submit(draft).then((_) => unit));
}
