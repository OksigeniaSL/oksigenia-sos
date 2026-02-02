// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Sistema Oksigenia pronto.';

  @override
  String get statusConnecting => 'Connessione ai satelliti...';

  @override
  String get statusLocationFixed => 'POSIZIONE ACQUISITA';

  @override
  String get statusSent => 'Allerta inviata correttamente.';

  @override
  String statusError(Object error) {
    return 'ERRORE: $error';
  }

  @override
  String get menuWeb => 'Sito Web ufficiale';

  @override
  String get menuSupport => 'Supporto Tecnico';

  @override
  String get menuLanguages => 'Lingua';

  @override
  String get menuSettings => 'Impostazioni';

  @override
  String get menuPrivacy => 'Privacy & Legalese';

  @override
  String get menuDonate => 'Dona';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Cresci;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALERT* 🆘\n\nHo urgentemente bisogno di auto.\n📍 Posizione: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'impostazioni SOS';

  @override
  String get settingsLabel => 'Contatti per Emergenze';

  @override
  String get settingsHint => 'Ex: +39 555 123 456';

  @override
  String get settingsSave => 'SALVA';

  @override
  String get settingsSavedMsg => 'Contatto salvato correttamente';

  @override
  String get errorNoContact => '⚠️ Prima configura un contatto!';

  @override
  String get autoModeLabel => 'Rilevamento Cadute';

  @override
  String get autoModeDescription => 'Monitora impatti violenti.';

  @override
  String get inactivityModeLabel => 'Rilevamento Inattività';

  @override
  String get inactivityModeDescription =>
      'Allerta se non vengono rilevati movimenti.';

  @override
  String get alertFallDetected => 'RILEVATO IMPATTO!';

  @override
  String get alertFallBody => 'Impatto violento rilevato, è tutto OK?';

  @override
  String get alertInactivityDetected => 'RILEVATA INATTIVITÀ!';

  @override
  String get alertInactivityBody => 'Nessun movimento rilevato, è tutto OK?';

  @override
  String get btnImOkay => 'STO BENE';

  @override
  String get disclaimerTitle => '⚠️ AVVERTENZE LEGALI & PRIVACY';

  @override
  String get disclaimerText =>
      'Oksigenia SOS è uno strumento di supporto, non un sostituto pe ri servizi di emergenza professionali. La sua operatività dipende da fattori esterni quali: battera, segnale GPS, copertura cellulare.\n\nAttivando questa app, accetti che il software sia forntito \'così com\'è\' e sollevi gli sviluppatori da qualunque responsabilità per problemi tecnici. Tu stesso sei responsabile per la tua sicurezza.\n\nCosto degli SMS: Tutti i costi relativi all\'invio di SMS sono sotto la responsabilità dell\'utente, secondo le tariffe del fornitore di servizi. Oksigenia non copre o addebita per questi messaggi.';

  @override
  String get btnAccept => 'ACCETTO IL RISCHIO';

  @override
  String get btnDecline => 'ESCI';

  @override
  String get privacyTitle => 'Condizioni & Privacy';

  @override
  String get privacyPolicyContent =>
      'PRIVACY POLICY & CONDIZIONI\n\n1. NO DATA COLLECTION\nOksigenia SOS opera localmente. Non carichiamo dati sul cloud nè vendiamo le tue informazioni.\n\n2. PERMESSI\n- Localizzazione: Per le coordinate in caso di allerta.\n- SMS: Esclusivamente per mandar eil messaggio di soccorso.\n\n3. LIMITAZIONE DI REPOSNABILITÀ\nApp fornita \'così com\'è\'. Non siamo responsabili per problemi di copertura o guasti hardware.';

  @override
  String get advSettingsTitle => 'Funzioni Avanzate';

  @override
  String get advSettingsSubtitle => 'Multi-contact, GPS Tracking...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody => 'Questa è la COMMUNITY version (Free).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abbonati alla versione PRO per sbloccare contatti multipi e tracking real-time.';

  @override
  String get btnDonate => 'Offrimi un caffè ☕';

  @override
  String get btnSubscribe => 'Abbonati';

  @override
  String get btnClose => 'Chiudi';

  @override
  String get permSmsTitle => 'PERICOLO! Permesso SMS Bloccato';

  @override
  String get permSmsBody =>
      'l\'App NON PUÒ inviare allerte ai contatti salvati.';

  @override
  String get permSmsButton => 'Abilita SMS nelle impostazioni';

  @override
  String get restrictedSettingsTitle => 'Impostazioni Limitate';

  @override
  String get restrictedSettingsBody =>
      'Android ha limitato questi permessi perchè l\'app è stata installata manualmente (side-loaded).';

  @override
  String get btnGoToSettings => 'VAI ALLE IMPOSTAZIONI';

  @override
  String get contactsTitle => 'Contatti di Emergenza';

  @override
  String get contactsSubtitle =>
      'Il primo (Principale) riceverà il tracking GPS.';

  @override
  String get contactsAddHint => 'Aggiungi numero';

  @override
  String get contactsEmpty =>
      '⚠️ Nessun contatto. Le allerte non saranno inviate.';

  @override
  String get messageTitle => 'Messaggio Personalizzato';

  @override
  String get messageSubtitle => 'Inviato PRIMA delle coordinate.';

  @override
  String get messageHint => 'Es: Diabetico. In rotta verso nord...';

  @override
  String get trackingTitle => 'Tracking GPS';

  @override
  String get trackingSubtitle =>
      'Invia la posizione al contatto principale ogni X tempo.';

  @override
  String get trackOff => '❌ Disabilitato';

  @override
  String get track30 => '⏱️ Ogni 30 min';

  @override
  String get track60 => '⏱️ Ogni 1 ora';

  @override
  String get track120 => '⏱️ Ogni 2 ore';

  @override
  String get contactMain => 'Principale (Tracking / Batteria)';

  @override
  String get inactivityTimeTitle => 'Tempo prima dell\'Allerta';

  @override
  String get inactivityTimeSubtitle =>
      'Quanto a lungo senza movimento prima di allertare?';

  @override
  String get ina30s => '🧪 30 sec (Modalità TEST)';

  @override
  String get ina1h => '⏱️ 1 ora (Raccomandato)';

  @override
  String get ina2h => '⏱️ 2 ore (Pausa lunga)';

  @override
  String get testModeWarning =>
      '⚠️ MODALITÀ TEST ATTIVATA: l\'allerta partirà tra 30s.';

  @override
  String get toastHoldToSOS => 'Tieni premuto il bottone per SOS';

  @override
  String get donateDialogTitle => '💎 Supporta il Progetto';

  @override
  String get donateDialogBody =>
      'Quasta app è gratuita ed Open Source Software. Se ti tiene al sicuro, offrici un caffè.';

  @override
  String get donateBtn => 'Dona via PayPal';

  @override
  String get donateClose => 'CHIUDI';

  @override
  String get alertSendingIn => 'Invio allerta tra...';

  @override
  String get alertCancel => 'CANCELLA';

  @override
  String get warningKeepAlive =>
      '⚠️ IMPORTANTE: Non scorrere via l\'app (Task Manager). Lasciala in background in modo che possa riavviarsi automaticamente.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutDisclaimer => 'Disclaimer Legale';

  @override
  String get aboutPrivacy => 'Privacy Policy';

  @override
  String get aboutSourceCode => 'Codice Sorgente (GitHub)';

  @override
  String get aboutLicenses => 'Licenze Software';

  @override
  String get aboutDevelopedBy => 'Sviluppato con ❤️ da Oksigenia';

  @override
  String get dialogClose => 'Chiudi';

  @override
  String get permSmsText =>
      'Permesso SMS mancante. L\'app non può inviare allerte.';

  @override
  String get phoneLabel => 'Telefono (e.g. +39...)';

  @override
  String get btnAdd => 'AGGIUNGI';

  @override
  String get noContacts => 'Nessun contatto configurato.';

  @override
  String get inactivityTitle => 'Tempo di Inattività';

  @override
  String get invalidNumberWarning => 'Numero non valido o troppo corto';

  @override
  String get inactivitySubtitle =>
      'Tempo in assenza di movimento prima di chiedere aiuto.';

  @override
  String get dialogPermissionTitle => 'Come abilitare i permessi';

  @override
  String get dialogPermissionStep1 =>
      '1. Premi \'VAI ALLE IMPOSTAZIONI\' qui sotto.';

  @override
  String get dialogPermissionStep2 =>
      '2. Sulla nuova schermata, premi i tre puntini (⠇) in alto a destra.';

  @override
  String get dialogPermissionStep3 =>
      '3. Seleziona \'Consenti impostazioni limitate\' (se visibile).';

  @override
  String get dialogPermissionStep4 => '4. Ritorna a questa app.';
}
