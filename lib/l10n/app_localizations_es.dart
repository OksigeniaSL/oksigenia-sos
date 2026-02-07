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
  String get menuPrivacy => 'Privacidad y Legal';

  @override
  String get menuDonate => 'Donar';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTA OKSIGENIA* 🆘\n\nNecesito ayuda urgente.\n📍 Ubicación: $link';
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
      'Oksigenia SOS es una herramienta de apoyo, no un sustituto de los servicios de emergencia profesionales. Su funcionamiento depende de factores externos: batería, señal GPS y cobertura móvil.\n\nAl activar esta aplicación, usted acepta que el software se proporciona \'tal cual\' y libera a los desarrolladores de responsabilidad legal por fallos técnicos. Usted es responsable de su propia seguridad.\n\nCostes de SMS: Todos los costes de mensajería son responsabilidad del usuario según las tarifas de su operador móvil. Oksigenia no cubre ni cobra por estos mensajes.';

  @override
  String get btnAccept => 'ACEPTO EL RIESGO';

  @override
  String get btnDecline => 'SALIR';

  @override
  String get privacyTitle => 'Términos y Privacidad';

  @override
  String get privacyPolicyContent =>
      'POLÍTICA DE PRIVACIDAD Y TÉRMINOS\n\n1. SIN RECOLECCIÓN DE DATOS\nOksigenia SOS funciona localmente. No subimos datos a la nube ni vendemos tu información.\n\n2. PERMISOS\n- Ubicación: Para coordenadas en caso de alerta.\n- SMS: Exclusivamente para enviar el mensaje de socorro.\n\n3. LIMITACIÓN DE RESPONSABILIDAD\nApp entregada \'tal cual\'. No nos hacemos responsables por fallos de cobertura o hardware.';

  @override
  String get advSettingsTitle => 'Funciones Avanzadas';

  @override
  String get advSettingsSubtitle => 'Multi-contacto, Rastreo GPS...';

  @override
  String get dialogCommunityTitle => '💎 Comunidad Oksigenia';

  @override
  String get dialogCommunityBody =>
      'Esta es la versión COMMUNITY (Gratis).\n\nTodas las funciones están desbloqueadas gracias al código abierto.';

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

  @override
  String get permSmsTitle => '¡PELIGRO! Permiso SMS bloqueado';

  @override
  String get permSmsBody =>
      'La app NO podrá enviar alertas aunque tengas contactos.';

  @override
  String get permSmsButton => 'Activar SMS en Ajustes';

  @override
  String get restrictedSettingsTitle => 'Ajustes Restringidos';

  @override
  String get restrictedSettingsBody =>
      'Android ha restringido este permiso porque la aplicación se instaló manualmente (side-loaded).';

  @override
  String get contactsTitle => 'Contactos de Emergencia';

  @override
  String get contactsSubtitle => 'El primero recibirá el seguimiento GPS.';

  @override
  String get contactsAddHint => 'Nuevo número';

  @override
  String get contactsEmpty => '⚠️ Sin contactos. La alerta no saldrá.';

  @override
  String get messageTitle => 'Mensaje Personalizado';

  @override
  String get messageSubtitle => 'Se enviará ANTES de las coordenadas.';

  @override
  String get messageHint => 'Ej: Soy diabético. Ruta Norte...';

  @override
  String get trackingTitle => 'Seguimiento GPS';

  @override
  String get trackingSubtitle => 'Envía posición al Principal cada X tiempo.';

  @override
  String get trackOff => '❌ Desactivado';

  @override
  String get track30 => '⏱️ Cada 30 min';

  @override
  String get track60 => '⏱️ Cada 1 hora';

  @override
  String get track120 => '⏱️ Cada 2 horas';

  @override
  String get inactivityTimeTitle => 'Tiempo para Alerta';

  @override
  String get inactivityTimeSubtitle =>
      '¿Cuánto tiempo sin moverte antes de avisar?';

  @override
  String get ina30s => '🧪 30 seg (Modo TEST)';

  @override
  String get ina1h => '⏱️ 1 hora (Recomendado)';

  @override
  String get ina2h => '⏱️ 2 horas (Pausa larga)';

  @override
  String get testModeWarning => 'MODO TEST: La alerta saltará en 30s.';

  @override
  String get toastHoldToSOS => 'Mantén pulsado para SOS';

  @override
  String get donateDialogTitle => '💎 Apoya el Proyecto';

  @override
  String get donateDialogBody =>
      'Esta app es Software Libre y Gratuito. Si te da seguridad, invítanos a un café para mantener los servidores.';

  @override
  String get donateBtn => 'Donar con PayPal';

  @override
  String get donateClose => 'CERRAR';

  @override
  String get alertSendingIn => 'Enviando alerta en...';

  @override
  String get alertCancel => 'CANCELAR';

  @override
  String get warningKeepAlive =>
      '⚠️ IMPORTANTE: No cierres la app deslizando (Multitarea). Déjala en 2º plano para que reinicie sola si apagas el móvil.';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutDisclaimer => 'Aviso Legal';

  @override
  String get aboutPrivacy => 'Política de Privacidad';

  @override
  String get aboutSourceCode => 'Código Fuente (GitHub)';

  @override
  String get aboutLicenses => 'Licencias de Software';

  @override
  String get aboutDevelopedBy => 'Desarrollado con ❤️ por Oksigenia';

  @override
  String get dialogClose => 'Cerrar';

  @override
  String get permSmsText =>
      'Faltan permisos de SMS. La app no podrá enviar alertas.';

  @override
  String get phoneLabel => 'Teléfono (ej: +34...)';

  @override
  String get btnAdd => 'AÑADIR';

  @override
  String get noContacts => 'No hay contactos configurados.';

  @override
  String get inactivityTitle => 'Tiempo de Inactividad';

  @override
  String get invalidNumberWarning => 'Número inválido o muy corto';

  @override
  String get contactMain => 'Principal (Tracking / Batería)';

  @override
  String get inactivitySubtitle =>
      'Tiempo sin movimiento antes de pedir ayuda.';

  @override
  String get dialogPermissionTitle => 'Cómo activar el permiso';

  @override
  String get dialogPermissionStep1 => '1. Toca \'IR A AJUSTES\' abajo.';

  @override
  String get dialogPermissionStep2 =>
      '2. En la nueva pantalla, toca los 3 puntos (⠇) arriba a la derecha.';

  @override
  String get dialogPermissionStep3 =>
      '3. Selecciona \'Permitir ajustes restringidos\' (si aparece).';

  @override
  String get dialogPermissionStep4 => '4. Vuelve a esta app.';

  @override
  String get btnGoToSettings => 'IR A AJUSTES';

  @override
  String get timerLabel => 'Temporizador';

  @override
  String get timerSeconds => 'seg';

  @override
  String get permSmsOk => 'Permiso SMS activo';

  @override
  String get permSensorsOk => 'Sensores activos';

  @override
  String get permNotifOk => 'Notificaciones activas';

  @override
  String get permSmsMissing => 'Falta permiso SMS';

  @override
  String get permSensorsMissing => 'Faltan sensores';

  @override
  String get permNotifMissing => 'Faltan notificaciones';

  @override
  String get permOverlayMissing => 'Falta permiso superposición';

  @override
  String get permDialogTitle => 'Permiso Requerido';

  @override
  String get permSmsHelpTitle => 'Ayuda SMS';

  @override
  String get permGoSettings => 'Ir a Ajustes';

  @override
  String get gpsHelpTitle => 'Sobre el GPS';

  @override
  String get gpsHelpBody =>
      'La precisión depende del chip físico de tu móvil y de tener visión directa del cielo.\n\nEn interiores, garajes o túneles, la señal de los satélites no entra y la ubicación puede ser aproximada o nula.\n\nOksigenia siempre intentará triangular la mejor posición posible.';

  @override
  String get holdToCancel => 'Mantén pulsado para cancelar';

  @override
  String get statusMonitorStopped => 'Monitor detenido.';

  @override
  String get statusScreenSleep => 'Apagando pantalla...';

  @override
  String get btnRestartSystem => 'REINICIAR SISTEMA';

  @override
  String get smsDyingGasp => '⚠️ BATERÍA <5%. Me apago. Loc:';

  @override
  String get smsHelpMessage => '¡AYUDA! Necesito asistencia.';

  @override
  String get batteryDialogTitle => 'Restricción de Batería';

  @override
  String get btnDisableBatterySaver => 'DESACTIVAR AHORRO';

  @override
  String get batteryDialogBody =>
      'El sistema está restringiendo la batería de esta app. Para que SOS funcione en segundo plano, debes seleccionar \'Sin Restricciones\' o \'No Optimizar\'.';

  @override
  String get permLocMissing => 'Falta Permiso de Ubicación';

  @override
  String get slideStopSystem => 'DESLIZA PARA APAGAR';
}
