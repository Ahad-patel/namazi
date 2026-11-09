import '../../../claims/domain/entities/claim.dart';
import '../../../masjids/domain/entities/prayer.dart';
import '../../domain/entities/admin_items.dart';

ClockTime? _time(Object? v) => v == null ? null : ClockTime.parse(v as String);
DateTime _date(Object? v) => DateTime.parse(v as String);

class ClaimItemModel extends ClaimItem {
  const ClaimItemModel({
    required super.id,
    required super.masjidName,
    required super.masjidSlug,
    required super.role,
    required super.createdAt,
    super.userName,
    super.phone,
    super.proofPath,
    super.reason,
  });

  static const columns =
      'id,masjid_name,masjid_slug,user_name,role_at_masjid,phone,proof_path,'
      'reason,created_at';

  factory ClaimItemModel.fromJson(Map<String, dynamic> j) => ClaimItemModel(
    id: j['id'] as String,
    masjidName: j['masjid_name'] as String,
    masjidSlug: j['masjid_slug'] as String,
    userName: j['user_name'] as String?,
    role: ClaimRole.values.byName(j['role_at_masjid'] as String),
    phone: j['phone'] as String?,
    proofPath: j['proof_path'] as String?,
    reason: j['reason'] as String?,
    createdAt: _date(j['created_at']),
  );
}

class ModerationMasjidModel extends ModerationMasjid {
  const ModerationMasjidModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.lat,
    required super.lng,
    required super.createdAt,
    super.nameLocal,
    super.createdByName,
  });

  static const columns =
      'id,slug,name,name_local,latitude,longitude,created_by_name,created_at';

  factory ModerationMasjidModel.fromJson(Map<String, dynamic> j) =>
      ModerationMasjidModel(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        nameLocal: j['name_local'] as String?,
        lat: (j['latitude'] as num).toDouble(),
        lng: (j['longitude'] as num).toDouble(),
        createdByName: j['created_by_name'] as String?,
        createdAt: _date(j['created_at']),
      );
}

class SuggestionItemModel extends SuggestionItem {
  const SuggestionItemModel({
    required super.id,
    required super.masjidName,
    required super.prayer,
    required super.jamat,
    required super.createdAt,
    super.note,
    super.netVotes,
    super.authorName,
  });

  static const openColumns =
      'id,masjid_name,prayer,jamat_time,note,net_votes,author_name,created_at';
  static const hiddenColumns =
      'id,masjid_name,prayer,jamat_time,note,created_at';

  factory SuggestionItemModel.fromJson(Map<String, dynamic> j) =>
      SuggestionItemModel(
        id: j['id'] as String,
        masjidName: j['masjid_name'] as String,
        prayer: Prayer.values.byName(j['prayer'] as String),
        jamat: ClockTime.parse(j['jamat_time'] as String),
        note: j['note'] as String?,
        netVotes: j['net_votes'] as int?,
        authorName: j['author_name'] as String?,
        createdAt: _date(j['created_at']),
      );
}

class BannedUserModel extends BannedUser {
  const BannedUserModel({required super.id, super.displayName});

  static const columns = 'id,display_name';

  factory BannedUserModel.fromJson(Map<String, dynamic> j) => BannedUserModel(
    id: j['id'] as String,
    displayName: j['display_name'] as String?,
  );
}

class LogEntryModel extends LogEntry {
  const LogEntryModel({
    required super.id,
    required super.action,
    required super.targetTable,
    required super.createdAt,
    super.reason,
  });

  static const columns = 'id,action,target_table,reason,created_at';

  factory LogEntryModel.fromJson(Map<String, dynamic> j) => LogEntryModel(
    id: j['id'] as int,
    action: j['action'] as String,
    targetTable: j['target_table'] as String,
    reason: j['reason'] as String?,
    createdAt: _date(j['created_at']),
  );
}

class InboxItemModel extends InboxItem {
  const InboxItemModel({
    required super.id,
    required super.prayer,
    required super.jamat,
    required super.netVotes,
    required super.createdAt,
    super.azaan,
    super.note,
    super.verifiedJamat,
  });

  static const columns =
      'id,prayer,azaan_time,jamat_time,note,net_votes,created_at,'
      'verified_jamat_time';

  factory InboxItemModel.fromJson(Map<String, dynamic> j) => InboxItemModel(
    id: j['id'] as String,
    prayer: Prayer.values.byName(j['prayer'] as String),
    jamat: ClockTime.parse(j['jamat_time'] as String),
    azaan: _time(j['azaan_time']),
    note: j['note'] as String?,
    netVotes: j['net_votes'] as int,
    createdAt: _date(j['created_at']),
    verifiedJamat: _time(j['verified_jamat_time']),
  );
}

class SuggestionAuthorModel extends SuggestionAuthor {
  const SuggestionAuthorModel({
    required super.openCount,
    required super.isBanned,
    super.displayName,
  });

  static const columns = 'display_name,open_count,is_banned';

  factory SuggestionAuthorModel.fromJson(Map<String, dynamic> j) =>
      SuggestionAuthorModel(
        displayName: j['display_name'] as String?,
        openCount: j['open_count'] as int,
        isBanned: j['is_banned'] as bool,
      );
}

/// `yyyy-mm-dd`, the form Postgres `date` accepts.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
