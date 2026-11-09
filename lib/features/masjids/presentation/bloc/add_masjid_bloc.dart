import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../../domain/entities/new_masjid.dart';
import '../../domain/usecases/masjid_usecases.dart';

part 'add_masjid_event.dart';
part 'add_masjid_state.dart';

class AddMasjidBloc extends Bloc<AddMasjidEvent, AddMasjidState> {
  AddMasjidBloc({required this._add}) : super(const AddMasjidState()) {
    on<AddMasjidPinDropped>(
      (e, emit) =>
          emit(state.copyWith(pin: e.point, status: AddMasjidStatus.editing)),
    );
    on<AddMasjidSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AddMasjid _add;

  Future<void> _onSubmitted(
    AddMasjidSubmitted event,
    Emitter<AddMasjidState> emit,
  ) async {
    emit(state.copyWith(status: AddMasjidStatus.submitting));
    final result = await _add(event.masjid);
    result.fold(
      (f) => emit(state.copyWith(status: AddMasjidStatus.error, failure: f)),
      (_) => emit(state.copyWith(status: AddMasjidStatus.success)),
    );
  }
}
