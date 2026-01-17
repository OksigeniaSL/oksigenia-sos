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
}
