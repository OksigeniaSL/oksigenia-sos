// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Oksigenia System Ready.';

  @override
  String get statusConnecting => 'Connecting satellites...';

  @override
  String get statusSent => 'Alert sent successfully.';

  @override
  String statusError(Object error) {
    return 'ERROR: $error';
  }

  @override
  String get menuWeb => 'Official Website';

  @override
  String get menuSupport => 'Tech Support';

  @override
  String get menuLanguages => 'Language';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *OKSIGENIA ALERT* 🆘\n\nI need urgent help.\n📍 Location: $link\n\nRespira > Inspira > Crece;';
  }
}
