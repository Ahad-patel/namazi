import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/prayer_window.dart';
import '../entities/suggestion.dart';

abstract class SuggestionRepository {
  Future<Either<Failure, List<Suggestion>>> list(String masjidId);

  /// Today's allowed time per namaz at this masjid.
  Future<Either<Failure, List<PrayerWindow>>> windows(String masjidId);

  /// Replaces the caller's previous open suggestion for that namaz.
  Future<Either<Failure, Unit>> submit(SuggestionDraft draft);

  /// [value] -1 / 1, or 0 to remove the caller's vote.
  Future<Either<Failure, Unit>> vote(String suggestionId, int value);
}
