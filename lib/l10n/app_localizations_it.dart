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
  String get statusReady => 'Sistema Oksigenia Pronto.';

  @override
  String get statusConnecting => 'Connessione satelliti...';

  @override
  String get statusLocationFixed => 'POSIZIONE AGGIORNATA';

  @override
  String get statusSent => 'Allerta inviata con successo.';

  @override
  String statusError(Object error) {
    return 'ERRORE: $error';
  }

  @override
  String get menuWeb => 'Sito Ufficiale';

  @override
  String get menuSupport => 'Supporto Tecnico';

  @override
  String get menuLanguages => 'Lingua';

  @override
  String get menuSettings => 'Impostazioni';

  @override
  String get menuPrivacy => 'Privacy e Note Legali';

  @override
  String get menuDonate => 'Dona / Donate';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Cresci;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALLERTA OKSIGENIA* 🆘\n\nHo bisogno di aiuto urgente.\n📍 Posizione: $link\n\nRespira > Inspira > Cresci;';
  }

  @override
  String get settingsTitle => 'Impostazioni SOS';

  @override
  String get settingsLabel => 'Telefono di Emergenza';

  @override
  String get settingsHint => 'Es: +39 333 123 4567';

  @override
  String get settingsSave => 'SALVA';

  @override
  String get settingsSavedMsg => 'Contatto salvato con successo';

  @override
  String get errorNoContact => '⚠️ Configura prima un contatto!';

  @override
  String get autoModeLabel => 'Rilevamento Cadute';

  @override
  String get autoModeDescription => 'Monitora impatti violenti.';

  @override
  String get inactivityModeLabel => 'Monitor Inattività';

  @override
  String get inactivityModeDescription =>
      'Avvisa se non viene rilevato alcun movimento.';

  @override
  String get alertFallDetected => 'IMPATTO RILEVATO!';

  @override
  String get alertFallBody => 'Rilevata caduta grave. Tutto bene?';

  @override
  String get alertInactivityDetected => 'INATTIVITÀ RILEVATA!';

  @override
  String get alertInactivityBody => 'Nessun movimento rilevato. Tutto bene?';

  @override
  String get btnImOkay => 'STO BENE';

  @override
  String get disclaimerTitle => '⚠️ NOTE LEGALI E PRIVACY';

  @override
  String get disclaimerText =>
      'Oksigenia SOS è uno strumento di supporto, non sostituisce i servizi di emergenza professionali. Il suo funzionamento dipende da fattori esterni: batteria, segnale GPS e copertura mobile.\n\nAttivando questa app, accetti che il software venga fornito \'così com\'è\' e sollevi gli sviluppatori da responsabilità legali per guasti tecnici. Sei responsabile della tua sicurezza.\n\nCosti Servizio SMS: Tutti i costi dei messaggi sono a carico dell\'utente secondo le tariffe del proprio operatore. Oksigenia non copre né addebita questi messaggi.';

  @override
  String get btnAccept => 'ACCETTO IL RISCHIO';

  @override
  String get btnDecline => 'ESCI';

  @override
  String get privacyTitle => 'Termini e Privacy';

  @override
  String get privacyPolicyContent =>
      'INFORMATIVA SULLA PRIVACY E TERMINI\n\n1. NESSUNA RACCOLTA DATI\nOksigenia SOS opera localmente. Non carichiamo dati sul cloud né vendiamo le tue informazioni.\n\n2. PERMESSI\n- Posizione: Per le coordinate in caso di allerta.\n- SMS: Esclusivamente per inviare il messaggio di soccorso.\n\n3. LIMITAZIONE DI RESPONSABILITÀ\nApp fornita \'così com\'è\'. Non siamo responsabili per mancanze di copertura o guasti hardware.';

  @override
  String get advSettingsTitle => 'Funzioni Avanzate';

  @override
  String get advSettingsSubtitle => 'Multi-contatto, Tracking GPS...';

  @override
  String get dialogCommunityTitle => '💎 Comunità Oksigenia';

  @override
  String get dialogCommunityBody =>
      'Questa è la versione COMMUNITY (Gratuita).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abbonati a PRO per sbloccare contatti multipli e monitoraggio in tempo reale.';

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
      'L\'app NON PUÒ inviare avvisi anche con contatti salvati.';

  @override
  String get permSmsButton => 'Attiva SMS nelle Impostazioni';

  @override
  String get restrictedSettingsTitle => 'Impostazioni Limitate';

  @override
  String get restrictedSettingsBody =>
      'Android ha limitato questo permesso perché l\'app è stata installata manualmente (side-loaded).';

  @override
  String get contactsTitle => 'Contatti di Emergenza';

  @override
  String get contactsSubtitle =>
      'Il primo (Principale) riceverà il tracking GPS.';

  @override
  String get contactsAddHint => 'Aggiungi numero';

  @override
  String get contactsEmpty =>
      '⚠️ Nessun contatto. L\'allerta non verrà inviata.';

  @override
  String get messageTitle => 'Messaggio Personalizzato';

  @override
  String get messageSubtitle => 'Inviato PRIMA delle coordinate.';

  @override
  String get messageHint => 'Es: Diabetico. Percorso Nord...';

  @override
  String get trackingTitle => 'Monitoraggio GPS';

  @override
  String get trackingSubtitle =>
      'Invia la posizione al contatto Principale ogni X tempo.';

  @override
  String get trackOff => '❌ Disattivato';

  @override
  String get track30 => '⏱️ Ogni 30 min';

  @override
  String get track60 => '⏱️ Ogni ora';

  @override
  String get track120 => '⏱️ Ogni 2 ore';

  @override
  String get inactivityTimeTitle => 'Tempo prima dell\'Allerta';

  @override
  String get inactivityTimeSubtitle =>
      'Quanto tempo senza movimenti prima dell\'allarme?';

  @override
  String get ina30s => '🧪 30 sec (Modalità TEST)';

  @override
  String get ina1h => '⏱️ 1 ora (Consigliato)';

  @override
  String get ina2h => '⏱️ 2 ore (Pausa lunga)';

  @override
  String get testModeWarning => '⚠️ MODO TEST ATTIVO: Allarme tra 30s.';

  @override
  String get toastHoldToSOS => 'Tieni premuto per SOS';

  @override
  String get donateDialogTitle => '💎 Sostieni il Progetto';

  @override
  String get donateDialogBody =>
      'Questa app è un software Libero e Open Source. Se ti aiuta a restare al sicuro, offrici un caffè.';

  @override
  String get donateBtn => 'Dona con PayPal';

  @override
  String get donateClose => 'CHIUDI';

  @override
  String get alertSendingIn => 'Invio allerta tra...';

  @override
  String get alertCancel => 'ANNULLA';

  @override
  String get warningKeepAlive =>
      '⚠️ IMPORTANTE: Non chiudere l\'app trascinandola via (Task Manager). Lasciala in background affinché possa riavviarsi.';

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutDisclaimer => 'Note Legali';

  @override
  String get aboutPrivacy => 'Informativa Privacy';

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
      'Permessi SMS mancanti. L\'app non può inviare allerta.';

  @override
  String get phoneLabel => 'Telefono (es. +39...)';

  @override
  String get btnAdd => 'AGGIUNGI';

  @override
  String get noContacts => 'Nessun contatto configurato.';

  @override
  String get inactivityTitle => 'Tempo di Inattività';

  @override
  String get invalidNumberWarning => 'Numero non valido o troppo corto';

  @override
  String get contactMain => 'Primario (Tracking / Batteria)';

  @override
  String get inactivitySubtitle =>
      'Tempo senza movimento prima di chiedere aiuto.';

  @override
  String get dialogPermissionTitle => 'Come attivare i permessi';

  @override
  String get dialogPermissionStep1 =>
      '1. Tocca \'VAI ALLE IMPOSTAZIONI\' qui sotto.';

  @override
  String get dialogPermissionStep2 =>
      '2. Nella nuova schermata, tocca i 3 puntini (⠇) in alto a derecha.';

  @override
  String get dialogPermissionStep3 =>
      '3. Seleziona \'Consenti impostazioni limitate\' (se visibile).';

  @override
  String get dialogPermissionStep4 => '4. Torna a questa app.';

  @override
  String get btnGoToSettings => 'VAI ALLE IMPOSTAZIONI';

  @override
  String get timerLabel => 'Timer';

  @override
  String get timerSeconds => 'sec';

  @override
  String get permSmsOk => 'Permesso SMS Attivo';

  @override
  String get permSensorsOk => 'Sensori Attivi';

  @override
  String get permNotifOk => 'Notifiche Attive';

  @override
  String get permSmsMissing => 'Permesso SMS Mancante';

  @override
  String get permSensorsMissing => 'Sensori Mancanti';

  @override
  String get permNotifMissing => 'Notifiche Mancanti';

  @override
  String get permOverlayMissing => 'Permesso Overlay Mancante';

  @override
  String get permDialogTitle => 'Permesso Richiesto';

  @override
  String get permSmsHelpTitle => 'Aiuto SMS';

  @override
  String get permGoSettings => 'Vai alle Impostaciones';

  @override
  String get gpsHelpTitle => 'Info sul GPS';

  @override
  String get gpsHelpBody =>
      'La precisione dipende dal chip fisico del telefono e dalla visuale diretta del cielo.\n\nAl chiuso, in garage o in galleria, il segnale satellitare non arriva e la posizione può essere approssimativa o nulla.\n\nOksigenia cercherà sempre di triangolare la migliore posizione possibile.';

  @override
  String get holdToCancel => 'Tieni premuto per annullare';

  @override
  String get statusMonitorStopped => 'Monitoraggio fermato.';

  @override
  String get statusScreenSleep => 'Spegnimento schermo...';

  @override
  String get btnRestartSystem => 'RIAVVIA SISTEMA';

  @override
  String get smsDyingGasp => '⚠️ BATTERIA <5%. Sistema in arresto. Pos:';

  @override
  String get smsHelpMessage => 'AIUTO! Ho bisogno di assistenza urgente.';

  @override
  String get batteryDialogTitle => 'Restrizione Batteria';

  @override
  String get btnDisableBatterySaver => 'DISATTIVA RISPARMIO';

  @override
  String get batteryDialogBody =>
      'Il sistema sta limitando la batteria. Affinché SOS funzioni in background, seleziona \'Nessuna restrizione\' o \'Non ottimizzare\'.';

  @override
  String get permLocMissing => 'Permesso posizione mancante';
}
