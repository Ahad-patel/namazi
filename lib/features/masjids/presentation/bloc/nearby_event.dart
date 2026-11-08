part of 'nearby_bloc.dart';

sealed class NearbyEvent extends Equatable {
  const NearbyEvent();
  @override
  List<Object?> get props => const [];
}

/// Ask for the device location and load masjids around it.
final class NearbyLocateRequested extends NearbyEvent {
  const NearbyLocateRequested();
}

/// The user typed in the area search (debounced inside the bloc).
final class NearbyAreaQueryChanged extends NearbyEvent {
  const NearbyAreaQueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

/// "Search a wider area" from the empty state.
final class NearbyWiderRequested extends NearbyEvent {
  const NearbyWiderRequested();
}

/// Retry, or the banner's jamat time just passed.
final class NearbyRefreshed extends NearbyEvent {
  const NearbyRefreshed();
}
