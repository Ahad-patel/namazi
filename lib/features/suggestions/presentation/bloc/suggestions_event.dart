part of 'suggestions_bloc.dart';

sealed class SuggestionsEvent extends Equatable {
  const SuggestionsEvent();
  @override
  List<Object?> get props => const [];
}

/// Load for [masjidId], or reload the current masjid when null.
final class SuggestionsRequested extends SuggestionsEvent {
  const SuggestionsRequested([this.masjidId]);
  final String? masjidId;
  @override
  List<Object?> get props => [masjidId];
}

final class SuggestionSubmitted extends SuggestionsEvent {
  const SuggestionSubmitted(this.draft);
  final SuggestionDraft draft;
  @override
  List<Object?> get props => [draft];
}

/// [value] -1 / 1, or 0 to take the vote back.
final class SuggestionVoted extends SuggestionsEvent {
  const SuggestionVoted(this.suggestionId, this.value);
  final String suggestionId;
  final int value;
  @override
  List<Object?> get props => [suggestionId, value];
}

/// The suggest sheet opened: forget the last submit result.
final class SuggestionFormOpened extends SuggestionsEvent {
  const SuggestionFormOpened();
}
