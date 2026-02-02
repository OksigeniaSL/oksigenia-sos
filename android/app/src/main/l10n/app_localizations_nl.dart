// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Oksigenia Systeem Klaar.';

  @override
  String get statusConnecting => 'Verbinden met satellieten...';

  @override
  String get statusLocationFixed => 'LOCATIE VASTGESTELD';

  @override
  String get statusSent => 'Alarm succesvol verzonden.';

  @override
  String statusError(Object error) {
    return 'FOUT: $error';
  }

  @override
  String get menuWeb => 'Officiële Website';

  @override
  String get menuSupport => 'Technische Ondersteuning';

  @override
  String get menuLanguages => 'Taal';

  @override
  String get menuSettings => 'Instellingen';

  @override
  String get menuPrivacy => 'Privacy & Juridisch';

  @override
  String get menuDonate => 'Doneren';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALERT* 🆘\n\nIk heb dringend hulp nodig.\n📍 Locatie: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'SOS Instellingen';

  @override
  String get settingsLabel => 'Noodtelefoon';

  @override
  String get settingsHint => 'Bijv: +31 6 12345678';

  @override
  String get settingsSave => 'OPSLAAN';

  @override
  String get settingsSavedMsg => 'Contact succesvol opgeslagen';

  @override
  String get errorNoContact => '⚠️ Configureer eerst een contact!';

  @override
  String get autoModeLabel => 'Valdetectie';

  @override
  String get autoModeDescription => 'Bewaakt zware schokken.';

  @override
  String get inactivityModeLabel => 'Inactiviteitsmonitor';

  @override
  String get inactivityModeDescription =>
      'Waarschuwt als er geen beweging wordt gedetecteerd.';

  @override
  String get alertFallDetected => 'SCHOK GEDETECTEERD!';

  @override
  String get alertFallBody => 'Zware val gedetecteerd. Ben je in orde?';

  @override
  String get alertInactivityDetected => 'INACTIVITEIT GEDETECTEERD!';

  @override
  String get alertInactivityBody =>
      'Geen beweging gedetecteerd. Ben je in orde?';

  @override
  String get btnImOkay => 'IK BEN OKÉ';

  @override
  String get disclaimerTitle => '⚠️ JURIDISCHE KENNISGEVING & PRIVACY';

  @override
  String get disclaimerText =>
      'Oksigenia SOS is een hulpmiddel, geen vervanging voor professionele hulpdiensten. De werking hangt af van externe factoren: batterij, GPS-signaal en mobiel bereik.\n\nDoor deze app te activeren, accepteert u dat de software \'as is\' wordt geleverd en ontheft u de ontwikkelaars van wettelijke aansprakelijkheid voor technische storingen. U bent verantwoordelijk voor uw eigen veiligheid.\n\nSMS-kosten: Alle berichtkosten zijn de verantwoordelijkheid van de gebruiker volgens de tarieven van de provider. Oksigenia dekt of berekent deze kosten niet.';

  @override
  String get btnAccept => 'IK ACCEPTEER HET RISICO';

  @override
  String get btnDecline => 'AFSLUITEN';

  @override
  String get privacyTitle => 'Voorwaarden & Privacy';

  @override
  String get privacyPolicyContent =>
      'PRIVACYBELEID & VOORWAARDEN\n\n1. GEEN GEGEVENSVERZAMELING\nOksigenia SOS werkt lokaal. We uploaden geen gegevens naar de cloud en verkopen uw informatie niet.\n\n2. TOESTEMMINGEN\n- Locatie: Voor coördinaten in geval van alarm.\n- SMS: Uitsluitend om het noodbericht te verzenden.\n\n3. BEPERKING VAN AANSPRAKELIJKHEID\nApp geleverd \'as is\'. Wij zijn niet verantwoordelijk voor dekkings- of hardwarestoringen.';

  @override
  String get advSettingsTitle => 'Geavanceerde Functies';

  @override
  String get advSettingsSubtitle => 'Multi-contact, GPS Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Gemeenschap';

  @override
  String get dialogCommunityBody => 'Dit is de COMMUNITY-versie (Gratis).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abonneer op PRO om meerdere contacten en real-time tracking te ontgrendelen.';

  @override
  String get btnDonate => 'Koop een koffie voor ons ☕';

  @override
  String get btnSubscribe => 'Abonneren';

  @override
  String get btnClose => 'Sluiten';

  @override
  String get permSmsTitle => 'GEVAAR! SMS-toestemming Geblokkeerd';

  @override
  String get permSmsBody =>
      'App KAN GEEN alarmen verzenden, zelfs met opgeslagen contacten.';

  @override
  String get permSmsButton => 'SMS inschakelen in Instellingen';

  @override
  String get restrictedSettingsTitle => 'Beperkte Instellingen';

  @override
  String get restrictedSettingsBody =>
      'Android heeft deze toestemming beperkt omdat de app handmatig is geïnstalleerd.';

  @override
  String get btnGoToSettings => 'GA NAAR INSTELLINGEN';

  @override
  String get contactsTitle => 'Noodcontacten';

  @override
  String get contactsSubtitle => 'De eerste (Hoofd) ontvangt GPS-tracking.';

  @override
  String get contactsAddHint => 'Nummer toevoegen';

  @override
  String get contactsEmpty => '⚠️ Geen contacten. Alarm wordt niet verzonden.';

  @override
  String get messageTitle => 'Aangepast Bericht';

  @override
  String get messageSubtitle => 'Verzonden VOOR de coördinaten.';

  @override
  String get messageHint => 'Bijv: Diabeet. Noordelijke route...';

  @override
  String get trackingTitle => 'GPS Tracking';

  @override
  String get trackingSubtitle =>
      'Stuurt positie naar Hoofdcontact elke X tijd.';

  @override
  String get trackOff => '❌ Uitgeschakeld';

  @override
  String get track30 => '⏱️ Elke 30 min';

  @override
  String get track60 => '⏱️ Elk uur';

  @override
  String get track120 => '⏱️ Elke 2 uur';

  @override
  String get contactMain => 'Hoofd';

  @override
  String get inactivityTimeTitle => 'Tijd voor Alarm';

  @override
  String get inactivityTimeSubtitle => 'Hoe lang zonder beweging voor alarm?';

  @override
  String get ina30s => '🧪 30 sec (TEST Modus)';

  @override
  String get ina1h => '⏱️ 1 uur (Aanbevolen)';

  @override
  String get ina2h => '⏱️ 2 uur (Lange pauze)';

  @override
  String get testModeWarning => '⚠️ TESTMODUS AAN: Alarm gaat af in 30s.';

  @override
  String get toastHoldToSOS => 'Houd knop ingedrukt voor SOS';

  @override
  String get donateDialogTitle => '💎 Steun het Project';

  @override
  String get donateDialogBody =>
      'Deze app is gratis en open source. Als het je veilig houdt, koop een koffie voor ons.';

  @override
  String get donateBtn => 'Doneren via PayPal';

  @override
  String get donateClose => 'SLUITEN';

  @override
  String get alertSendingIn => 'Alarm verzenden over...';

  @override
  String get alertCancel => 'ANNULEREN';

  @override
  String get warningKeepAlive =>
      '⚠️ BELANGRIJK: Sluit de app niet door te vegen. Laat het op de achtergrond zodat het automatisch kan herstarten.';

  @override
  String get aboutTitle => 'Over';

  @override
  String get aboutVersion => 'Versie';

  @override
  String get aboutDisclaimer => 'Juridische Disclaimer';

  @override
  String get aboutPrivacy => 'Privacybeleid';

  @override
  String get aboutSourceCode => 'Broncode (GitHub)';

  @override
  String get aboutLicenses => 'Softwarelicenties';

  @override
  String get aboutDevelopedBy => 'Ontwikkeld met ❤️ door Oksigenia';

  @override
  String get dialogClose => 'Sluiten';

  @override
  String get permSmsText =>
      'SMS-toestemmingen ontbreken. App kan geen alarmen verzenden.';

  @override
  String get phoneLabel => 'Telefoon (bijv. +31...)';

  @override
  String get btnAdd => 'TOEVOEGEN';

  @override
  String get noContacts => 'Geen contacten geconfigureerd.';

  @override
  String get inactivityTitle => 'Inactiviteitstijd';

  @override
  String get invalidNumberWarning => 'Ongeldig of te kort nummer';

  @override
  String get inactivitySubtitle =>
      'Tijd zonder beweging voordat hulp wordt ingeroepen.';

  @override
  String get dialogPermissionTitle => 'Hoe toestemmingen in te schakelen';

  @override
  String get dialogPermissionStep1 =>
      '1. Tik hieronder op \'GA NAAR INSTELLINGEN\'.';

  @override
  String get dialogPermissionStep2 =>
      '2. Tik op het nieuwe scherm op de 3 puntjes (⠇) rechtsboven.';

  @override
  String get dialogPermissionStep3 =>
      '3. Selecteer \'Beperkte instellingen toestaan\' (indien zichtbaar).';

  @override
  String get dialogPermissionStep4 => '4. Keer terug naar deze app.';

  @override
  String get timerLabel => 'Timer';

  @override
  String get timerSeconds => 'sec';

  @override
  String get permSmsOk => 'SMS-toestemming actief';

  @override
  String get permSensorsOk => 'Sensoren actief';

  @override
  String get permNotifOk => 'Meldingen actief';

  @override
  String get permSmsMissing => 'SMS-toestemming ontbreekt';

  @override
  String get permSensorsMissing => 'Sensoren ontbreken';

  @override
  String get permNotifMissing => 'Meldingen ontbreken';

  @override
  String get permOverlayMissing => 'Overlay ontbreekt';

  @override
  String get permDialogTitle => 'Toestemming vereist';

  @override
  String get permSmsHelpTitle => 'SMS Hulp';

  @override
  String get permGoSettings => 'Ga naar Instellingen';

  @override
  String get gpsHelpTitle => 'GPS';

  @override
  String get gpsHelpBody =>
      'GPS is afhankelijk van de fysieke chip en zichtbaarheid.';
}
