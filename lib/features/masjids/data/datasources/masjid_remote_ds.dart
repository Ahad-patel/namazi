import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
import '../../domain/entities/new_masjid.dart';
import '../models/masjid_models.dart';

/// Supabase RPC calls. Throws; the repository turns throws into Failures.
class MasjidRemoteDataSource {
  MasjidRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<NearbyMasjidModel>> nearby(double lat, double lng, int radiusM) =>
      pg(() async {
        final rows = await _client
            .rpc(
              'nearby_masjids',
              params: {'lat': lat, 'lng': lng, 'radius_m': radiusM},
            )
            .select(NearbyMasjidModel.columns);
        return [for (final r in rows) NearbyMasjidModel.fromJson(r)];
      });

  Future<NearbyMasjidModel?> nextJamatNearby(
    double lat,
    double lng,
    int radiusM,
  ) => pg(() async {
    // Not maybeSingle(): on an RPC, 0 rows comes back as a 406 (PGRST116)
    // instead of null. An empty radius is normal, so read a list.
    final rows = await _client
        .rpc(
          'next_jamat_nearby',
          params: {'lat': lat, 'lng': lng, 'radius_m': radiusM},
        )
        .select(NearbyMasjidModel.columns)
        .limit(1);
    return rows.isEmpty ? null : NearbyMasjidModel.fromJson(rows.first);
  });

  Future<MasjidModel> bySlug(String slug) => pg(() async {
    final rows = await _client
        .rpc('masjid_by_slug', params: {'masjid_slug': slug})
        .select(MasjidModel.columns)
        .limit(1);
    if (rows.isEmpty) throw NotFoundException('masjid $slug');
    return MasjidModel.fromJson(rows.first);
  });

  Future<List<PrayerTimeModel>> times(String masjidId) => pg(() async {
    final rows = await _client
        .rpc('masjid_times', params: {'masjid_id': masjidId})
        .select(PrayerTimeModel.columns);
    return [for (final r in rows) PrayerTimeModel.fromJson(r)];
  });

  /// `add_masjid` builds the slug and geography server side.
  Future<String> add(NewMasjid m) => pg(() async {
    final local = m.nameLocal?.trim();
    final id = await _client.rpc<String>(
      'add_masjid',
      params: {
        'name': m.name.trim(),
        'lat': m.location.lat,
        'lng': m.location.lng,
        'name_local': (local == null || local.isEmpty) ? null : local,
        'name_script': (local == null || local.isEmpty)
            ? null
            : m.nameScript?.name,
      },
    );
    return id;
  });
}
