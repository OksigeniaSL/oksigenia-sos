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
  String get menuWeb => 'Offizielle Webseite';

  @override
  String get menuSupport => 'Technischer Support';

  @override
  String get menuLanguages => 'Sprache';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get motto => 'Atmen > Inspirieren > Wachsen;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALARM* 🆘\n\nIch brauche dringend Hilfe.\n📍 Standort: $link\n\nAtmen > Inspirieren > Wachsen;';
  }

  @override
  String get settingsTitle => 'SOS Konfiguration';

  @override
  String get settingsLabel => 'Notrufnummer';

  @override
  String get settingsHint => 'Bsp: +49 151 1234 5678';

  @override
  String get settingsSave => 'SPEICHERN';

  @override
  String get settingsSavedMsg => 'Kontakt erfolgreich gespeichert';

  @override
  String get errorNoContact => '⚠️ Bitte zuerst Kontakt konfigurieren!';

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
  String get disclaimerTitle => '⚠️ RECHTLICHER HINWEIS & DATENSCHUTZ';

  @override
  String get disclaimerText =>
      'Oksigenia SOS ist ein Hilfsmittel, kein Ersatz für professionelle Rettungsdienste. Der Betrieb hängt von externen Faktoren ab: Akku, GPS-Signal und Mobilfunkabdeckung.\n\nMit der Aktivierung dieser App akzeptieren Sie, dass die Software \'wie besehen\' geliefert wird, und stellen die Entwickler von der gesetzlichen Haftung für technische Ausfälle frei. Sie sind für Ihre eigene Sicherheit verantwortlich.';

  @override
  String get btnAccept => 'ICH AKZEPTIERE DAS RISIKO';

  @override
  String get btnDecline => 'BEENDEN';

  @override
  String get menuPrivacy => 'Datenschutz & Rechtliches';

  @override
  String get privacyTitle => 'AGB & Datenschutz';

  @override
  String get privacyPolicyContent =>
      'DATENSCHUTZRICHTLINIE & BEDINGUNGEN\n\n1. KEINE DATENSAMMLUNG\nOksigenia SOS arbeitet lokal. Wir laden keine Daten in die Cloud hoch und verkaufen Ihre Informationen nicht.\n\n2. BERECHTIGUNGEN\n- Standort: Für Koordinaten im Alarmfall.\n- SMS: Ausschließlich zum Senden des Notrufs.\n\n3. HAFTUNGSBESCHRÄNKUNG\nApp wird \'wie besehen\' bereitgestellt. Wir haften nicht für Netz- oder Hardwareausfälle.';

  @override
  String get advSettingsTitle => 'Erweiterte Funktionen';

  @override
  String get advSettingsSubtitle => 'Multi-Kontakt, GPS-Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'Dies ist die COMMUNITY-Version (Kostenlos).\n\nAlle Funktionen sind dank Open Source freigeschaltet.\n\nWenn es nützlich ist, erwägen Sie eine freiwillige Spende.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abonnieren Sie PRO, um mehrere Kontakte und Echtzeit-Tracking freizuschalten.';

  @override
  String get btnDonate => 'Spendier mir einen Kaffee ☕';

  @override
  String get btnSubscribe => 'Abonnieren';

  @override
  String get btnClose => 'Schließen';

  @override
  String get permSmsTitle => 'GEFAHR! SMS-Berechtigung blockiert';

  @override
  String get permSmsBody => 'Die App kann OHNE Erlaubnis keine Alarme senden.';

  @override
  String get permSmsButton => 'SMS in Einstellungen aktivieren';

  @override
  String get contactsTitle => 'Notfallkontakte';

  @override
  String get contactsSubtitle => 'Der erste (Haupt) erhält das GPS-Tracking.';

  @override
  String get contactsAddHint => 'Neue Nummer';

  @override
  String get contactsEmpty => '⚠️ Keine Kontakte. Alarm wird nicht gesendet.';

  @override
  String get messageTitle => 'Benutzerdefinierte Nachricht';

  @override
  String get messageSubtitle => 'Wird VOR den Koordinaten gesendet.';

  @override
  String get messageHint => 'Bsp: Diabetiker. Nordroute...';

  @override
  String get trackingTitle => 'GPS-Tracking';

  @override
  String get trackingSubtitle => 'Sendet Position alle X an Hauptkontakt.';

  @override
  String get trackOff => '❌ Deaktiviert';

  @override
  String get track30 => '⏱️ Alle 30 Min';

  @override
  String get track60 => '⏱️ Alle 1 Std';

  @override
  String get track120 => '⏱️ Alle 2 Std';

  @override
  String get contactMain => 'Haupt';

  @override
  String get inactivityTimeTitle => 'Zeit bis Alarm';

  @override
  String get inactivityTimeSubtitle => 'Wie lange ohne Bewegung?';

  @override
  String get ina30s => '🧪 30 Sek (TEST-Modus)';

  @override
  String get ina1h => '⏱️ 1 Stunde (Empfohlen)';

  @override
  String get ina2h => '⏱️ 2 Stunden (Lange Pause)';

  @override
  String get testModeWarning =>
      '⚠️ TEST-MODUS AKTIV: Alarm wird in 30s ausgelöst.';

  @override
  String get toastHoldToSOS => 'Für SOS gedrückt halten';

  @override
  String get donateDialogTitle => '💎 Projekt unterstützen';

  @override
  String get donateDialogBody =>
      'Diese App ist freie und Open-Source-Software.\nWenn sie Ihnen Sicherheit gibt, spendieren Sie uns einen Kaffee, um die Server zu finanzieren.';

  @override
  String get donateBtn => 'Spenden via PayPal';

  @override
  String get donateClose => 'SCHLIEßEN';
}
