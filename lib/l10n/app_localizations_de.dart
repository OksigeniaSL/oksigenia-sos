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
  String get statusReady => 'Oksigenia System bereit.';

  @override
  String get statusConnecting => 'Verbindung zu Satelliten...';

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
  String get settingsHint => 'Bsp: +49 151 12345678';

  @override
  String get settingsSave => 'SPEICHERN';

  @override
  String get settingsSavedMsg => 'Kontakt erfolgreich gespeichert';

  @override
  String get errorNoContact => '⚠️ Bitte erst Kontakt konfigurieren!';

  @override
  String get autoModeLabel => 'Sturzerkennung';

  @override
  String get autoModeDescription => 'Überwacht starke Aufpralle.';

  @override
  String get alertFallDetected => 'AUFPRALL ERKANNT!';

  @override
  String get alertFallBody => 'Schwerer Sturz erkannt. Alles okay?';

  @override
  String get disclaimerTitle => '⚠️ RECHTSHINWEIS & DATENSCHUTZ';

  @override
  String get disclaimerText =>
      'Diese App ist ein Hilfsmittel und ERSETZT NICHT professionelle Rettungsdienste (112, 911).\n\nDATENSCHUTZ: Oksigenia sammelt KEINE persönlichen Daten. Ihr Standort und Ihre Kontakte verbleiben ausschließlich auf Ihrem Gerät.\n\nDie Funktionalität hängt vom Gerätezustand, Akku und Netzabdeckung ab. Nutzung auf eigene Gefahr.';

  @override
  String get btnAccept => 'AKZEPTIEREN';

  @override
  String get btnDecline => 'BEENDEN';

  @override
  String get menuPrivacy => 'Datenschutz & Rechtliches';

  @override
  String get privacyTitle => 'Bedingungen & Datenschutz';

  @override
  String get privacyPolicyContent =>
      'DATENSCHUTZRICHTLINIE & NUTZUNGSBEDINGUNGEN\n\n1. KEINE DATENERFASSUNG\nOksigenia SOS basiert auf dem Prinzip \'Privacy by Design\'. Die Anwendung arbeitet vollständig lokal. Wir laden Ihre Daten nicht in eine Cloud hoch, nutzen keine Tracking-Server und verkaufen Ihre Informationen nicht. Ihre Notfallkontakte bleiben streng auf Ihrem Gerät.\n\n2. NUTZUNG VON BERECHTIGUNGEN\n- Standort: Wird ausschließlich verwendet, um GPS-Koordinaten im Falle eines Aufpralls oder einer manuellen Aktivierung abzurufen. Es erfolgt kein Hintergrund-Tracking, wenn die Überwachung deaktiviert ist.\n- SMS: Wird ausschließlich verwendet, um die Alarmnachricht an Ihren definierten Kontakt zu senden. Die App liest Ihre persönlichen Nachrichten nicht.\n\n3. HAFTUNGSBESCHRÄNKUNG\nDiese Anwendung wird \'wie besehen\' zur Verfügung gestellt, ohne jegliche Garantie. Oksigenia und seine Entwickler haften nicht für Schäden oder Folgen, die aus einem Softwarefehler resultieren, einschließlich: fehlende Mobilfunkabdeckung, leerer Akku oder GPS-Fehler.\n\nDieses Tool ist eine Sicherheitsergänzung und darf niemals als unfehlbarer Ersatz für professionelle Rettungsdienste angesehen werden.';

  @override
  String get advSettingsTitle => 'Erweiterte Funktionen';

  @override
  String get advSettingsSubtitle => 'Multi-Kontakt, GPS-Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'Dies ist die COMMUNITY-Version (Kostenlos).\n\nAlle Funktionen sind dank Open Source freigeschaltet.\n\nWenn sie nützlich ist, erwägen Sie eine freiwillige Spende.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abonnieren Sie die PRO-Version, um mehrere Kontakte und Echtzeit-Tracking auf unseren privaten Servern freizuschalten.';

  @override
  String get btnDonate => 'Spendier mir einen Kaffee ☕';

  @override
  String get btnSubscribe => 'Abonnieren';

  @override
  String get btnClose => 'Schließen';
}
