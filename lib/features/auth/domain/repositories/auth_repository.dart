import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// The signed-in user id (null = signed out) each time the session changes,
  /// starting with the current one. Auth errors (e.g. a failed OAuth
  /// redirect) arrive as a Left.
  Stream<Either<Failure, String?>> get sessionChanges;

  /// Own profile, null when signed out.
  Future<Either<Failure, AppUser?>> currentUser();

  /// Opens Google sign-in. The session arrives later through [sessionChanges].
  Future<Either<Failure, Unit>> signInWithGoogle();

  /// Emails a one-time code.
  Future<Either<Failure, Unit>> sendEmailCode(String email);

  Future<Either<Failure, Unit>> verifyEmailCode(String email, String code);

  Future<Either<Failure, Unit>> signOut();

  /// Profile, suggestions, votes, claims as a JSON document (my_data()).
  Future<Either<Failure, String>> myData();

  /// Deletes the account server side and signs out. Suggestions stay,
  /// anonymised.
  Future<Either<Failure, Unit>> deleteAccount();

  /// "I am 18 or older" + "I agree to the Terms and Privacy Policy".
  Future<Either<Failure, Unit>> acceptTerms(String version);
}
