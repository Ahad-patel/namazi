part of 'suggestions_bloc.dart';

enum SuggestionsStatus { initial, loading, loaded, empty, error }

enum SubmitStatus { idle, submitting, success, failure }

class SuggestionsState extends Equatable {
  const SuggestionsState({
    this.status = SuggestionsStatus.initial,
    this.masjidId,
    this.items = const [],
    this.failure,
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
    this.voteFailure,
    this.changes = 0,
    this.windows = const [],
  });

  final SuggestionsStatus status;
  final String? masjidId;
  final List<Suggestion> items;
  final Failure? failure;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  /// Set when a vote was rolled back; cleared by the next vote.
  final Failure? voteFailure;

  /// Bumped after every accepted write, so the detail page refetches
  /// `masjid_times` (a vote can change what is displayed).
  final int changes;

  /// Today's allowed time per namaz (empty until the sheet first opens).
  final List<PrayerWindow> windows;

  PrayerWindow? windowFor(Prayer p) {
    for (final w in windows) {
      if (w.prayer == p) return w;
    }
    return null;
  }

  SuggestionsState copyWith({
    SuggestionsStatus? status,
    String? masjidId,
    List<Suggestion>? items,
    Failure? failure,
    SubmitStatus? submitStatus,
    Failure? submitFailure,
    Failure? voteFailure,
    bool clearVoteFailure = false,
    int? changes,
    List<PrayerWindow>? windows,
  }) => SuggestionsState(
    status: status ?? this.status,
    masjidId: masjidId ?? this.masjidId,
    items: items ?? this.items,
    failure: failure ?? this.failure,
    submitStatus: submitStatus ?? this.submitStatus,
    submitFailure: submitFailure ?? this.submitFailure,
    voteFailure: clearVoteFailure ? null : voteFailure ?? this.voteFailure,
    changes: changes ?? this.changes,
    windows: windows ?? this.windows,
  );

  @override
  List<Object?> get props => [
    status,
    masjidId,
    items,
    failure,
    submitStatus,
    submitFailure,
    voteFailure,
    changes,
    windows,
  ];
}
