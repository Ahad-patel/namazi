import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../location/domain/entities/geo_point.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../domain/entities/nearby_masjid.dart';
import '../../domain/usecases/masjid_usecases.dart';

part 'nearby_event.dart';
part 'nearby_state.dart';

class NearbyBloc extends Bloc<NearbyEvent, NearbyState> {
  NearbyBloc({
    required this._getCurrentLocation,
    required this._searchArea,
    required this._getNearby,
    required this._getNextJamat,
    this.debounce = AppConstants.searchDebounce,
  }) : super(const NearbyState()) {
    // One transformer for every event: a new search, a locate or a retry
    // cancels whatever was still in flight, so a stale answer never lands.
    on<NearbyEvent>(_onEvent, transformer: restartable());
  }

  final GetCurrentLocation _getCurrentLocation;
  final SearchArea _searchArea;
  final GetNearbyMasjids _getNearby;
  final GetNextJamatNearby _getNextJamat;
  final Duration debounce;

  Future<void> _onEvent(NearbyEvent event, Emitter<NearbyState> emit) =>
      switch (event) {
        NearbyLocateRequested() => _locate(emit),
        NearbyAreaQueryChanged(:final query) => _searchQuery(query, emit),
        NearbyWiderRequested() =>
          state.origin == null
              ? Future<void>.value()
              : _load(emit, state.origin!, AppConstants.wideRadiusM),
        NearbyRefreshed() =>
          state.origin == null
              ? _locate(emit)
              : _load(emit, state.origin!, state.radiusM, quiet: true),
      };

  Future<void> _locate(Emitter<NearbyState> emit) async {
    emit(state.copyWith(status: NearbyStatus.locating));
    final result = await _getCurrentLocation(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: failure is LocationFailure
              ? NearbyStatus.needsArea
              : NearbyStatus.error,
          failure: failure,
        ),
      ),
      (point) async {
        emit(state.copyWith(areaLabel: null));
        await _load(emit, point, AppConstants.nearbyRadiusM);
      },
    );
  }

  Future<void> _searchQuery(String query, Emitter<NearbyState> emit) async {
    final q = query.trim();
    if (q.length < 2) return;
    await Future<void>.delayed(debounce);
    // restartable() drops a superseded handler's emits, but its code keeps
    // running; stop here so the stale query never hits the geocoder.
    if (emit.isDone) return;
    emit(state.copyWith(status: NearbyStatus.loading));
    final result = await _searchArea(q);
    await result.fold(
      (failure) async =>
          emit(state.copyWith(status: NearbyStatus.error, failure: failure)),
      (place) async {
        if (place == null) {
          emit(state.copyWith(status: NearbyStatus.areaNotFound, areaQuery: q));
          return;
        }
        emit(state.copyWith(areaLabel: place.label));
        await _load(emit, place.point, AppConstants.nearbyRadiusM);
      },
    );
  }

  /// [quiet] keeps the current list on screen while refreshing.
  Future<void> _load(
    Emitter<NearbyState> emit,
    GeoPoint origin,
    int radiusM, {
    bool quiet = false,
  }) async {
    if (!quiet) emit(state.copyWith(status: NearbyStatus.loading));
    final params = NearbyParams(origin, radiusM);
    final (list, next) = await (_getNearby(params), _getNextJamat(params)).wait;
    final failure =
        list.fold<Failure?>((f) => f, (_) => null) ??
        next.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(status: NearbyStatus.error, failure: failure));
      return;
    }
    final masjids = list.getOrElse(() => const []);
    emit(
      state.copyWith(
        status: masjids.isEmpty ? NearbyStatus.empty : NearbyStatus.loaded,
        origin: origin,
        radiusM: radiusM,
        masjids: masjids,
        next: next.getOrElse(() => null),
      ),
    );
  }
}
