import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/usecases/suggestion_usecases.dart';

part 'suggestions_event.dart';
part 'suggestions_state.dart';

/// Community suggestions of one masjid: list, submit, vote. Votes are
/// optimistic and roll back with [SuggestionsState.voteFailure] on error.
class SuggestionsBloc extends Bloc<SuggestionsEvent, SuggestionsState> {
  SuggestionsBloc({
    required this._getSuggestions,
    required this._submit,
    required this._vote,
  }) : super(const SuggestionsState()) {
    on<SuggestionsRequested>(_onRequested, transformer: restartable());
    on<SuggestionSubmitted>(_onSubmitted, transformer: droppable());
    on<SuggestionVoted>(_onVoted, transformer: sequential());
    on<SuggestionFormOpened>(
      (_, emit) => emit(state.copyWith(submitStatus: SubmitStatus.idle)),
    );
  }

  final GetSuggestions _getSuggestions;
  final SubmitSuggestion _submit;
  final VoteOnSuggestion _vote;

  Future<void> _onRequested(
    SuggestionsRequested event,
    Emitter<SuggestionsState> emit,
  ) async {
    final id = event.masjidId ?? state.masjidId;
    if (id == null) return;
    if (event.masjidId != null || state.status != SuggestionsStatus.loaded) {
      emit(state.copyWith(status: SuggestionsStatus.loading, masjidId: id));
    }
    await _load(id, emit);
  }

  Future<void> _load(String id, Emitter<SuggestionsState> emit) async {
    final result = await _getSuggestions(id);
    result.fold(
      (f) => emit(state.copyWith(status: SuggestionsStatus.error, failure: f)),
      (items) => emit(
        state.copyWith(
          status: items.isEmpty
              ? SuggestionsStatus.empty
              : SuggestionsStatus.loaded,
          items: items,
        ),
      ),
    );
  }

  Future<void> _onSubmitted(
    SuggestionSubmitted event,
    Emitter<SuggestionsState> emit,
  ) async {
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _submit(event.draft);
    await result.fold(
      (f) async => emit(
        state.copyWith(submitStatus: SubmitStatus.failure, submitFailure: f),
      ),
      (_) async {
        emit(
          state.copyWith(
            submitStatus: SubmitStatus.success,
            changes: state.changes + 1,
          ),
        );
        await _load(event.draft.masjidId, emit);
      },
    );
  }

  Future<void> _onVoted(
    SuggestionVoted event,
    Emitter<SuggestionsState> emit,
  ) async {
    final before = state.items;
    emit(
      state.copyWith(
        items: [
          for (final s in before)
            s.id == event.suggestionId ? s.withVote(event.value) : s,
        ],
        clearVoteFailure: true,
      ),
    );
    final result = await _vote(VoteParams(event.suggestionId, event.value));
    result.fold(
      (f) => emit(state.copyWith(items: before, voteFailure: f)),
      (_) => emit(state.copyWith(changes: state.changes + 1)),
    );
  }
}
