// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Système Oksigenia Prêt.';

  @override
  String get statusConnecting => 'Connexion satellites...';

  @override
  String get statusLocationFixed => 'POSITION FIXÉE';

  @override
  String get statusSent => 'Alerte envoyée avec succès.';

  @override
  String statusError(Object error) {
    return 'ERREUR : $error';
  }

  @override
  String get menuWeb => 'Site Officiel';

  @override
  String get menuSupport => 'Support Technique';

  @override
  String get menuLanguages => 'Langue';

  @override
  String get menuSettings => 'Paramètres';

  @override
  String get menuPrivacy => 'Confidentialité et Légal';

  @override
  String get menuDonate => 'Donar / Donate';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTE OKSIGENIA* 🆘\n\nBesoin d\'aide urgente.\n📍 Position : $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Configuration SOS';

  @override
  String get settingsLabel => 'Téléphone d\'Urgence';

  @override
  String get settingsHint => 'Ex : +33 6 12 34 56 78';

  @override
  String get settingsSave => 'ENREGISTRER';

  @override
  String get settingsSavedMsg => 'Contact enregistré correctement';

  @override
  String get errorNoContact => '⚠️ Configurez d\'abord un contact !';

  @override
  String get autoModeLabel => 'Détection de Chute';

  @override
  String get autoModeDescription => 'Surveille les impacts sévères.';

  @override
  String get inactivityModeLabel => 'Moniteur d\'Inactivité';

  @override
  String get inactivityModeDescription =>
      'Alerte si aucun mouvement n\'est détecté.';

  @override
  String get alertFallDetected => 'IMPACT DÉTECTÉ !';

  @override
  String get alertFallBody => 'Chute sévère détectée. Ça va ?';

  @override
  String get alertInactivityDetected => 'INACTIVITÉ DÉTECTÉE !';

  @override
  String get alertInactivityBody => 'Aucun mouvement détecté. Ça va ?';

  @override
  String get btnImOkay => 'JE VAIS BIEN';

  @override
  String get disclaimerTitle => '⚠️ AVIS JURIDIQUE ET CONFIDENTIALITÉ';

  @override
  String get disclaimerText =>
      'Oksigenia SOS est un outil de soutien, pas un substitut aux services d\'urgence professionnels.';

  @override
  String get btnAccept => 'J\'ACCEPTE LE RISQUE';

  @override
  String get btnDecline => 'QUITTER';

  @override
  String get privacyTitle => 'Conditions et Confidentialité';

  @override
  String get privacyPolicyContent => 'POLÍTICA DE PRIVACIDAD Y TÉRMINOS';

  @override
  String get advSettingsTitle => 'Fonctions Avancées';

  @override
  String get advSettingsSubtitle => 'Multi-contacts, Suivi GPS...';

  @override
  String get dialogCommunityTitle => '💎 Communauté Oksigenia';

  @override
  String get dialogCommunityBody => 'Version COMMUNITY (Gratuit).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abonnez-vous à PRO pour le suivi en temps réel.';

  @override
  String get btnDonate => 'Offrez-moi un café ☕';

  @override
  String get btnSubscribe => 'S\'abonner';

  @override
  String get btnClose => 'Fermer';

  @override
  String get permSmsTitle => 'DANGER ! Permission SMS bloquée';

  @override
  String get permSmsBody => 'L\'app NE PEUT PAS envoyer d\'alertes.';

  @override
  String get permSmsButton => 'Activer SMS';

  @override
  String get restrictedSettingsTitle => 'Paramètres Restreints';

  @override
  String get restrictedSettingsBody =>
      'Android a restreint cette autorisation.';

  @override
  String get btnGoToSettings => 'PARAMÈTRES';

  @override
  String get contactsTitle => 'Contacts d\'Urgence';

  @override
  String get contactsSubtitle => 'Le premier reçoit le suivi GPS.';

  @override
  String get contactsAddHint => 'Nouveau numéro';

  @override
  String get contactsEmpty => '⚠️ Aucun contact.';

  @override
  String get messageTitle => 'Message Personnalisé';

  @override
  String get messageSubtitle => 'Envoyé AVANT les coordonnées.';

  @override
  String get messageHint => 'Ex : Diabétique. Route Nord...';

  @override
  String get trackingTitle => 'Suivi GPS';

  @override
  String get trackingSubtitle => 'Envoie la position à intervalles.';

  @override
  String get trackOff => '❌ Désactivé';

  @override
  String get track30 => '⏱️ Toutes les 30 min';

  @override
  String get track60 => '⏱️ Toutes les 1 h';

  @override
  String get track120 => '⏱️ Toutes les 2 h';

  @override
  String get contactMain => 'Principal';

  @override
  String get inactivityTimeTitle => 'Délai avant Alerte';

  @override
  String get inactivityTimeSubtitle => 'Temps sans mouvement ?';

  @override
  String get ina30s => '🧪 30 sec';

  @override
  String get ina1h => '⏱️ 1 heure';

  @override
  String get ina2h => '⏱️ 2 heures';

  @override
  String get testModeWarning => '⚠️ MODE TEST ACTIVÉ : 30s.';

  @override
  String get toastHoldToSOS => 'Maintenez pour SOS';

  @override
  String get donateDialogTitle => '💎 Soutenez-nous';

  @override
  String get donateDialogBody => 'Offrez-nous un café.';

  @override
  String get donateBtn => 'Faire un don PayPal';

  @override
  String get donateClose => 'FERMER';
}
