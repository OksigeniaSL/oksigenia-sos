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
  String get statusReady => 'Sistema Oksigenia listo.';

  @override
  String get statusConnecting => 'Conectando satélites...';

  @override
  String get statusSent => 'Alerta enviada correctamente.';

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
  String get menuSettings => 'Configuración';

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
  String get settingsHint => 'Ej: 600123456';

  @override
  String get settingsSave => 'GUARDAR';

  @override
  String get settingsSavedMsg => 'Contacto guardado correctamente';

  @override
  String get errorNoContact => '⚠️ ¡Configura un contacto primero!';

  @override
  String get autoModeLabel => 'Detección de Caídas';

  @override
  String get autoModeDescription => 'Monitoriza impactos fuertes.';

  @override
  String get alertFallDetected => '¡IMPACTO DETECTADO!';

  @override
  String get alertFallBody => 'Se ha detectado una caída grave. ¿Estás bien?';

  @override
  String get disclaimerTitle => '⚠️ AVISO LEGAL Y PRIVACIDAD';

  @override
  String get disclaimerText =>
      'Esta aplicación es una herramienta de ayuda y NO sustituye a los servicios de emergencia profesionales (112, 911).\n\nPRIVACIDAD: Oksigenia NO recolecta datos personales. Tu ubicación y contactos se quedan exclusivamente en tu dispositivo.\n\nEl funcionamiento depende del estado del dispositivo, batería y cobertura. Úsala bajo tu propia responsabilidad.';

  @override
  String get btnAccept => 'ACEPTAR';

  @override
  String get btnDecline => 'SALIR';

  @override
  String get menuPrivacy => 'Privacidad y Legal';

  @override
  String get privacyTitle => 'Términos y Privacidad';

  @override
  String get privacyPolicyContent =>
      'POLÍTICA DE PRIVACIDAD Y TÉRMINOS DE USO\n\n1. SIN RECOLECCIÓN DE DATOS\nOksigenia SOS está diseñada bajo el principio de privacidad por diseño. La aplicación funciona de manera totalmente local. No subimos tus datos a ninguna nube, no utilizamos servidores de rastreo, ni vendemos tu información a terceros. Tus contactos de emergencia y tu historial de ubicaciones permanecen estrictamente dentro de tu dispositivo.\n\n2. USO DE PERMISOS\n- Ubicación: Se utiliza estrictamente para obtener las coordenadas GPS en caso de detectar un impacto o activación manual. No se realiza seguimiento en segundo plano cuando la monitorización está desactivada.\n- SMS: Se utiliza exclusivamente para enviar el mensaje de alerta a tu contacto definido. La aplicación no lee tus mensajes personales.\n\n3. LIMITACIÓN DE RESPONSABILIDAD\nEsta aplicación se proporciona \'tal cual\', sin garantías de ningún tipo. Oksigenia y sus desarrolladores no se hacen responsables de daños, lesiones o muertes derivadas de fallos en el funcionamiento del software, incluyendo pero no limitado a: falta de cobertura móvil, agotamiento de batería, fallos del sistema operativo o errores en el hardware GPS.\n\nEsta herramienta es un complemento de seguridad y nunca debe considerarse un sustituto infalible de los servicios de emergencia profesionales.';

  @override
  String get advSettingsTitle => 'Funciones Avanzadas';

  @override
  String get advSettingsSubtitle => 'Multi-contacto, Rastreo GPS...';

  @override
  String get dialogCommunityTitle => '💎 Oksigenia Community';

  @override
  String get dialogCommunityBody =>
      'Esta es la versión COMMUNITY (Libre).\n\nTodas las funciones están desbloqueadas gracias al código abierto.\n\nSi te es útil, considera una donación voluntaria.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody =>
      'Suscríbete a la versión PRO para desbloquear múltiples contactos y seguimiento en tiempo real en nuestros servidores privados.';

  @override
  String get btnDonate => 'Invitar a un café ☕';

  @override
  String get btnSubscribe => 'Suscribirse';

  @override
  String get btnClose => 'Cerrar';
}
