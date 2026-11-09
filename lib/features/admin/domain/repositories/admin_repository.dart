import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_items.dart';
import '../entities/admin_queue.dart';

abstract class AdminRepository {
  /// One page (AppConstants.pageSize rows) of [queue].
  Future<Either<Failure, List<T>>> load<T>(AdminQueue<T> queue, int page);

  Future<Either<Failure, Unit>> perform(AdminAction action);

  Future<Either<Failure, SuggestionAuthor>> suggestionAuthor(
    String suggestionId,
  );

  /// Short-lived signed URL for a claim proof photo (super admin only).
  Future<Either<Failure, String>> proofUrl(String path);
}
