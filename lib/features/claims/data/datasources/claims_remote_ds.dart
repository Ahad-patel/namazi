import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
import '../../domain/entities/claim.dart';
import '../models/claim_models.dart';

class ClaimsRemoteDataSource {
  ClaimsRemoteDataSource(this._client, {Random? random})
    : _random = random ?? Random.secure();

  final SupabaseClient _client;
  final Random _random;

  static const bucket = 'claim-proofs';

  Future<MasjidAccessModel> access(String masjidId) => pg(() async {
    final rows = await _client
        .rpc('masjid_access', params: {'masjid_id': masjidId})
        .select(MasjidAccessModel.columns)
        .limit(1);
    return rows.isEmpty
        ? const MasjidAccessModel(canManage: false)
        : MasjidAccessModel.fromJson(rows.first);
  });

  /// The claim id is made here so the photo path can carry it
  /// (`<user_id>/<claim_id>.jpg`, write-once: a new claim is a new path).
  Future<void> submit(ClaimDraft d) => pg(() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw SessionExpiredException('no session');
    final id = uuidV4(_random);
    String? path;
    final photo = d.photo;
    if (photo != null) {
      path = '$uid/$id.jpg';
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            photo,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }
    await _client.from('masjid_admins').insert({
      'id': id,
      'masjid_id': d.masjidId,
      'role_at_masjid': d.role.name,
      'phone': normalisePhone(d.phone),
      'proof_path': path,
    });
  });
}

/// RFC 4122 v4 from 16 random bytes (no uuid package for one call site).
String uuidV4(Random r) {
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
