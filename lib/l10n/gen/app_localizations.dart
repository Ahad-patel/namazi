import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Masjid Timer'**
  String get appName;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing what was loaded last.'**
  String get offline;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerZuhr.
  ///
  /// In en, this message translates to:
  /// **'Zuhr'**
  String get prayerZuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerJummah.
  ///
  /// In en, this message translates to:
  /// **'Jummah'**
  String get prayerJummah;

  /// No description provided for @searchAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Search an area, e.g. Bandra West'**
  String get searchAreaHint;

  /// No description provided for @searchAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Search area'**
  String get searchAreaLabel;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @showMap.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get showMap;

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'Show list'**
  String get showList;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// No description provided for @nearArea.
  ///
  /// In en, this message translates to:
  /// **'Near {area}'**
  String nearArea(String area);

  /// No description provided for @locationDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for an area to see masjids near it.'**
  String get locationDeniedTitle;

  /// No description provided for @locationDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this app. You can turn it on in settings, or search by area.'**
  String get locationDeniedBody;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Turn them on, or search by area.'**
  String get locationServiceOff;

  /// No description provided for @areaNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{query}\". Try a nearby landmark or area name.'**
  String areaNotFound(String query);

  /// No description provided for @emptyNearby.
  ///
  /// In en, this message translates to:
  /// **'No masjids within {km} km.'**
  String emptyNearby(int km);

  /// No description provided for @searchWider.
  ///
  /// In en, this message translates to:
  /// **'Search a wider area'**
  String get searchWider;

  /// No description provided for @distanceWalk.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {minutes} min walk'**
  String distanceWalk(String distance, int minutes);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @distanceM.
  ///
  /// In en, this message translates to:
  /// **'{m} m'**
  String distanceM(int m);

  /// No description provided for @noTimeYet.
  ///
  /// In en, this message translates to:
  /// **'No time yet'**
  String get noTimeYet;

  /// No description provided for @nextJamat.
  ///
  /// In en, this message translates to:
  /// **'Next jamat'**
  String get nextJamat;

  /// No description provided for @countdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{now} =1{1 min} other{{minutes} min}}'**
  String countdownMinutes(int minutes);

  /// No description provided for @countdownHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String countdownHours(int hours, int minutes);

  /// No description provided for @countdownDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d {hours} h'**
  String countdownDays(int days, int hours);

  /// No description provided for @nextIn.
  ///
  /// In en, this message translates to:
  /// **'Next · in {duration}'**
  String nextIn(String duration);

  /// No description provided for @nextJamatSemantics.
  ///
  /// In en, this message translates to:
  /// **'Next jamat {prayer} at {masjid} in {duration}'**
  String nextJamatSemantics(String prayer, String masjid, String duration);

  /// No description provided for @mapPinSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {distance}'**
  String mapPinSemantics(String name, String distance);

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @azaan.
  ///
  /// In en, this message translates to:
  /// **'Azaan'**
  String get azaan;

  /// No description provided for @jamat.
  ///
  /// In en, this message translates to:
  /// **'Jamat'**
  String get jamat;

  /// No description provided for @namaz.
  ///
  /// In en, this message translates to:
  /// **'Namaz'**
  String get namaz;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @detailFooter.
  ///
  /// In en, this message translates to:
  /// **'Times can change. Confirm with the masjid.'**
  String get detailFooter;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors · © MapTiler'**
  String get mapAttribution;

  /// No description provided for @emptyTimes.
  ///
  /// In en, this message translates to:
  /// **'No times yet for this masjid.'**
  String get emptyTimes;

  /// No description provided for @masjidNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this masjid. It may have moved or been removed.'**
  String get masjidNotFound;

  /// No description provided for @backToNearby.
  ///
  /// In en, this message translates to:
  /// **'Back to nearby masjids'**
  String get backToNearby;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist.'**
  String get pageNotFound;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @badgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified · {date}'**
  String badgeVerified(String date);

  /// No description provided for @badgeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community · {date}'**
  String badgeCommunity(String date);

  /// No description provided for @badgeVerifiedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Verified time, updated {date}'**
  String badgeVerifiedSemantics(String date);

  /// No description provided for @badgeCommunitySemantics.
  ///
  /// In en, this message translates to:
  /// **'Community time, updated {date}'**
  String badgeCommunitySemantics(String date);

  /// No description provided for @sourceVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get sourceVerifiedTitle;

  /// No description provided for @sourceVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Set by an approved admin of this masjid.'**
  String get sourceVerifiedBody;

  /// No description provided for @sourceCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get sourceCommunityTitle;

  /// No description provided for @sourceCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Suggested by the community.'**
  String get sourceCommunityBody;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that.'**
  String get errorNotFound;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get errorServer;

  /// No description provided for @errorLocation.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location. Search by area instead.'**
  String get errorLocation;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get technicalDetails;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
