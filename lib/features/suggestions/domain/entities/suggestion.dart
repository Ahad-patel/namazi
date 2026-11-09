import 'package:equatable/equatable.dart';

import '../../../masjids/domain/entities/prayer.dart';

/// One open community suggestion, as `masjid_suggestions` returns it.
class Suggestion extends Equatable {
  const Suggestion({
    required this.id,
    required this.prayer,
    required this.jamat,
    required this.netVotes,
    required this.createdAt,
    this.azaan,
    this.note,
    this.isMine = false,
    this.myVote = 0,
  });

  final String id;
  final Prayer prayer;
  final ClockTime? azaan;
  final ClockTime jamat;
  final String? note;
  final int netVotes;
  final DateTime createdAt;
  final bool isMine;

  /// -1, 0 (no vote) or 1.
  final int myVote;

  /// Local copy with the caller's vote changed (optimistic UI).
  Suggestion withVote(int vote) => Suggestion(
    id: id,
    prayer: prayer,
    azaan: azaan,
    jamat: jamat,
    note: note,
    netVotes: netVotes - myVote + vote,
    createdAt: createdAt,
    isMine: isMine,
    myVote: vote,
  );

  @override
  List<Object?> get props => [
    id,
    prayer,
    azaan,
    jamat,
    note,
    netVotes,
    createdAt,
    isMine,
    myVote,
  ];
}

class SuggestionDraft extends Equatable {
  const SuggestionDraft({
    required this.masjidId,
    required this.prayer,
    required this.jamat,
    this.azaan,
    this.note,
  });

  final String masjidId;
  final Prayer prayer;
  final ClockTime jamat;
  final ClockTime? azaan;
  final String? note;

  @override
  List<Object?> get props => [masjidId, prayer, jamat, azaan, note];
}
