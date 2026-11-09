import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_items.dart';
import '../../domain/usecases/admin_usecases.dart';

/// One-shot lookups behind a dialog: a proof photo's signed URL, or the ban
/// preview of a suggestion's author. Cubit: trivial state, one call each.
class AdminLookupCubit extends Cubit<AdminLookupState> {
  AdminLookupCubit({required this._proofUrl, required this._author})
    : super(const AdminLookupLoading());

  final GetProofUrl _proofUrl;
  final GetSuggestionAuthor _author;

  Future<void> proof(String path) async {
    emit(const AdminLookupLoading());
    final r = await _proofUrl(path);
    if (isClosed) return;
    emit(r.fold(AdminLookupError.new, ProofLoaded.new));
  }

  Future<void> author(String suggestionId) async {
    emit(const AdminLookupLoading());
    final r = await _author(suggestionId);
    if (isClosed) return;
    emit(r.fold(AdminLookupError.new, AuthorLoaded.new));
  }
}

sealed class AdminLookupState extends Equatable {
  const AdminLookupState();
  @override
  List<Object?> get props => const [];
}

final class AdminLookupLoading extends AdminLookupState {
  const AdminLookupLoading();
}

final class ProofLoaded extends AdminLookupState {
  const ProofLoaded(this.url);
  final String url;
  @override
  List<Object?> get props => [url];
}

final class AuthorLoaded extends AdminLookupState {
  const AuthorLoaded(this.author);
  final SuggestionAuthor author;
  @override
  List<Object?> get props => [author];
}

final class AdminLookupError extends AdminLookupState {
  const AdminLookupError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
