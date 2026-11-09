import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}

/// A geocoded area the user searched for.
class Place extends Equatable {
  const Place(this.label, this.point);

  final String label;
  final GeoPoint point;

  @override
  List<Object?> get props => [label, point];
}
