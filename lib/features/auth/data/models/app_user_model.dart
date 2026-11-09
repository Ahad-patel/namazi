import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.role,
    super.isBanned,
    super.isAdult,
    super.termsVersion,
    super.termsAcceptedAt,
  });

  static const columns =
      'id,display_name,role,is_banned,is_adult,terms_version,terms_accepted_at';

  /// [email] comes from the auth session, not from `profiles`.
  factory AppUserModel.fromJson(Map<String, dynamic> j, {String? email}) =>
      AppUserModel(
        id: j['id'] as String,
        email: email,
        displayName: j['display_name'] as String?,
        role: j['role'] == 'super_admin' ? UserRole.superAdmin : UserRole.user,
        isBanned: j['is_banned'] as bool? ?? false,
        isAdult: j['is_adult'] as bool? ?? false,
        termsVersion: j['terms_version'] as String?,
        termsAcceptedAt: j['terms_accepted_at'] == null
            ? null
            : DateTime.parse(j['terms_accepted_at'] as String),
      );
}
