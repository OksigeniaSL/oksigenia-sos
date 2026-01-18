// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Oksigenia System Bereit.';

  @override
  String get statusConnecting => 'Verbinde Satelliten...';

  @override
  String get statusLocationFixed => 'STANDORT FIXIERT';

  @override
  String get statusSent => 'Alarm erfolgreich gesendet.';

  @override
  String statusError(Object error) {
    return 'FEHLER: $error';
  }

  @override
  String get menuWeb => 'Offizielle Website';

  @override
  String get menuSupport => 'Technischer Support';

  @override
  String get menuLanguages => 'Sprache';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALARM* 🆘\n\nIch brauche dringend Hilfe.\n📍 Standort: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'SOS Einstellungen';

  @override
  String get settingsLabel => 'Notrufnummer';

  @override
  String get settingsHint => 'Bsp: +49 150 123 456';

  @override
  String get settingsSave => 'SPEICHERN';

  @override
  String get settingsSavedMsg => 'Kontakt gespeichert';

  @override
  String get errorNoContact => '⚠️ Zuerst Kontakt konfigurieren!';

  @override
  String get autoModeLabel => 'Sturzerkennung';

  @override
  String get autoModeDescription => 'Überwacht schwere Stöße.';

  @override
  String get inactivityModeLabel => 'Inaktivitätsmonitor';

  @override
  String get inactivityModeDescription => 'Alarm bei fehlender Bewegung.';

  @override
  String get alertFallDetected => 'AUFPRALL ERKANNT!';

  @override
  String get alertFallBody => 'Schwerer Sturz erkannt. Alles okay?';

  @override
  String get alertInactivityDetected => 'INAKTIVITÄT ERKANNT!';

  @override
  String get alertInactivityBody => 'Keine Bewegung erkannt. Alles okay?';

  @override
  String get btnImOkay => 'MIR GEHT ES GUT';

  @override
  String get disclaimerTitle => '⚠️ RECHTSHINWEIS & DATENSCHUTZ';

  @override
  String get disclaimerText =>
      'Oksigenia SOS ist ein Hilfsmittel. Der Betrieb hängt von Akku, GPS und Mobilfunknetz ab.\n\nSie akzeptieren die Nutzung \'wie besehen\' auf eigenes Risiko.';

  @override
  String get btnAccept => 'ICH AKZEPTIERE DAS RISIKO';

  @override
  String get btnDecline => 'BEENDEN';

  @override
  String get menuPrivacy => 'Datenschutz & Rechtliches';

  @override
  String get privacyTitle => 'Begriffe & Datenschutz';

  @override
  String get privacyPolicyContent =>
      'DATENSCHUTZRICHTLINIE\n\n1. KEINE DATENSAMMLUNG\nLokaler Betrieb.\n\n2. BERECHTIGUNGEN\n- GPS: Für Alarm.\n- SMS: Für Hilferuf.\n\n3. HAFTUNG\nSoftware ohne Garantie.';

  @override
  String get advSettingsTitle => 'Erweiterte Funktionen';

  @override
  String get advSettingsSubtitle => 'Multi-Kontakt, GPS-Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'COMMUNITY Version (Kostenlos).\n\nOpen Source.\n\nSpenden Sie, wenn nützlich.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody => 'Abonnieren Sie PRO für Echtzeit-Tracking.';

  @override
  String get btnDonate => 'Kauf mir einen Kaffee ☕';

  @override
  String get btnSubscribe => 'Abonnieren';

  @override
  String get btnClose => 'Schließen';
}
