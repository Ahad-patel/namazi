// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Masjid Timer';

  @override
  String get offline => 'You\'re offline. Showing what was loaded last.';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerZuhr => 'Zuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerJummah => 'Jummah';

  @override
  String get searchAreaHint => 'Search an area, e.g. Bandra West';

  @override
  String get searchAreaLabel => 'Search area';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get showMap => 'Show map';

  @override
  String get showList => 'Show list';

  @override
  String get nearYou => 'Near you';

  @override
  String nearArea(String area) {
    return 'Near $area';
  }

  @override
  String get locationDeniedTitle =>
      'Search for an area to see masjids near it.';

  @override
  String get locationDeniedBody =>
      'Location is off for this app. You can turn it on in settings, or search by area.';

  @override
  String get locationServiceOff =>
      'Location services are off. Turn them on, or search by area.';

  @override
  String areaNotFound(String query) {
    return 'We couldn\'t find \"$query\". Try a nearby landmark or area name.';
  }

  @override
  String emptyNearby(int km) {
    return 'No masjids within $km km.';
  }

  @override
  String get searchWider => 'Search a wider area';

  @override
  String distanceWalk(String distance, int minutes) {
    return '$distance · $minutes min walk';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceM(int m) {
    return '$m m';
  }

  @override
  String get noTimeYet => 'No time yet';

  @override
  String get nextJamat => 'Next jamat';

  @override
  String countdownMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
      zero: 'now',
    );
    return '$_temp0';
  }

  @override
  String countdownHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String countdownDays(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String nextIn(String duration) {
    return 'Next · in $duration';
  }

  @override
  String nextJamatSemantics(String prayer, String masjid, String duration) {
    return 'Next jamat $prayer at $masjid in $duration';
  }

  @override
  String mapPinSemantics(String name, String distance) {
    return '$name, $distance';
  }

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get azaan => 'Azaan';

  @override
  String get jamat => 'Jamat';

  @override
  String get namaz => 'Namaz';

  @override
  String get notAvailable => 'Not available';

  @override
  String get directions => 'Directions';

  @override
  String get detailFooter => 'Times can change. Confirm with the masjid.';

  @override
  String get mapAttribution => '© OpenStreetMap contributors · © MapTiler';

  @override
  String get emptyTimes => 'No times yet for this masjid.';

  @override
  String get masjidNotFound =>
      'We couldn\'t find this masjid. It may have moved or been removed.';

  @override
  String get backToNearby => 'Back to nearby masjids';

  @override
  String get pageNotFound => 'This page doesn\'t exist.';

  @override
  String get back => 'Back';

  @override
  String badgeVerified(String date) {
    return 'Verified · $date';
  }

  @override
  String badgeCommunity(String date) {
    return 'Community · $date';
  }

  @override
  String badgeVerifiedSemantics(String date) {
    return 'Verified time, updated $date';
  }

  @override
  String badgeCommunitySemantics(String date) {
    return 'Community time, updated $date';
  }

  @override
  String get sourceVerifiedTitle => 'Verified';

  @override
  String get sourceVerifiedBody => 'Set by an approved admin of this masjid.';

  @override
  String get sourceCommunityTitle => 'Community';

  @override
  String get sourceCommunityBody => 'Suggested by the community.';

  @override
  String get errorNetwork =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get errorPermission => 'You don\'t have permission to do that.';

  @override
  String get errorNotFound => 'We couldn\'t find that.';

  @override
  String get errorSessionExpired => 'Please sign in again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again.';

  @override
  String get errorLocation =>
      'We couldn\'t get your location. Search by area instead.';

  @override
  String get retry => 'Retry';

  @override
  String get signIn => 'Sign in';

  @override
  String get technicalDetails => 'Technical details';

  @override
  String get loading => 'Loading';
}
