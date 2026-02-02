// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Oksigenia System Redo.';

  @override
  String get statusConnecting => 'Ansluter satelliter...';

  @override
  String get statusLocationFixed => 'PLATS FASTSTÄLLD';

  @override
  String get statusSent => 'Varning skickad.';

  @override
  String statusError(Object error) {
    return 'FEL: $error';
  }

  @override
  String get menuWeb => 'Officiell Webbplats';

  @override
  String get menuSupport => 'Teknisk Support';

  @override
  String get menuLanguages => 'Språk';

  @override
  String get menuSettings => 'Inställningar';

  @override
  String get menuPrivacy => 'Sekretess & Juridik';

  @override
  String get menuDonate => 'Donera';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALERT* 🆘\n\nJag behöver akut hjälp.\n📍 Plats: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'SOS Inställningar';

  @override
  String get settingsLabel => 'Nödtelefon';

  @override
  String get settingsHint => 'Ex: +46 70 123 4567';

  @override
  String get settingsSave => 'SPARA';

  @override
  String get settingsSavedMsg => 'Kontakt sparad';

  @override
  String get errorNoContact => '⚠️ Konfigurera en kontakt först!';

  @override
  String get autoModeLabel => 'Falldetektering';

  @override
  String get autoModeDescription => 'Övervakar svåra stötar.';

  @override
  String get inactivityModeLabel => 'Inaktivitetsmonitor';

  @override
  String get inactivityModeDescription => 'Varnar om ingen rörelse upptäcks.';

  @override
  String get alertFallDetected => 'STÖT UPPTÄCKT!';

  @override
  String get alertFallBody => 'Svårt fall upptäckt. Är du okej?';

  @override
  String get alertInactivityDetected => 'INAKTIVITET UPPTÄCKT!';

  @override
  String get alertInactivityBody => 'Ingen rörelse upptäckt. Är du okej?';

  @override
  String get btnImOkay => 'JAG ÄR OKEJ';

  @override
  String get disclaimerTitle => '⚠️ JURIDISKT MEDDELANDE & SEKRETESS';

  @override
  String get disclaimerText =>
      'Oksigenia SOS är ett stödverktyg, inte en ersättning för professionella nödtjänster. Dess funktion beror på externa faktorer: batteri, GPS-signal och mobiltäckning.\n\nGenom att aktivera denna app accepterar du att programvaran tillhandahålls \'i befintligt skick\' och friskriver utvecklarna från juridiskt ansvar för tekniska fel. Du ansvarar för din egen säkerhet.\n\nSMS-kostnader: Alla meddelandekostnader är användarens ansvar enligt mobiloperatörens taxor. Oksigenia täcker inte eller tar betalt för dessa meddelanden.';

  @override
  String get btnAccept => 'JAG ACCEPTERAR RISKEN';

  @override
  String get btnDecline => 'AVSLUTA';

  @override
  String get privacyTitle => 'Villkor & Sekretess';

  @override
  String get privacyPolicyContent =>
      'SEKRETESSPOLICY & VILLKOR\n\n1. INGEN DATAINSAMLING\nOksigenia SOS fungerar lokalt. Vi laddar inte upp data till molnet eller säljer din information.\n\n2. BEHÖRIGHETER\n- Plats: För koordinater vid larm.\n- SMS: Endast för att skicka nödmeddelandet.\n\n3. ANSVARSBEGRÄNSNING\nAppen tillhandahålls \'i befintligt skick\'. Vi ansvarar inte för täckning eller hårdvarufel.';

  @override
  String get advSettingsTitle => 'Avancerade Funktioner';

  @override
  String get advSettingsSubtitle => 'Flerkontakter, GPS-spårning...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Gemenskap';

  @override
  String get dialogCommunityBody => 'Detta är COMMUNITY-versionen (Gratis).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Prenumerera på PRO för att låsa upp flera kontakter och spårning i realtid.';

  @override
  String get btnDonate => 'Köp mig en kaffe ☕';

  @override
  String get btnSubscribe => 'Prenumerera';

  @override
  String get btnClose => 'Stäng';

  @override
  String get permSmsTitle => 'FARA! SMS-behörighet Blockerad';

  @override
  String get permSmsBody =>
      'Appen KAN INTE skicka larm även med sparade kontakter.';

  @override
  String get permSmsButton => 'Aktivera SMS i Inställningar';

  @override
  String get restrictedSettingsTitle => 'Begränsade Inställningar';

  @override
  String get restrictedSettingsBody =>
      'Android har begränsat denna behörighet eftersom appen installerades manuellt.';

  @override
  String get btnGoToSettings => 'GÅ TILL INSTÄLLNINGAR';

  @override
  String get contactsTitle => 'Nödkontakter';

  @override
  String get contactsSubtitle => 'Den första (Huvud) tar emot GPS-spårning.';

  @override
  String get contactsAddHint => 'Lägg till nummer';

  @override
  String get contactsEmpty =>
      '⚠️ Inga kontakter. Larm kommer inte att skickas.';

  @override
  String get messageTitle => 'Anpassat Meddelande';

  @override
  String get messageSubtitle => 'Skickas FÖRE koordinaterna.';

  @override
  String get messageHint => 'Ex: Diabetiker. Norra rutten...';

  @override
  String get trackingTitle => 'GPS-spårning';

  @override
  String get trackingSubtitle =>
      'Skickar position till Huvudkontakt varje X tid.';

  @override
  String get trackOff => '❌ Inaktiverad';

  @override
  String get track30 => '⏱️ Var 30:e min';

  @override
  String get track60 => '⏱️ Varje timme';

  @override
  String get track120 => '⏱️ Varannan timme';

  @override
  String get contactMain => 'Huvud';

  @override
  String get inactivityTimeTitle => 'Tid före Larm';

  @override
  String get inactivityTimeSubtitle => 'Hur länge utan rörelse innan larm?';

  @override
  String get ina30s => '🧪 30 sek (TEST-läge)';

  @override
  String get ina1h => '⏱️ 1 timme (Rekommenderas)';

  @override
  String get ina2h => '⏱️ 2 timmar (Lång paus)';

  @override
  String get testModeWarning => '⚠️ TESTLÄGE PÅ: Larm utlöses om 30s.';

  @override
  String get toastHoldToSOS => 'Håll knappen för SOS';

  @override
  String get donateDialogTitle => '💎 Stöd Projektet';

  @override
  String get donateDialogBody =>
      'Denna app är fri och öppen källkod. Om den håller dig säker, köp oss en kaffe.';

  @override
  String get donateBtn => 'Donera via PayPal';

  @override
  String get donateClose => 'STÄNG';

  @override
  String get alertSendingIn => 'Skickar larm om...';

  @override
  String get alertCancel => 'AVBRYT';

  @override
  String get warningKeepAlive =>
      '⚠️ VIKTIGT: Stäng inte appen genom att svepa bort den. Lämna den i bakgrunden så den kan starta om automatiskt.';

  @override
  String get aboutTitle => 'Om';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDisclaimer => 'Juridisk Friskrivning';

  @override
  String get aboutPrivacy => 'Sekretesspolicy';

  @override
  String get aboutSourceCode => 'Källkod (GitHub)';

  @override
  String get aboutLicenses => 'Programvarulicenser';

  @override
  String get aboutDevelopedBy => 'Utvecklad med ❤️ av Oksigenia';

  @override
  String get dialogClose => 'Stäng';

  @override
  String get permSmsText =>
      'SMS-behörigheter saknas. Appen kan inte skicka larm.';

  @override
  String get phoneLabel => 'Telefon (t.ex. +46...)';

  @override
  String get btnAdd => 'LÄGG TILL';

  @override
  String get noContacts => 'Inga kontakter konfigurerade.';

  @override
  String get inactivityTitle => 'Inaktivitetstid';

  @override
  String get invalidNumberWarning => 'Ogiltigt eller för kort nummer';

  @override
  String get inactivitySubtitle => 'Tid utan rörelse innan hjälp tillkallas.';

  @override
  String get dialogPermissionTitle => 'Hur man aktiverar behörigheter';

  @override
  String get dialogPermissionStep1 =>
      '1. Tryck på \'GÅ TILL INSTÄLLNINGAR\' nedan.';

  @override
  String get dialogPermissionStep2 =>
      '2. På nya skärmen, tryck på de 3 prickarna (⠇) uppe till höger.';

  @override
  String get dialogPermissionStep3 =>
      '3. Välj \'Tillåt begränsade inställningar\' (om synligt).';

  @override
  String get dialogPermissionStep4 => '4. Återgå till denna app.';

  @override
  String get timerLabel => 'Timer';

  @override
  String get timerSeconds => 'sek';

  @override
  String get permSmsOk => 'SMS-behörighet aktiv';

  @override
  String get permSensorsOk => 'Sensorer aktiva';

  @override
  String get permNotifOk => 'Aviseringar aktiva';

  @override
  String get permSmsMissing => 'SMS-behörighet saknas';

  @override
  String get permSensorsMissing => 'Sensorer saknas';

  @override
  String get permNotifMissing => 'Aviseringar saknas';

  @override
  String get permOverlayMissing => 'Överlagring saknas';

  @override
  String get permDialogTitle => 'Behörighet krävs';

  @override
  String get permSmsHelpTitle => 'SMS Hjälp';

  @override
  String get permGoSettings => 'Gå till Inställningar';

  @override
  String get gpsHelpTitle => 'GPS';

  @override
  String get gpsHelpBody => 'GPS beror på det fysiska chippet och sikten.';
}
