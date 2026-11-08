import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
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
    final row = await _client
        .rpc(
          'next_jamat_nearby',
          params: {'lat': lat, 'lng': lng, 'radius_m': radiusM},
        )
        .select(NearbyMasjidModel.columns)
        .maybeSingle();
    return row == null ? null : NearbyMasjidModel.fromJson(row);
  });

  Future<MasjidModel> bySlug(String slug) => pg(() async {
    final row = await _client
        .rpc('masjid_by_slug', params: {'masjid_slug': slug})
        .select(MasjidModel.columns)
        .maybeSingle();
    if (row == null) throw NotFoundException('masjid $slug');
    return MasjidModel.fromJson(row);
  });

  Future<List<PrayerTimeModel>> times(String masjidId) => pg(() async {
    final rows = await _client
        .rpc('masjid_times', params: {'masjid_id': masjidId})
        .select(PrayerTimeModel.columns);
    return [for (final r in rows) PrayerTimeModel.fromJson(r)];
  });
}
