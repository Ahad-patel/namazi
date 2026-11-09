import '../../../masjids/domain/entities/prayer.dart';
import '../../domain/entities/suggestion.dart';

class SuggestionModel extends Suggestion {
  const SuggestionModel({
    required super.id,
    required super.prayer,
    required super.jamat,
    required super.netVotes,
    required super.createdAt,
    super.azaan,
    super.note,
    super.isMine,
    super.myVote,
  });

  static const columns =
      'id,prayer,azaan_time,jamat_time,note,net_votes,created_at,is_mine,my_vote';

  factory SuggestionModel.fromJson(Map<String, dynamic> j) => SuggestionModel(
    id: j['id'] as String,
    prayer: Prayer.values.byName(j['prayer'] as String),
    azaan: j['azaan_time'] == null
        ? null
        : ClockTime.parse(j['azaan_time'] as String),
    jamat: ClockTime.parse(j['jamat_time'] as String),
    note: j['note'] as String?,
    netVotes: (j['net_votes'] as num).toInt(),
    createdAt: DateTime.parse(j['created_at'] as String),
    isMine: j['is_mine'] as bool? ?? false,
    myVote: (j['my_vote'] as num?)?.toInt() ?? 0,
  );

  /// Insert payload for `time_suggestions`. `suggested_by` defaults to
  /// `auth.uid()` server side.
  static Map<String, dynamic> draftToJson(SuggestionDraft d) => {
    'masjid_id': d.masjidId,
    'prayer': d.prayer.name,
    'jamat_time': d.jamat.hhmm,
    'azaan_time': d.azaan?.hhmm,
    'note': (d.note?.trim().isEmpty ?? true) ? null : d.note!.trim(),
  };
}
