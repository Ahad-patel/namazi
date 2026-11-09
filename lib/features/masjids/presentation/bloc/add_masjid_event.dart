part of 'add_masjid_bloc.dart';

sealed class AddMasjidEvent extends Equatable {
  const AddMasjidEvent();
  @override
  List<Object?> get props => const [];
}

final class AddMasjidPinDropped extends AddMasjidEvent {
  const AddMasjidPinDropped(this.point);
  final GeoPoint point;
  @override
  List<Object?> get props => [point];
}

final class AddMasjidSubmitted extends AddMasjidEvent {
  const AddMasjidSubmitted(this.masjid);
  final NewMasjid masjid;
  @override
  List<Object?> get props => [masjid];
}
