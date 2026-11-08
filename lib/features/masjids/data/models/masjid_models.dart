import '../../../location/domain/entities/geo_point.dart';
import '../../domain/entities/masjid.dart';
import '../../domain/entities/nearby_masjid.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_time.dart';

class MasjidModel extends Masjid {
  const MasjidModel({
    required super.id,
    required super.slug,
    required super.name,
    required super.location,
    required super.timezone,
    super.nameLocal,
    super.nameScript,
    super.address,
  });

  /// Columns returned by `masjid_by_slug`, `nearby_masjids`, `next_jamat_nearby`.
  static const columns =
      'id,slug,name,name_local,name_script,address,timezone,latitude,longitude';

  factory MasjidModel.fromJson(Map<String, dynamic> j) => MasjidModel(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    nameLocal: j['name_local'] as String?,
    nameScript: switch (j['name_script']) {
      'arab' => NameScript.arab,
      'urdu' => NameScript.urdu,
      _ => null,
    },
    address: j['address'] as String?,
    timezone: j['timezone'] as String,
    location: GeoPoint(
      (j['latitude'] as num).toDouble(),
      (j['longitude'] as num).toDouble(),
    ),
  );
}

class PrayerTimeModel extends PrayerTime {
  const PrayerTimeModel({
    required super.prayer,
    required super.jamat,
    required super.source,
    required super.updatedAt,
    required super.nextAt,
    super.azaan,
  });

  static const columns =
      'prayer,azaan_time,jamat_time,source,updated_at,next_at';

  factory PrayerTimeModel.fromJson(Map<String, dynamic> j) => PrayerTimeModel(
    prayer: Prayer.values.byName(j['prayer'] as String),
    azaan: _clock(j['azaan_time']),
    jamat: ClockTime.parse(j['jamat_time'] as String),
    source: TimeSource.values.byName(j['source'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
    nextAt: _instant(j['next_at']),
  );
}

class NearbyMasjidModel extends NearbyMasjid {
  const NearbyMasjidModel({
    required super.masjid,
    required super.distanceM,
    super.next,
  });

  static const columns =
      '${MasjidModel.columns},distance_m,next_prayer,next_jamat_time,'
      'next_source,next_updated_at,next_at';

  factory NearbyMasjidModel.fromJson(Map<String, dynamic> j) =>
      NearbyMasjidModel(
        masjid: MasjidModel.fromJson(j),
        distanceM: (j['distance_m'] as num).toDouble(),
        next: j['next_prayer'] == null
            ? null
            : PrayerTimeModel(
                prayer: Prayer.values.byName(j['next_prayer'] as String),
                jamat: ClockTime.parse(j['next_jamat_time'] as String),
                source: TimeSource.values.byName(j['next_source'] as String),
                updatedAt: DateTime.parse(j['next_updated_at'] as String),
                nextAt: _instant(j['next_at']),
              ),
      );
}

ClockTime? _clock(Object? v) => v == null ? null : ClockTime.parse(v as String);

DateTime? _instant(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();
