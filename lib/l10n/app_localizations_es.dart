// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Sistema Oksigenia Listo.';

  @override
  String get statusConnecting => 'Conectando satélites...';

  @override
  String get statusLocationFixed => 'UBICACIÓN FIJADA';

  @override
  String get statusSent => 'Alerta enviada con éxito.';

  @override
  String statusError(Object error) {
    return 'ERROR: $error';
  }

  @override
  String get menuWeb => 'Web Oficial';

  @override
  String get menuSupport => 'Soporte Técnico';

  @override
  String get menuLanguages => 'Idioma';

  @override
  String get menuSettings => 'Ajustes';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTA OKSIGENIA* 🆘\n\nNecesito ayuda urgente.\n📍 Ubicación: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Configuración SOS';

  @override
  String get settingsLabel => 'Teléfono de Emergencia';

  @override
  String get settingsHint => 'Ej: +34 600 123 456';

  @override
  String get settingsSave => 'GUARDAR';

  @override
  String get settingsSavedMsg => 'Contacto guardado correctamente';

  @override
  String get errorNoContact => '⚠️ ¡Configura un contacto primero!';

  @override
  String get autoModeLabel => 'Detección de Caídas';

  @override
  String get autoModeDescription => 'Monitoriza impactos severos.';

  @override
  String get inactivityModeLabel => 'Monitor de Inactividad';

  @override
  String get inactivityModeDescription => 'Alerta si no se detecta movimiento.';

  @override
  String get alertFallDetected => '¡IMPACTO DETECTADO!';

  @override
  String get alertFallBody => 'Caída severa detectada. ¿Estás bien?';

  @override
  String get alertInactivityDetected => '¡INACTIVIDAD DETECTADA!';

  @override
  String get alertInactivityBody => 'Sin movimiento detectado. ¿Estás bien?';

  @override
  String get btnImOkay => 'ESTOY BIEN';

  @override
  String get disclaimerTitle => '⚠️ AVISO LEGAL Y PRIVACIDAD';

  @override
  String get disclaimerText =>
      'Oksigenia SOS es una herramienta de apoyo, no un sustituto de servicios de emergencia profesionales. Su operación depende de factores externos: batería, señal GPS y cobertura móvil.\n\nAl activar esta app, aceptas que el software se entrega \'tal cual\' y liberas a los desarrolladores de responsabilidad legal por fallos técnicos. Eres responsable de tu propia seguridad.';

  @override
  String get btnAccept => 'ACEPTO EL RIESGO';

  @override
  String get btnDecline => 'SALIR';

  @override
  String get menuPrivacy => 'Privacidad y Legal';

  @override
  String get privacyTitle => 'Términos y Privacidad';

  @override
  String get privacyPolicyContent =>
      'POLÍTICA DE PRIVACIDAD Y TÉRMINOS\n\n1. SIN RECOPILACIÓN DE DATOS\nOksigenia SOS opera localmente. No subimos datos a la nube ni vendemos tu información.\n\n2. PERMISOS\n- Ubicación: Para coordenadas en caso de alerta.\n- SMS: Exclusivamente para enviar el mensaje de socorro.\n\n3. LIMITACIÓN DE RESPONSABILIDAD\nApp entregada \'tal cual\'. No nos hacemos responsables por fallos de cobertura o hardware.';

  @override
  String get advSettingsTitle => 'Funciones Avanzadas';

  @override
  String get advSettingsSubtitle => 'Multi-contacto, Rastreo GPS...';

  @override
  String get dialogCommunityTitle => '💎 Comunidad Oksigenia';

  @override
  String get dialogCommunityBody =>
      'Esta es la versión COMMUNITY (Gratis).\n\nTodas las funciones están desbloqueadas gracias al código abierto.\n\nSi te es útil, considera una donación voluntaria.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Suscríbete a PRO para desbloquear múltiples contactos y rastreo en tiempo real.';

  @override
  String get btnDonate => 'Invítame a un café ☕';

  @override
  String get btnSubscribe => 'Suscribirse';

  @override
  String get btnClose => 'Cerrar';
}
