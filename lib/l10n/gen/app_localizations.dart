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

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit for now. Please try again later.'**
  String get errorRateLimit;

  /// No description provided for @errorSignIn.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Check the code, or ask for a new one.'**
  String get errorSignIn;

  /// No description provided for @bannedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t add or vote on times. You can still browse.'**
  String get bannedNotice;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to contribute'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Browsing never needs an account. Sign in to suggest times, vote, or add a missing masjid.'**
  String get signInBody;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailMeCode.
  ///
  /// In en, this message translates to:
  /// **'Email me a code'**
  String get emailMeCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}. It expires in a few minutes.'**
  String codeSentTo(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get codeLabel;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get verifyCode;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get resendCode;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you contribute'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Your suggestions and votes help others find the right jamat time. Please confirm both to continue.'**
  String get consentBody;

  /// No description provided for @consentAdult.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older'**
  String get consentAdult;

  /// No description provided for @consentTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Privacy Policy'**
  String get consentTerms;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @sourceCommunityBodyVotes.
  ///
  /// In en, this message translates to:
  /// **'{votes, plural, =1{Suggested by the community, 1 net vote.} other{Suggested by the community, {votes} net votes.}}'**
  String sourceCommunityBodyVotes(int votes);

  /// No description provided for @mayBeOutdated.
  ///
  /// In en, this message translates to:
  /// **'May be outdated'**
  String get mayBeOutdated;

  /// No description provided for @differingReports.
  ///
  /// In en, this message translates to:
  /// **'{count} people report a different time'**
  String differingReports(int count);

  /// No description provided for @communityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Community:'**
  String get communityPrefix;

  /// No description provided for @suggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get suggest;

  /// No description provided for @voteFailed.
  ///
  /// In en, this message translates to:
  /// **'Your vote wasn\'t saved. {reason}'**
  String voteFailed(String reason);

  /// No description provided for @communitySuggestions.
  ///
  /// In en, this message translates to:
  /// **'Community suggestions'**
  String get communitySuggestions;

  /// No description provided for @suggestTime.
  ///
  /// In en, this message translates to:
  /// **'Suggest a time'**
  String get suggestTime;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions yet.'**
  String get noSuggestions;

  /// No description provided for @suggestedOn.
  ///
  /// In en, this message translates to:
  /// **'Suggested {date}'**
  String suggestedOn(String date);

  /// No description provided for @suggestedOnYours.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion · {date}'**
  String suggestedOnYours(String date);

  /// No description provided for @upvote.
  ///
  /// In en, this message translates to:
  /// **'Upvote'**
  String get upvote;

  /// No description provided for @downvote.
  ///
  /// In en, this message translates to:
  /// **'Downvote'**
  String get downvote;

  /// No description provided for @netVotesSemantics.
  ///
  /// In en, this message translates to:
  /// **'{votes, plural, =1{1 net vote} other{{votes} net votes}}'**
  String netVotesSemantics(int votes);

  /// No description provided for @suggestionThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your suggestion is listed under Community suggestions.'**
  String get suggestionThanks;

  /// No description provided for @suggestTimeBody.
  ///
  /// In en, this message translates to:
  /// **'It shows under Community suggestions straight away. A new suggestion for the same namaz replaces your old one.'**
  String get suggestTimeBody;

  /// No description provided for @jamatTime.
  ///
  /// In en, this message translates to:
  /// **'Jamat time'**
  String get jamatTime;

  /// No description provided for @azaanTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'Azaan time (optional)'**
  String get azaanTimeOptional;

  /// No description provided for @azaanAfterJamat.
  ///
  /// In en, this message translates to:
  /// **'Azaan must be at or before the jamat time.'**
  String get azaanAfterJamat;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional), e.g. \"From the notice board\"'**
  String get noteOptional;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @addMasjid.
  ///
  /// In en, this message translates to:
  /// **'Add a masjid'**
  String get addMasjid;

  /// No description provided for @addMasjidBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the map where the masjid is, then enter its name. It appears once it has been reviewed.'**
  String get addMasjidBody;

  /// No description provided for @addMasjidThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. The masjid will appear once it\'s been reviewed.'**
  String get addMasjidThanks;

  /// No description provided for @pinDroppedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Masjid location pin'**
  String get pinDroppedSemantics;

  /// No description provided for @tapMapForPin.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the pin.'**
  String get tapMapForPin;

  /// No description provided for @pinDropped.
  ///
  /// In en, this message translates to:
  /// **'Pin placed. Tap again to move it.'**
  String get pinDropped;

  /// No description provided for @useMapCentre.
  ///
  /// In en, this message translates to:
  /// **'Use map centre'**
  String get useMapCentre;

  /// No description provided for @masjidNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Masjid name'**
  String get masjidNameLabel;

  /// No description provided for @masjidLocalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name in Arabic or Urdu (optional)'**
  String get masjidLocalNameLabel;

  /// No description provided for @scriptArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic script'**
  String get scriptArabic;

  /// No description provided for @scriptUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu script'**
  String get scriptUrdu;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get submitForReview;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licences;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLine(String version);

  /// No description provided for @signedOutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing without an account.'**
  String get signedOutBody;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {who}'**
  String signedInAs(String who);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @errorOutsideWindow.
  ///
  /// In en, this message translates to:
  /// **'That time is outside this namaz\'s time at this masjid.'**
  String get errorOutsideWindow;

  /// No description provided for @outsideWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a time inside the window above.'**
  String get outsideWindowHint;

  /// No description provided for @windowToday.
  ///
  /// In en, this message translates to:
  /// **'{prayer} here today:'**
  String windowToday(String prayer);

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'That can\'t be done: a limit was reached, such as 3 admins per masjid.'**
  String get errorConflict;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim this masjid'**
  String get claimTitle;

  /// No description provided for @claimBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us your role at this masjid. Every claim is reviewed by hand, usually with a phone call.'**
  String get claimBody;

  /// No description provided for @claimRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get claimRoleLabel;

  /// No description provided for @roleImam.
  ///
  /// In en, this message translates to:
  /// **'Imam'**
  String get roleImam;

  /// No description provided for @roleMutawalli.
  ///
  /// In en, this message translates to:
  /// **'Mutawalli'**
  String get roleMutawalli;

  /// No description provided for @roleCommittee.
  ///
  /// In en, this message translates to:
  /// **'Committee member'**
  String get roleCommittee;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Used only to confirm your claim.'**
  String get phoneHelper;

  /// No description provided for @proofLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof photo (optional)'**
  String get proofLabel;

  /// No description provided for @proofHelper.
  ///
  /// In en, this message translates to:
  /// **'A letter, notice board or card that links you to this masjid. Only the reviewer sees it.'**
  String get proofHelper;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get photoAdded;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @claimPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your phone number and photo are seen only by the reviewer and are deleted 90 days after the decision.'**
  String get claimPrivacy;

  /// No description provided for @sendClaim.
  ///
  /// In en, this message translates to:
  /// **'Send claim'**
  String get sendClaim;

  /// No description provided for @claimThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Your claim is waiting for review. We may call you to confirm.'**
  String get claimThanks;

  /// No description provided for @claimPending.
  ///
  /// In en, this message translates to:
  /// **'Your claim is waiting for review'**
  String get claimPending;

  /// No description provided for @manageTimes.
  ///
  /// In en, this message translates to:
  /// **'Manage times'**
  String get manageTimes;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setTime;

  /// No description provided for @setTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} time'**
  String setTimeTitle(String prayer);

  /// No description provided for @startingToday.
  ///
  /// In en, this message translates to:
  /// **'Starting today'**
  String get startingToday;

  /// No description provided for @startingOn.
  ///
  /// In en, this message translates to:
  /// **'Starting {date}'**
  String startingOn(String date);

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDate;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @timeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. It shows as verified now.'**
  String get timeSaved;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No community suggestions differ from your times.'**
  String get inboxEmpty;

  /// No description provided for @yourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time'**
  String get yourTime;

  /// No description provided for @netVotes.
  ///
  /// In en, this message translates to:
  /// **'{votes} net votes'**
  String netVotes(int votes);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get superAdmin;

  /// No description provided for @tabClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get tabClaims;

  /// No description provided for @tabMasjids.
  ///
  /// In en, this message translates to:
  /// **'Masjids'**
  String get tabMasjids;

  /// No description provided for @tabSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get tabSuggestions;

  /// No description provided for @tabAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get tabAdmins;

  /// No description provided for @tabHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get tabHidden;

  /// No description provided for @tabLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get tabLog;

  /// No description provided for @segPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get segPending;

  /// No description provided for @segActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get segActive;

  /// No description provided for @segMasjids.
  ///
  /// In en, this message translates to:
  /// **'Masjids'**
  String get segMasjids;

  /// No description provided for @segSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get segSuggestions;

  /// No description provided for @segBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned users'**
  String get segBanned;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @emptyQueue.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get emptyQueue;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @banAuthor.
  ///
  /// In en, this message translates to:
  /// **'Ban author'**
  String get banAuthor;

  /// No description provided for @unban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get unban;

  /// No description provided for @viewProof.
  ///
  /// In en, this message translates to:
  /// **'View proof photo'**
  String get viewProof;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get openInMaps;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @byName.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byName(String name);

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject?'**
  String get rejectTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @confirmHideMasjidTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide {name}?'**
  String confirmHideMasjidTitle(String name);

  /// No description provided for @confirmHideMasjidBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears for everyone. You can restore it from Hidden.'**
  String get confirmHideMasjidBody;

  /// No description provided for @confirmBanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban {name}?'**
  String confirmBanTitle(String name);

  /// No description provided for @confirmBanBody.
  ///
  /// In en, this message translates to:
  /// **'This hides {count, plural, =0{no open suggestions} =1{1 open suggestion} other{{count} open suggestions}} by {name}. They can still browse. You can unban them from Hidden.'**
  String confirmBanBody(int count, String name);

  /// No description provided for @confirmRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke admin rights of {name}?'**
  String confirmRevokeTitle(String name);

  /// No description provided for @confirmRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'They lose the admin section of {masjid}. They can send a new claim later.'**
  String confirmRevokeBody(String masjid);

  /// No description provided for @typeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {text} to confirm'**
  String typeToConfirm(String text);

  /// No description provided for @superAdminTools.
  ///
  /// In en, this message translates to:
  /// **'Super admin tools'**
  String get superAdminTools;

  /// No description provided for @logAction.
  ///
  /// In en, this message translates to:
  /// **'{action, select, approve_claim{Approved a claim} reject_claim{Rejected a claim} revoke_admin{Revoked an admin} approve_masjid{Approved a masjid} reject_masjid{Rejected a masjid} hide_masjid{Hid a masjid} restore_masjid{Restored a masjid} hide_suggestion{Hid a suggestion} restore_suggestion{Restored a suggestion} accept_suggestion{Accepted a suggestion} reject_suggestion{Rejected a suggestion} ban_user{Banned a user} unban_user{Unbanned a user} other{{action}}}'**
  String logAction(String action);

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, votes and claims are deleted. Times you suggested stay, without your name. This can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmWord;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @contactLine.
  ///
  /// In en, this message translates to:
  /// **'Contact: {email}'**
  String contactLine(String email);

  /// No description provided for @versionWithPatch.
  ///
  /// In en, this message translates to:
  /// **'{version} · patch {patch}'**
  String versionWithPatch(String version, int patch);

  /// No description provided for @deleteAccountPage.
  ///
  /// In en, this message translates to:
  /// **'Account deletion'**
  String get deleteAccountPage;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'Jamat times at masjids near you'**
  String get landingTitle;

  /// No description provided for @landingBody.
  ///
  /// In en, this message translates to:
  /// **'Times come from masjid admins and the community. They can change, so confirm with the masjid.'**
  String get landingBody;

  /// No description provided for @orSearchArea.
  ///
  /// In en, this message translates to:
  /// **'or search an area'**
  String get orSearchArea;
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
