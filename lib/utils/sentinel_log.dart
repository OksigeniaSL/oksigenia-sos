/// sentinel.log lives in external app storage so it can be pulled from a
/// release build, and users paste it into public issues: it must not grow
/// without limit and must not carry contact numbers or exact positions.
library;

import 'dart:io';

/// Size at which sentinel.log is rotated. One older file is kept as
/// `sentinel.log.1`, so the log never takes more than about twice this.
const int sentinelLogMaxBytes = 2 * 1024 * 1024;

// A "+" and at least seven digits, written together or in groups.
final RegExp _plusPhone = RegExp(r'\+\d(?:[ \-]?\d){6,}');
// Nine or more digits in a row with no "+": a national number.
final RegExp _barePhone = RegExp(r'(?<![\d.,+])\d{9,}(?![\d.])');
// Any number with more than three decimals (a coordinate, in practice).
final RegExp _longDecimals = RegExp(r'(\d\.\d{3})\d+');

/// [number] with its middle hidden: `+34600111222` → `+34•••222`.
String maskPhone(String number) {
  final String compact = number.replaceAll(RegExp(r'[^\d+]'), '');
  if (compact.length < 7) return '•••';
  return '${compact.substring(0, 3)}•••${compact.substring(compact.length - 3)}';
}

/// A position for a log line: three decimals, about 100 m. Enough to tell
/// whether a fix moved, not enough to point at a door.
String logPosition(double lat, double lon) =>
    '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';

/// [line] safe to write: whatever a caller or an exception text put in it,
/// phone numbers leave masked and long decimals leave cut to three places.
String scrubLogLine(String line) => line
    .replaceAllMapped(_plusPhone, (m) => maskPhone(m[0]!))
    .replaceAllMapped(_barePhone, (m) => maskPhone(m[0]!))
    .replaceAllMapped(_longDecimals, (m) => m[1]!);

/// Appends [line] to [file]. Once the file reaches [maxBytes] it becomes
/// `<file>.1`, replacing the previous one, and a new file starts.
Future<void> appendToRotatingLog(File file, String line,
    {int maxBytes = sentinelLogMaxBytes}) async {
  try {
    if (await file.exists() && await file.length() >= maxBytes) {
      final File older = File('${file.path}.1');
      if (await older.exists()) await older.delete();
      await file.rename(older.path);
    }
  } catch (_) {
    // A failed rotation must never cost the line that follows.
  }
  await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
}
