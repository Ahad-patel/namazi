part of 'claims_bloc.dart';

sealed class ClaimsEvent extends Equatable {
  const ClaimsEvent();
  @override
  List<Object?> get props => const [];
}

/// Load access for [masjidId]; null = signed out (no access, no claim).
final class ClaimsAccessRequested extends ClaimsEvent {
  const ClaimsAccessRequested(this.masjidId);
  final String? masjidId;
  @override
  List<Object?> get props => [masjidId];
}

final class ClaimSubmitted extends ClaimsEvent {
  const ClaimSubmitted(this.draft);
  final ClaimDraft draft;
  @override
  List<Object?> get props => [draft];
}
