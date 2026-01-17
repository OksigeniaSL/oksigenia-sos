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
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTA OKSIGENIA* 🆘\n\nNecesito ayuda urgente.\n📍 Ubicación: $link\n\nRespira > Inspira > Crece;';
  }
}
