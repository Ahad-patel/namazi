part of 'add_masjid_bloc.dart';

/// editing = form open (empty), submitting = loading, success = loaded
/// (sent for review), error.
enum AddMasjidStatus { editing, submitting, success, error }

class AddMasjidState extends Equatable {
  const AddMasjidState({
    this.status = AddMasjidStatus.editing,
    this.pin,
    this.failure,
  });

  final AddMasjidStatus status;

  /// Where the user dropped the pin; null until they tap the map.
  final GeoPoint? pin;
  final Failure? failure;

  AddMasjidState copyWith({
    AddMasjidStatus? status,
    GeoPoint? pin,
    Failure? failure,
  }) => AddMasjidState(
    status: status ?? this.status,
    pin: pin ?? this.pin,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, pin, failure];
}
