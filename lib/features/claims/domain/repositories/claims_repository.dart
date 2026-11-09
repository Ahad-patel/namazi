import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/claim.dart';

abstract class ClaimsRepository {
  Future<Either<Failure, MasjidAccess>> access(String masjidId);

  /// Uploads the proof photo (if any) to `<user_id>/<claim_id>.jpg`, then
  /// inserts the pending claim.
  Future<Either<Failure, Unit>> submit(ClaimDraft draft);
}
