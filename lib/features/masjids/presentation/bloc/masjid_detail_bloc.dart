import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/masjid.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/usecases/masjid_usecases.dart';

part 'masjid_detail_event.dart';
part 'masjid_detail_state.dart';

class MasjidDetailBloc extends Bloc<MasjidDetailEvent, MasjidDetailState> {
  MasjidDetailBloc({required this._getBySlug, required this._getTimes})
    : super(const MasjidDetailState()) {
    on<MasjidDetailRequested>(_onRequested);
    on<MasjidDetailRefreshed>(_onRefreshed);
  }

  final GetMasjidBySlug _getBySlug;
  final GetMasjidTimes _getTimes;
  String? _slug;

  /// [MasjidDetailRequested.known] is the masjid passed from the nearby list,
  /// so only the times are fetched. A shared link has only the slug.
  Future<void> _onRequested(
    MasjidDetailRequested event,
    Emitter<MasjidDetailState> emit,
  ) async {
    _slug = event.slug;
    emit(
      state.copyWith(status: MasjidDetailStatus.loading, masjid: event.known),
    );
    final known = event.known;
    if (known != null) return _loadTimes(known, emit, refresh: false);
    await _loadBySlug(event.slug, emit);
  }

  Future<void> _loadBySlug(String slug, Emitter<MasjidDetailState> emit) async {
    final result = await _getBySlug(slug);
    await result.fold(
      (f) async =>
          emit(state.copyWith(status: MasjidDetailStatus.error, failure: f)),
      (m) => _loadTimes(m, emit, refresh: false),
    );
  }

  Future<void> _onRefreshed(
    MasjidDetailRefreshed event,
    Emitter<MasjidDetailState> emit,
  ) async {
    final m = state.masjid;
    if (m != null) return _loadTimes(m, emit, refresh: true);
    final slug = _slug;
    if (slug == null) return;
    emit(state.copyWith(status: MasjidDetailStatus.loading));
    await _loadBySlug(slug, emit);
  }

  Future<void> _loadTimes(
    Masjid masjid,
    Emitter<MasjidDetailState> emit, {
    required bool refresh,
  }) async {
    final result = await _getTimes(TimesParams(masjid.id, refresh: refresh));
    result.fold(
      (f) => emit(
        state.copyWith(
          status: MasjidDetailStatus.error,
          masjid: masjid,
          failure: f,
        ),
      ),
      (times) => emit(
        state.copyWith(
          status: times.isEmpty
              ? MasjidDetailStatus.empty
              : MasjidDetailStatus.loaded,
          masjid: masjid,
          times: times,
        ),
      ),
    );
  }
}
