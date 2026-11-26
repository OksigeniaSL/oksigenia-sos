/// Shared pieces of the SMS texts, so the builders in both isolates and the
/// worst-case body used to price an SOS cannot drift apart.
library;

/// Separator between the fields of the technical line. Never "|": in GSM 7-bit
/// it is an extension character worth two septets, and with some note lengths
/// that pushed a part of the concatenated SOS over its limit, so the whole
/// send failed.
const String smsFieldSeparator = ' / ';

/// Minutes to show for a fix that is [ageSeconds] old, or null when the fix is
/// fresh enough to pass as the current position. [stale] forces the label (a
/// last-known position, whatever its timestamp says).
int? smsFixAgeMinutes(int ageSeconds, {bool stale = false}) =>
    (stale || ageSeconds > 90) ? (ageSeconds / 60).round() : null;

/// "Acc: 8m", or "Acc: 8m / 12min" when the fix is old.
String smsFixQuality(double accuracyM, int ageSeconds, {bool stale = false}) {
  final int? minutes = smsFixAgeMinutes(ageSeconds, stale: stale);
  final String acc = 'Acc: ${accuracyM.toStringAsFixed(0)}m';
  return minutes == null ? acc : '$acc$smsFieldSeparator${minutes}min';
}

/// Technical line of an SOS: "Bat: 63% / Alt: 1834m / Acc: 8m[ / 12min]".
String sosTechLine({
  required int batteryPct,
  required double altitudeM,
  required double accuracyM,
  required int fixAgeSeconds,
  bool stale = false,
}) =>
    'Bat: $batteryPct%$smsFieldSeparator'
    'Alt: ${altitudeM.toStringAsFixed(0)}m$smsFieldSeparator'
    '${smsFixQuality(accuracyM, fixAgeSeconds, stale: stale)}';
