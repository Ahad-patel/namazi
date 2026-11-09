import 'package:equatable/equatable.dart';

import '../../../location/domain/entities/geo_point.dart';

enum NameScript { arab, urdu }

class Masjid extends Equatable {
  const Masjid({
    required this.id,
    required this.slug,
    required this.name,
    required this.location,
    required this.timezone,
    this.nameLocal,
    this.nameScript,
    this.address,
  });

  final String id;
  final String slug;
  final String name;
  final String? nameLocal;
  final NameScript? nameScript;
  final String? address;
  final GeoPoint location;
  final String timezone;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    nameLocal,
    nameScript,
    address,
    location,
    timezone,
  ];
}
