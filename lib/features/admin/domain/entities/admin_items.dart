import 'package:equatable/equatable.dart';

import '../../../claims/domain/entities/claim.dart';
import '../../../masjids/domain/entities/prayer.dart';

/// A claim in the review queue (pending) or the admins list (approved).
class ClaimItem extends Equatable {
  const ClaimItem({
    required this.id,
    required this.masjidName,
    required this.masjidSlug,
    required this.role,
    required this.createdAt,
    this.userName,
    this.phone,
    this.proofPath,
    this.reason,
  });

  final String id;
  final String masjidName;
  final String masjidSlug;
  final ClaimRole role;
  final DateTime createdAt;
  final String? userName;

  /// Null once purged (90 days after the decision).
  final String? phone;
  final String? proofPath;
  final String? reason;

  @override
  List<Object?> get props => [id, masjidName, role, userName, phone, proofPath];
}

class ModerationMasjid extends Equatable {
  const ModerationMasjid({
    required this.id,
    required this.slug,
    required this.name,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.nameLocal,
    this.createdByName,
  });

  final String id;
  final String slug;
  final String name;
  final String? nameLocal;
  final double lat;
  final double lng;
  final String? createdByName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, nameLocal, lat, lng, createdByName];
}

/// Open (to hide / ban the author) or hidden (to restore).
class SuggestionItem extends Equatable {
  const SuggestionItem({
    required this.id,
    required this.masjidName,
    required this.prayer,
    required this.jamat,
    required this.createdAt,
    this.note,
    this.netVotes,
    this.authorName,
  });

  final String id;
  final String masjidName;
  final Prayer prayer;
  final ClockTime jamat;
  final DateTime createdAt;
  final String? note;
  final int? netVotes;
  final String? authorName;

  @override
  List<Object?> get props => [id, masjidName, prayer, jamat, note, netVotes];
}

class BannedUser extends Equatable {
  const BannedUser({required this.id, this.displayName});
  final String id;
  final String? displayName;
  @override
  List<Object?> get props => [id, displayName];
}

class LogEntry extends Equatable {
  const LogEntry({
    required this.id,
    required this.action,
    required this.targetTable,
    required this.createdAt,
    this.reason,
  });

  final int id;
  final String action;
  final String targetTable;
  final DateTime createdAt;
  final String? reason;

  @override
  List<Object?> get props => [id, action, targetTable, reason];
}

/// Admin inbox: an open suggestion that differs from the verified time.
class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.prayer,
    required this.jamat,
    required this.netVotes,
    required this.createdAt,
    this.azaan,
    this.note,
    this.verifiedJamat,
  });

  final String id;
  final Prayer prayer;
  final ClockTime jamat;
  final ClockTime? azaan;
  final String? note;
  final int netVotes;
  final DateTime createdAt;
  final ClockTime? verifiedJamat;

  @override
  List<Object?> get props => [id, prayer, jamat, azaan, note, netVotes];
}

/// Ban preview.
class SuggestionAuthor extends Equatable {
  const SuggestionAuthor({
    required this.openCount,
    required this.isBanned,
    this.displayName,
  });

  final String? displayName;
  final int openCount;
  final bool isBanned;

  @override
  List<Object?> get props => [displayName, openCount, isBanned];
}
