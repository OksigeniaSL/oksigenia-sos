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
  String get statusLocationFixed => 'LOCALISATION FIXE';

  @override
  String get statusSent => 'Alerte envoyée avec succès.';

  @override
  String statusError(Object error) {
    return 'ERREUR: $error';
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
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTE OKSIGENIA* 🆘\n\nJ\'ai besoin d\'aide.\n📍 Localisation: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Réglages SOS';

  @override
  String get settingsLabel => 'Numéro d\'urgence';

  @override
  String get settingsHint => 'Ex: +33 600 123 456';

  @override
  String get settingsSave => 'SAUVEGARDER';

  @override
  String get settingsSavedMsg => 'Contact enregistré';

  @override
  String get errorNoContact => '⚠️ Configurez un contact d\'abord !';

  @override
  String get autoModeLabel => 'Détection de Chute';

  @override
  String get autoModeDescription => 'Surveille les impacts sévères.';

  @override
  String get inactivityModeLabel => 'Moniteur d\'Inactivité';

  @override
  String get inactivityModeDescription => 'Alerte si aucun mouvement détecté.';

  @override
  String get alertFallDetected => 'IMPACT DÉTECTÉ !';

  @override
  String get alertFallBody => 'Chute sévère détectée. Ça va ?';

  @override
  String get alertInactivityDetected => 'INACTIVITÉ DÉTECTÉE !';

  @override
  String get alertInactivityBody => 'Aucun mouvement. Ça va ?';

  @override
  String get btnImOkay => 'JE VAIS BIEN';

  @override
  String get disclaimerTitle => '⚠️ AVIS LÉGAL & CONFIDENTIALITÉ';

  @override
  String get disclaimerText =>
      'Oksigenia SOS est un outil de support, pas un substitut aux urgences pro. Dépend de la batterie, GPS et réseau mobile.\n\nVous acceptez d\'utiliser le logiciel \'tel quel\' à vos propres risques.';

  @override
  String get btnAccept => 'J\'ACCEPTE LE RISQUE';

  @override
  String get btnDecline => 'QUITTER';

  @override
  String get menuPrivacy => 'Privacité & Légal';

  @override
  String get privacyTitle => 'Termes & Confidentialité';

  @override
  String get privacyPolicyContent =>
      'POLITIQUE DE CONFIDENTIALITÉ\n\n1. PAS DE COLLECTE\nOpération 100% locale.\n\n2. PERMISSIONS\n- GPS: Pour l\'alerte.\n- SMS: Pour l\'envoi de secours.\n\n3. RESPONSABILITÉ\nLogiciel fourni sans garantie.';

  @override
  String get advSettingsTitle => 'Fonctions Avancées';

  @override
  String get advSettingsSubtitle => 'Multi-contact, Tracking GPS...';

  @override
  String get dialogCommunityTitle => '💎 Communauté Oksigenia';

  @override
  String get dialogCommunityBody =>
      'Version COMMUNITY (Gratuite).\n\nOpen Source.\n\nConsidérez un don si utile.';

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
}
