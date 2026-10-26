import 'package:oksigenia_sms/oksigenia_sms.dart';

import 'geo_links.dart';

/// First line of every SOS SMS. The SOS builders in background_service.dart
/// and sos_logic.dart use it, and so does [worstCaseSosBody].
const String sosSmsHeader = 'SOS OKSIGENIA';

/// The longest SOS body the builders can produce for [note]: worst-case
/// coordinates, altitude, accuracy and fix age. Lets the app price an SOS in
/// SMS parts before any GPS fix exists. Keep it in step with the builders.
String worstCaseSosBody(String note) =>
    '$sosSmsHeader\n$note\n${geoLinks(-89.999999, -179.999999)}'
    '\nBat: 100% | Alt: -9999m | Acc: 9999m | 999min';

/// How one SOS fits Android's per-app SMS rate limit (issue #13).
///
/// Past the limit, Android holds every further SMS part behind a system
/// "Allow / Deny" dialog with no timeout, so with nobody there to confirm, the
/// rest of the SOS never leaves the phone.
class SmsBudget {
  final int contacts;
  final int partsPerContact;
  final OksigeniaSmsRateLimit limit;

  const SmsBudget({
    required this.contacts,
    required this.partsPerContact,
    required this.limit,
  });

  /// SMS parts one SOS sends: every contact gets the whole message.
  int get needed => contacts * partsPerContact;

  /// True if the whole SOS goes out without a confirmation dialog.
  bool get ok => limit.allows(needed);
}

/// Prices an SOS for [contacts] recipients with [note], or returns null if the
/// platform can't tell (the app then assumes the SOS fits).
Future<SmsBudget?> sosSmsBudget({
  required int contacts,
  required String note,
}) async {
  try {
    final limit = await OksigeniaSms.rateLimit();
    final parts = await OksigeniaSms.partCount(worstCaseSosBody(note));
    return SmsBudget(contacts: contacts, partsPerContact: parts, limit: limit);
  } catch (_) {
    return null;
  }
}
