import 'package:equatable/equatable.dart';

import '../../../claims/domain/entities/claim.dart';
import '../../../masjids/domain/entities/prayer.dart';
import 'admin_items.dart';

/// Every paged list an admin screen shows. [T] is the row type.
sealed class AdminQueue<T> extends Equatable {
  const AdminQueue();
  @override
  List<Object?> get props => const [];
}

/// pending = review queue, approved = current admins (revoke).
final class ClaimsQueue extends AdminQueue<ClaimItem> {
  const ClaimsQueue(this.status);
  final ClaimStatus status;
  @override
  List<Object?> get props => [status];
}

enum MasjidModeration { pending, active, hidden }

final class MasjidsQueue extends AdminQueue<ModerationMasjid> {
  const MasjidsQueue(this.status, {this.query});
  final MasjidModeration status;
  final String? query;
  @override
  List<Object?> get props => [status, query];
}

final class OpenSuggestionsQueue extends AdminQueue<SuggestionItem> {
  const OpenSuggestionsQueue();
}

final class HiddenSuggestionsQueue extends AdminQueue<SuggestionItem> {
  const HiddenSuggestionsQueue();
}

final class BannedUsersQueue extends AdminQueue<BannedUser> {
  const BannedUsersQueue();
}

final class ModerationLogQueue extends AdminQueue<LogEntry> {
  const ModerationLogQueue();
}

final class InboxQueue extends AdminQueue<InboxItem> {
  const InboxQueue(this.masjidId);
  final String masjidId;
  @override
  List<Object?> get props => [masjidId];
}

/// Every admin write. Each acts on exactly one id (CHECKLISTS §1).
sealed class AdminAction extends Equatable {
  const AdminAction();
}

final class ReviewClaim extends AdminAction {
  const ReviewClaim(this.claimId, {required this.approve, this.reason});
  final String claimId;
  final bool approve;
  final String? reason;
  @override
  List<Object?> get props => [claimId, approve, reason];
}

final class RevokeAdmin extends AdminAction {
  const RevokeAdmin(this.claimId, {this.reason});
  final String claimId;
  final String? reason;
  @override
  List<Object?> get props => [claimId, reason];
}

final class SetMasjidStatus extends AdminAction {
  const SetMasjidStatus(this.masjidId, this.status, {this.reason});
  final String masjidId;

  /// active or hidden (the server checks the move is allowed).
  final MasjidModeration status;
  final String? reason;
  @override
  List<Object?> get props => [masjidId, status, reason];
}

final class HideSuggestion extends AdminAction {
  const HideSuggestion(this.suggestionId, {this.reason});
  final String suggestionId;
  final String? reason;
  @override
  List<Object?> get props => [suggestionId, reason];
}

final class RestoreSuggestion extends AdminAction {
  const RestoreSuggestion(this.suggestionId);
  final String suggestionId;
  @override
  List<Object?> get props => [suggestionId];
}

/// Bans the author and hides their open suggestions (server caps at 50).
final class BanAuthor extends AdminAction {
  const BanAuthor(this.suggestionId, {this.reason});
  final String suggestionId;
  final String? reason;
  @override
  List<Object?> get props => [suggestionId, reason];
}

final class UnbanUser extends AdminAction {
  const UnbanUser(this.userId, {this.reason});
  final String userId;
  final String? reason;
  @override
  List<Object?> get props => [userId, reason];
}

final class AcceptSuggestion extends AdminAction {
  const AcceptSuggestion(this.suggestionId);
  final String suggestionId;
  @override
  List<Object?> get props => [suggestionId];
}

final class RejectSuggestion extends AdminAction {
  const RejectSuggestion(this.suggestionId, {this.reason});
  final String suggestionId;
  final String? reason;
  @override
  List<Object?> get props => [suggestionId, reason];
}

/// Verified time for one namaz from [validFrom] (null = masjid's today).
final class SetJamatTime extends AdminAction {
  const SetJamatTime({
    required this.masjidId,
    required this.prayer,
    required this.jamat,
    this.azaan,
    this.validFrom,
  });
  final String masjidId;
  final Prayer prayer;
  final ClockTime jamat;
  final ClockTime? azaan;
  final DateTime? validFrom;
  @override
  List<Object?> get props => [masjidId, prayer, jamat, azaan, validFrom];
}
