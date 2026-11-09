import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/claims_usecases.dart';

part 'claims_event.dart';
part 'claims_state.dart';

/// The caller's access to one masjid (detail page), and the claim form.
class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  ClaimsBloc({required this._getAccess, required this._submit})
    : super(const ClaimsState()) {
    on<ClaimsAccessRequested>(_onAccess, transformer: restartable());
    on<ClaimSubmitted>(_onSubmit, transformer: droppable());
  }

  final GetMasjidAccess _getAccess;
  final SubmitClaim _submit;

  Future<void> _onAccess(
    ClaimsAccessRequested event,
    Emitter<ClaimsState> emit,
  ) async {
    final id = event.masjidId;
    if (id == null) {
      return emit(
        const ClaimsState(
          status: AccessStatus.loaded,
          access: MasjidAccess.none,
        ),
      );
    }
    emit(state.copyWith(status: AccessStatus.loading));
    final result = await _getAccess(id);
    result.fold(
      (f) => emit(state.copyWith(status: AccessStatus.error, failure: f)),
      (a) => emit(state.copyWith(status: AccessStatus.loaded, access: a)),
    );
  }

  Future<void> _onSubmit(
    ClaimSubmitted event,
    Emitter<ClaimsState> emit,
  ) async {
    emit(state.copyWith(submitStatus: ClaimSubmitStatus.submitting));
    final result = await _submit(event.draft);
    result.fold(
      (f) => emit(
        state.copyWith(
          submitStatus: ClaimSubmitStatus.failure,
          submitFailure: f,
        ),
      ),
      (_) => emit(
        state.copyWith(
          submitStatus: ClaimSubmitStatus.success,
          access: const MasjidAccess(
            canManage: false,
            claimStatus: ClaimStatus.pending,
          ),
        ),
      ),
    );
  }
}
