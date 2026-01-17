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
  String get statusReady => 'Système Oksigenia prêt.';

  @override
  String get statusConnecting => 'Connexion aux satellites...';

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
    return '🆘 *ALERTE OKSIGENIA* 🆘\n\nJ\'ai besoin d\'une aide urgente.\n📍 Localisation: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Paramètres SOS';

  @override
  String get settingsLabel => 'Téléphone d\'urgence';

  @override
  String get settingsHint => 'Ex: +33 6 12 34 56 78';

  @override
  String get settingsSave => 'ENREGISTRER';

  @override
  String get settingsSavedMsg => 'Contact enregistré avec succès';

  @override
  String get errorNoContact => '⚠️ Configurez d\'abord un contact !';

  @override
  String get autoModeLabel => 'Détection de Chute';

  @override
  String get autoModeDescription => 'Surveille les impacts violents.';

  @override
  String get alertFallDetected => 'IMPACT DÉTECTÉ !';

  @override
  String get alertFallBody => 'Chute grave détectée. Ça va ?';

  @override
  String get disclaimerTitle => '⚠️ AVERTISSEMENT LEGAL & CONFIDENTIALITÉ';

  @override
  String get disclaimerText =>
      'Cette application est un outil d\'aide et NE REMPLACE PAS les services d\'urgence professionnels (112, 911).\n\nCONFIDENTIALITÉ : Oksigenia NE collecte AUCUNE donnée personnelle. Votre localisation et vos contacts restent exclusivement sur votre appareil.\n\nLe fonctionnement dépend de l\'état de l\'appareil, de la batterie et de la couverture. À utiliser à vos propres risques.';

  @override
  String get btnAccept => 'ACCEPTER';

  @override
  String get btnDecline => 'QUITTER';

  @override
  String get menuPrivacy => 'Confidentialité et Légal';

  @override
  String get privacyTitle => 'Conditions et Confidentialité';

  @override
  String get privacyPolicyContent =>
      'POLITIQUE DE CONFIDENTIALITÉ ET CONDITIONS D\'UTILISATION\n\n1. AUCUNE COLLECTE DE DONNÉES\nOksigenia SOS est conçue selon le principe de confidentialité par défaut. L\'application fonctionne entièrement localement. Nous ne téléchargeons pas vos données dans le cloud, n\'utilisons pas de serveurs de suivi et ne vendons pas vos informations. Vos contacts d\'urgence restent strictement sur votre appareil.\n\n2. UTILISATION DES PERMISSIONS\n- Localisation : Utilisée strictement pour obtenir les coordonnées GPS en cas d\'impact ou d\'activation manuelle. Aucun suivi en arrière-plan n\'est effectué lorsque la surveillance est désactivée.\n- SMS : Utilisé exclusivement pour envoyer le message d\'alerte à votre contact défini. L\'application ne lit pas vos messages personnels.\n\n3. LIMITATION DE RESPONSABILITÉ\nCette application est fournie \'telle quelle\', sans garantie d\'aucune sorte. Oksigenia et ses développeurs ne sont pas responsables des dommages ou conséquences résultant d\'une défaillance du logiciel, y compris : absence de couverture mobile, batterie déchargée ou erreurs GPS.\n\nCet outil est un complément de sécurité et ne doit jamais être considéré comme un substitut infaillible aux secours professionnels.';

  @override
  String get advSettingsTitle => 'Fonctionnalités Avancées';

  @override
  String get advSettingsSubtitle => 'Multi-contact, Suivi GPS...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'Ceci est la version COMMUNITY (Gratuite).\n\nToutes les fonctionnalités sont débloquées grâce à l\'open source.\n\nSi elle vous est utile, envisagez un don volontaire.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Abonnez-vous à la version PRO pour débloquer plusieurs contacts et le suivi en temps réel sur nos serveurs privés.';

  @override
  String get btnDonate => 'Offrez-moi un café ☕';

  @override
  String get btnSubscribe => 'S\'abonner';

  @override
  String get btnClose => 'Fermer';
}
