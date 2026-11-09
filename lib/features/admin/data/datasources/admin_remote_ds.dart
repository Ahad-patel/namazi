import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/postgrest_guard.dart';
import '../../domain/entities/admin_queue.dart';
import '../models/admin_models.dart';

/// Every admin read and write. Writes are one-id RPCs that check the role
/// server side; the client never updates these tables directly.
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const proofBucket = 'claim-proofs';

  Future<List<Map<String, dynamic>>> _rpc(
    String fn,
    String columns,
    int page, [
    Map<String, dynamic>? params,
  ]) {
    const size = AppConstants.pageSize;
    return _client
        .rpc(fn, params: params)
        .select(columns)
        .range(page * size, page * size + size - 1);
  }

  /// One page of [queue], as the matching model type.
  Future<List<Object>> load(AdminQueue<dynamic> queue, int page) =>
      pg(() async {
        const size = AppConstants.pageSize;
        switch (queue) {
          case ClaimsQueue(:final status):
            final rows = await _rpc(
              'claims_by_status',
              ClaimItemModel.columns,
              page,
              {'p_status': status.name},
            );
            return [for (final r in rows) ClaimItemModel.fromJson(r)];
          case MasjidsQueue(:final status, :final query):
            final q = query?.trim();
            final rows = await _rpc(
              'masjids_by_status',
              ModerationMasjidModel.columns,
              page,
              {
                'p_status': status.name,
                'p_query': q == null || q.isEmpty ? null : q,
              },
            );
            return [for (final r in rows) ModerationMasjidModel.fromJson(r)];
          case OpenSuggestionsQueue():
            final rows = await _rpc(
              'open_suggestions',
              SuggestionItemModel.openColumns,
              page,
            );
            return [for (final r in rows) SuggestionItemModel.fromJson(r)];
          case HiddenSuggestionsQueue():
            final rows = await _rpc(
              'hidden_suggestions',
              SuggestionItemModel.hiddenColumns,
              page,
            );
            return [for (final r in rows) SuggestionItemModel.fromJson(r)];
          case BannedUsersQueue():
            final rows = await _rpc(
              'banned_users',
              BannedUserModel.columns,
              page,
            );
            return [for (final r in rows) BannedUserModel.fromJson(r)];
          case ModerationLogQueue():
            final rows = await _client
                .from('moderation_log')
                .select(LogEntryModel.columns)
                .order('created_at', ascending: false)
                .range(page * size, page * size + size - 1);
            return [for (final r in rows) LogEntryModel.fromJson(r)];
          case InboxQueue(:final masjidId):
            final rows = await _rpc(
              'admin_inbox',
              InboxItemModel.columns,
              page,
              {'masjid_id': masjidId},
            );
            return [for (final r in rows) InboxItemModel.fromJson(r)];
        }
      });

  Future<void> perform(AdminAction a) => pg(() async {
    final (fn, params) = switch (a) {
      ReviewClaim() => (
        'review_claim',
        {'claim_id': a.claimId, 'approve': a.approve, 'reason': a.reason},
      ),
      RevokeAdmin() => (
        'revoke_admin',
        {'claim_id': a.claimId, 'reason': a.reason},
      ),
      SetMasjidStatus() => (
        'set_masjid_status',
        {'masjid_id': a.masjidId, 'status': a.status.name, 'reason': a.reason},
      ),
      HideSuggestion() => (
        'hide_suggestion',
        {'suggestion_id': a.suggestionId, 'reason': a.reason},
      ),
      RestoreSuggestion() => (
        'restore_suggestion',
        {'suggestion_id': a.suggestionId},
      ),
      BanAuthor() => (
        'ban_suggestion_author',
        {'suggestion_id': a.suggestionId, 'reason': a.reason},
      ),
      UnbanUser() => ('unban_user', {'user_id': a.userId, 'reason': a.reason}),
      AcceptSuggestion() => (
        'accept_suggestion',
        {'suggestion_id': a.suggestionId},
      ),
      RejectSuggestion() => (
        'reject_suggestion',
        {'suggestion_id': a.suggestionId, 'reason': a.reason},
      ),
      SetJamatTime() => (
        'set_jamat_time',
        {
          'masjid_id': a.masjidId,
          'prayer': a.prayer.name,
          'jamat_time': a.jamat.hhmm,
          'azaan_time': a.azaan?.hhmm,
          'valid_from': a.validFrom == null ? null : isoDate(a.validFrom!),
        },
      ),
    };
    await _client.rpc<void>(fn, params: params);
  });

  Future<SuggestionAuthorModel> suggestionAuthor(String suggestionId) =>
      pg(() async {
        final rows = await _client
            .rpc('suggestion_author', params: {'suggestion_id': suggestionId})
            .select(SuggestionAuthorModel.columns)
            .limit(1);
        if (rows.isEmpty) throw NotFoundException('author not found');
        return SuggestionAuthorModel.fromJson(rows.first);
      });

  /// Short-lived (AppConstants.proofUrlTtlSeconds), made only when the super
  /// admin opens the photo.
  Future<String> proofUrl(String path) => pg(
    () => _client.storage
        .from(proofBucket)
        .createSignedUrl(path, AppConstants.proofUrlTtlSeconds),
  );
}
