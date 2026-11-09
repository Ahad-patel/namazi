import 'package:equatable/equatable.dart';

import '../../../location/domain/entities/geo_point.dart';
import 'masjid.dart';

/// A user-added masjid. Hidden until a super admin approves it.
class NewMasjid extends Equatable {
  const NewMasjid({
    required this.name,
    required this.location,
    this.nameLocal,
    this.nameScript,
  });

  final String name;
  final GeoPoint location;
  final String? nameLocal;
  final NameScript? nameScript;

  @override
  List<Object?> get props => [name, location, nameLocal, nameScript];
}
