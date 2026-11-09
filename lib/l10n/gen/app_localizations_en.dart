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

  @override
  String get errorRateLimit =>
      'You\'ve reached the limit for now. Please try again later.';

  @override
  String get errorSignIn =>
      'That didn\'t work. Check the code, or ask for a new one.';

  @override
  String get bannedNotice =>
      'Your account can\'t add or vote on times. You can still browse.';

  @override
  String get signInTitle => 'Sign in to contribute';

  @override
  String get signInBody =>
      'Browsing never needs an account. Sign in to suggest times, vote, or add a missing masjid.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get or => 'or';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailMeCode => 'Email me a code';

  @override
  String codeSentTo(String email) {
    return 'We sent a code to $email. It expires in a few minutes.';
  }

  @override
  String get codeLabel => 'Code from the email';

  @override
  String get verifyCode => 'Sign in';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get resendCode => 'Send a new code';

  @override
  String get consentTitle => 'Before you contribute';

  @override
  String get consentBody =>
      'Your suggestions and votes help others find the right jamat time. Please confirm both to continue.';

  @override
  String get consentAdult => 'I am 18 or older';

  @override
  String get consentTerms => 'I agree to the Terms and Privacy Policy';

  @override
  String get continueLabel => 'Continue';

  @override
  String get terms => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String sourceCommunityBodyVotes(int votes) {
    String _temp0 = intl.Intl.pluralLogic(
      votes,
      locale: localeName,
      other: 'Suggested by the community, $votes net votes.',
      one: 'Suggested by the community, 1 net vote.',
    );
    return '$_temp0';
  }

  @override
  String get mayBeOutdated => 'May be outdated';

  @override
  String differingReports(int count) {
    return '$count people report a different time';
  }

  @override
  String get communityPrefix => 'Community:';

  @override
  String get suggest => 'Suggest';

  @override
  String voteFailed(String reason) {
    return 'Your vote wasn\'t saved. $reason';
  }

  @override
  String get communitySuggestions => 'Community suggestions';

  @override
  String get suggestTime => 'Suggest a time';

  @override
  String get noSuggestions => 'No suggestions yet.';

  @override
  String suggestedOn(String date) {
    return 'Suggested $date';
  }

  @override
  String suggestedOnYours(String date) {
    return 'Your suggestion · $date';
  }

  @override
  String get upvote => 'Upvote';

  @override
  String get downvote => 'Downvote';

  @override
  String netVotesSemantics(int votes) {
    String _temp0 = intl.Intl.pluralLogic(
      votes,
      locale: localeName,
      other: '$votes net votes',
      one: '1 net vote',
    );
    return '$_temp0';
  }

  @override
  String get suggestionThanks =>
      'Thanks. Your suggestion is listed under Community suggestions.';

  @override
  String get suggestTimeBody =>
      'It shows under Community suggestions straight away. A new suggestion for the same namaz replaces your old one.';

  @override
  String get jamatTime => 'Jamat time';

  @override
  String get azaanTimeOptional => 'Azaan time (optional)';

  @override
  String get azaanAfterJamat => 'Azaan must be at or before the jamat time.';

  @override
  String get noteOptional => 'Note (optional), e.g. \"From the notice board\"';

  @override
  String get sending => 'Sending…';

  @override
  String get submit => 'Submit';

  @override
  String get clear => 'Clear';

  @override
  String get addMasjid => 'Add a masjid';

  @override
  String get addMasjidBody =>
      'Tap the map where the masjid is, then enter its name. It appears once it has been reviewed.';

  @override
  String get addMasjidThanks =>
      'Thanks. The masjid will appear once it\'s been reviewed.';

  @override
  String get pinDroppedSemantics => 'Masjid location pin';

  @override
  String get tapMapForPin => 'Tap the map to place the pin.';

  @override
  String get pinDropped => 'Pin placed. Tap again to move it.';

  @override
  String get useMapCentre => 'Use map centre';

  @override
  String get masjidNameLabel => 'Masjid name';

  @override
  String get masjidLocalNameLabel => 'Name in Arabic or Urdu (optional)';

  @override
  String get scriptArabic => 'Arabic script';

  @override
  String get scriptUrdu => 'Urdu script';

  @override
  String get submitForReview => 'Send for review';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get account => 'Account';

  @override
  String get about => 'About';

  @override
  String get licences => 'Open-source licences';

  @override
  String versionLine(String version) {
    return 'Version $version';
  }

  @override
  String get signedOutBody => 'You\'re browsing without an account.';

  @override
  String signedInAs(String who) {
    return 'Signed in as $who';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get errorOutsideWindow =>
      'That time is outside this namaz\'s time at this masjid.';

  @override
  String get outsideWindowHint => 'Pick a time inside the window above.';

  @override
  String windowToday(String prayer) {
    return '$prayer here today:';
  }

  @override
  String get errorConflict =>
      'That can\'t be done: a limit was reached, such as 3 admins per masjid.';

  @override
  String get claimTitle => 'Claim this masjid';

  @override
  String get claimBody =>
      'Tell us your role at this masjid. Every claim is reviewed by hand, usually with a phone call.';

  @override
  String get claimRoleLabel => 'Your role';

  @override
  String get roleImam => 'Imam';

  @override
  String get roleMutawalli => 'Mutawalli';

  @override
  String get roleCommittee => 'Committee member';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHelper => 'Used only to confirm your claim.';

  @override
  String get proofLabel => 'Proof photo (optional)';

  @override
  String get proofHelper =>
      'A letter, notice board or card that links you to this masjid. Only the reviewer sees it.';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get photoAdded => 'Photo added';

  @override
  String get remove => 'Remove';

  @override
  String get claimPrivacy =>
      'Your phone number and photo are seen only by the reviewer and are deleted 90 days after the decision.';

  @override
  String get sendClaim => 'Send claim';

  @override
  String get claimThanks =>
      'Thanks. Your claim is waiting for review. We may call you to confirm.';

  @override
  String get claimPending => 'Your claim is waiting for review';

  @override
  String get manageTimes => 'Manage times';

  @override
  String get setTime => 'Set';

  @override
  String setTimeTitle(String prayer) {
    return '$prayer time';
  }

  @override
  String get startingToday => 'Starting today';

  @override
  String startingOn(String date) {
    return 'Starting $date';
  }

  @override
  String get changeDate => 'Change date';

  @override
  String get save => 'Save';

  @override
  String get timeSaved => 'Saved. It shows as verified now.';

  @override
  String get inbox => 'Inbox';

  @override
  String get inboxEmpty => 'No community suggestions differ from your times.';

  @override
  String get yourTime => 'Your time';

  @override
  String netVotes(int votes) {
    return '$votes net votes';
  }

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get superAdmin => 'Super admin';

  @override
  String get tabClaims => 'Claims';

  @override
  String get tabMasjids => 'Masjids';

  @override
  String get tabSuggestions => 'Suggestions';

  @override
  String get tabAdmins => 'Admins';

  @override
  String get tabHidden => 'Hidden';

  @override
  String get tabLog => 'Log';

  @override
  String get segPending => 'Pending';

  @override
  String get segActive => 'Active';

  @override
  String get segMasjids => 'Masjids';

  @override
  String get segSuggestions => 'Suggestions';

  @override
  String get segBanned => 'Banned users';

  @override
  String get searchByName => 'Search by name';

  @override
  String get emptyQueue => 'Nothing here.';

  @override
  String get loadMore => 'Load more';

  @override
  String get approve => 'Approve';

  @override
  String get hide => 'Hide';

  @override
  String get restore => 'Restore';

  @override
  String get revoke => 'Revoke';

  @override
  String get banAuthor => 'Ban author';

  @override
  String get unban => 'Unban';

  @override
  String get viewProof => 'View proof photo';

  @override
  String get openInMaps => 'Open in maps';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String byName(String name) {
    return 'by $name';
  }

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get rejectTitle => 'Reject?';

  @override
  String get cancel => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String confirmHideMasjidTitle(String name) {
    return 'Hide $name?';
  }

  @override
  String get confirmHideMasjidBody =>
      'It disappears for everyone. You can restore it from Hidden.';

  @override
  String confirmBanTitle(String name) {
    return 'Ban $name?';
  }

  @override
  String confirmBanBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open suggestions',
      one: '1 open suggestion',
      zero: 'no open suggestions',
    );
    return 'This hides $_temp0 by $name. They can still browse. You can unban them from Hidden.';
  }

  @override
  String confirmRevokeTitle(String name) {
    return 'Revoke admin rights of $name?';
  }

  @override
  String confirmRevokeBody(String masjid) {
    return 'They lose the admin section of $masjid. They can send a new claim later.';
  }

  @override
  String typeToConfirm(String text) {
    return 'Type $text to confirm';
  }

  @override
  String get superAdminTools => 'Super admin tools';

  @override
  String logAction(String action) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'approve_claim': 'Approved a claim',
      'reject_claim': 'Rejected a claim',
      'revoke_admin': 'Revoked an admin',
      'approve_masjid': 'Approved a masjid',
      'reject_masjid': 'Rejected a masjid',
      'hide_masjid': 'Hid a masjid',
      'restore_masjid': 'Restored a masjid',
      'hide_suggestion': 'Hid a suggestion',
      'restore_suggestion': 'Restored a suggestion',
      'accept_suggestion': 'Accepted a suggestion',
      'reject_suggestion': 'Rejected a suggestion',
      'ban_user': 'Banned a user',
      'unban_user': 'Unbanned a user',
      'other': '$action',
    });
    return '$_temp0';
  }

  @override
  String get downloadMyData => 'Download my data';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your profile, votes and claims are deleted. Times you suggested stay, without your name. This can\'t be undone.';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String get delete => 'Delete';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String contactLine(String email) {
    return 'Contact: $email';
  }

  @override
  String versionWithPatch(String version, int patch) {
    return '$version · patch $patch';
  }

  @override
  String get deleteAccountPage => 'Account deletion';

  @override
  String get landingTitle => 'Jamat times at masjids near you';

  @override
  String get landingBody =>
      'Times come from masjid admins and the community. They can change, so confirm with the masjid.';

  @override
  String get orSearchArea => 'or search an area';
}
