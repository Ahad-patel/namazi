import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
import '../../domain/entities/suggestion.dart';
import '../models/suggestion_model.dart';

class SuggestionRemoteDataSource {
  SuggestionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<SuggestionModel>> list(String masjidId) => pg(() async {
    final rows = await _client
        .rpc('masjid_suggestions', params: {'masjid_id': masjidId})
        .select(SuggestionModel.columns);
    return [for (final r in rows) SuggestionModel.fromJson(r)];
  });

  Future<List<PrayerWindowModel>> windows(String masjidId) => pg(() async {
    final rows = await _client
        .rpc('prayer_windows', params: {'masjid_id': masjidId})
        .select(PrayerWindowModel.columns);
    return [for (final r in rows) PrayerWindowModel.fromJson(r)];
  });

  Future<void> submit(SuggestionDraft d) => pg(
    () =>
        _client.from('time_suggestions').insert(SuggestionModel.draftToJson(d)),
  );

  Future<void> vote(String suggestionId, int value) => pg(() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw SessionExpiredException('no session');
    if (value == 0) {
      await _client
          .from('suggestion_votes')
          .delete()
          .eq('suggestion_id', suggestionId)
          .eq('user_id', uid);
      return;
    }
    await _client.from('suggestion_votes').upsert({
      'suggestion_id': suggestionId,
      'user_id': uid,
      'value': value,
    }, onConflict: 'suggestion_id,user_id');
  });
}
