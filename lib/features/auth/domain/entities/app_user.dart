import 'package:equatable/equatable.dart';

enum UserRole { user, superAdmin }

/// The signed-in user's own `profiles` row.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.role = UserRole.user,
    this.isBanned = false,
    this.isAdult = false,
    this.termsVersion,
    this.termsAcceptedAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final UserRole role;
  final bool isBanned;
  final bool isAdult;
  final String? termsVersion;
  final DateTime? termsAcceptedAt;

  /// Said "I am 18 or older" and accepted [currentVersion] of the terms.
  /// A new TERMS_VERSION asks again on the next contribution.
  bool hasConsented(String currentVersion) =>
      isAdult && termsAcceptedAt != null && termsVersion == currentVersion;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    role,
    isBanned,
    isAdult,
    termsVersion,
    termsAcceptedAt,
  ];
}
