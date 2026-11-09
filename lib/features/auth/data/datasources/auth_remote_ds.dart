import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
import '../models/app_user_model.dart';

/// Supabase Auth + own profile. Throws; the repository turns throws into
/// Failures.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Deep link registered in AndroidManifest.xml and Info.plist, and listed
  /// under Supabase Auth → Redirect URLs.
  static const mobileRedirect = 'com.ska.namazi://login-callback';

  Stream<String?> get userIdChanges =>
      _client.auth.onAuthStateChange.map((s) => s.session?.user.id);

  Future<AppUserModel?> profile() => pg(() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final rows = await _client
        .from('profiles')
        .select(AppUserModel.columns)
        .eq('id', user.id)
        .limit(1);
    // The handle_new_user trigger creates the row with the auth user, so a
    // missing row means something is wrong server side.
    if (rows.isEmpty) throw NotFoundException('profile ${user.id}');
    return AppUserModel.fromJson(rows.first, email: user.email);
  });

  /// Web: a full-page redirect back to the site root. Mobile: the system
  /// browser, back through [mobileRedirect].
  /// ponytail: browser OAuth on mobile too (no google_sign_in plugin or
  /// per-platform client ids); switch to native sign-in if the browser hop
  /// hurts conversion.
  Future<void> signInWithGoogle() => pg(
    () => _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.resolve('/').toString() : mobileRedirect,
    ),
  );

  /// The Supabase email template must include `{{ .Token }}` (NOTES.md).
  Future<void> sendEmailCode(String email) =>
      pg(() => _client.auth.signInWithOtp(email: email));

  Future<void> verifyEmailCode(String email, String code) => pg(
    () =>
        _client.auth.verifyOTP(type: OtpType.email, email: email, token: code),
  );

  Future<void> signOut() => pg(() => _client.auth.signOut());

  /// Everything we hold about the caller, as pretty-printed JSON.
  Future<String> myData() => pg(() async {
    final data = await _client.rpc<Object?>('my_data');
    return const JsonEncoder.withIndent('  ').convert(data);
  });

  /// Server side (service role) in the delete-account Edge Function, then a
  /// local sign-out: the server already ended the session.
  Future<void> deleteAccount() => pg(() async {
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut(scope: SignOutScope.local);
  });

  Future<void> acceptTerms(String version) =>
      pg(() => _client.rpc<void>('accept_terms', params: {'version': version}));
}
