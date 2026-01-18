// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Oksigenia System Ready.';

  @override
  String get statusConnecting => 'Connecting satellites...';

  @override
  String get statusLocationFixed => 'LOCATION FIXED';

  @override
  String get statusSent => 'Alert sent successfully.';

  @override
  String statusError(Object error) {
    return 'ERROR: $error';
  }

  @override
  String get menuWeb => 'Official Website';

  @override
  String get menuSupport => 'Tech Support';

  @override
  String get menuLanguages => 'Language';

  @override
  String get menuSettings => 'Settings';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALERT* 🆘\n\nI need urgent help.\n📍 Location: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'SOS Settings';

  @override
  String get settingsLabel => 'Emergency Phone Number';

  @override
  String get settingsHint => 'Ex: +1 555-0199';

  @override
  String get settingsSave => 'SAVE';

  @override
  String get settingsSavedMsg => 'Contact saved successfully';

  @override
  String get errorNoContact => '⚠️ Configure a contact first!';

  @override
  String get autoModeLabel => 'Fall Detection';

  @override
  String get autoModeDescription => 'Monitors severe impacts.';

  @override
  String get inactivityModeLabel => 'Inactivity Monitor';

  @override
  String get inactivityModeDescription => 'Alerts if no movement is detected.';

  @override
  String get alertFallDetected => 'IMPACT DETECTED!';

  @override
  String get alertFallBody => 'Severe fall detected. Are you okay?';

  @override
  String get alertInactivityDetected => 'INACTIVITY DETECTED!';

  @override
  String get alertInactivityBody =>
      'No movement detected for a while. Are you okay?';

  @override
  String get btnImOkay => 'I\'M OKAY';

  @override
  String get disclaimerTitle => '⚠️ LEGAL NOTICE & PRIVACY';

  @override
  String get disclaimerText =>
      'Oksigenia SOS is a support tool, not a replacement for professional emergency services. Its operation depends entirely on external factors: battery level, GPS signal, and cellular coverage.\n\nBy activating this app, you agree that the software is provided \'as is\' and release the developers from any legal liability for technical failures, lack of signal, or hardware errors. You are ultimately responsible for your own safety and for checking your equipment before heading out.';

  @override
  String get btnAccept => 'I ACCEPT THE RISK';

  @override
  String get btnDecline => 'EXIT';

  @override
  String get menuPrivacy => 'Privacy & Legal';

  @override
  String get privacyTitle => 'Terms & Privacy';

  @override
  String get privacyPolicyContent =>
      'PRIVACY POLICY AND TERMS OF USE\n\n1. NO DATA COLLECTION\nOksigenia SOS operates entirely locally. We do not upload your data to any cloud or sell your information. Your contacts and locations remain strictly on your device.\n\n2. USE OF PERMISSIONS\n- Location: Strictly for coordinates in case of alert.\n- SMS: Exclusively to send the distress message.\n\n3. LIMITATION OF LIABILITY\nThis app is provided \'as is\', without warranties. Developers are not liable for damages, injuries, or deaths resulting from software failure, including: lack of coverage, dead battery, OS failures, or hardware errors. This tool must never be considered an infallible substitute for professional emergency services (112/911).';

  @override
  String get advSettingsTitle => 'Advanced Features';

  @override
  String get advSettingsSubtitle => 'Multi-contact, GPS Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'This is the COMMUNITY version (Free).\n\nAll features are unlocked thanks to open source.\n\nIf you find it useful, consider a voluntary donation.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Subscribe to PRO version to unlock multiple contacts and real-time tracking on our private servers.';

  @override
  String get btnDonate => 'Buy me a coffee ☕';

  @override
  String get btnSubscribe => 'Subscribe';

  @override
  String get btnClose => 'Close';
}
