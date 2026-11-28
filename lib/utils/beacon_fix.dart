/// Quality rules of the Smart Beacon: which fixes it may act on, and when a
/// move away from the last reported point is real.
///
/// The beacon used to compare a single fix with the last reported point and
/// text every contact when they were 300 m apart, whatever the fix's accuracy
/// or age. A first fix from the network can be hundreds of metres off: one of
/// those sent a wrong "new location", became the reference, and the next good
/// fix "moved" back, up to twenty times.
library;

import 'dart:math';

/// Worst accuracy radius, in metres, of a fix the beacon acts on.
const double beaconMaxAccuracyM = 100.0;

/// Oldest fix, in seconds, the beacon acts on.
const int beaconMaxFixAgeSeconds = 60;

/// True for a fix that is accurate and recent enough to decide with. An
/// accuracy of 0 means the provider gave none: not usable.
bool beaconFixUsable({required double accuracyM, required int ageSeconds}) =>
    accuracyM > 0 &&
    accuracyM <= beaconMaxAccuracyM &&
    ageSeconds < beaconMaxFixAgeSeconds;

/// Great-circle distance in metres (haversine, mean Earth radius).
double metersBetween(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371000.0;
  double rad(double d) => d * pi / 180.0;
  final double dLat = rad(lat2 - lat1);
  final double dLon = rad(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(min(1.0, sqrt(a)));
}

enum BeaconMove {
  /// Not enough usable fixes yet.
  undecided,

  /// A usable fix puts the phone within the threshold: no update to send.
  still,

  /// Two usable fixes in a row, the second newer, both beyond the threshold.
  moved,
}

/// Feeds on the fixes of one probe and decides whether the phone really is
/// [thresholdM] or more from the last reported point ([refLat], [refLon]).
///
/// One fix beyond the threshold only opens the question; a second, newer one
/// must agree. A usable fix inside the threshold closes it at once: if the
/// first was an outlier, the beacon stays quiet.
class BeaconMoveCheck {
  BeaconMoveCheck({
    required this.refLat,
    required this.refLon,
    required this.thresholdM,
  });

  final double refLat;
  final double refLon;
  final double thresholdM;

  BeaconMove _result = BeaconMove.undecided;
  DateTime? _candidateTime;
  double _candidateDistanceM = 0;

  BeaconMove get result => _result;

  /// Distance of the first fix that went beyond the threshold, or 0 if none
  /// did. Kept for the log when no second fix confirmed it.
  double get candidateDistanceM => _candidateDistanceM;

  /// Distance from the reference of the fix that settled the question.
  double distanceM = 0;

  /// Takes one fix. [time] is the fix's own timestamp, [now] the current time.
  BeaconMove add({
    required double lat,
    required double lon,
    required double accuracyM,
    required DateTime time,
    required DateTime now,
  }) {
    if (_result != BeaconMove.undecided) return _result;
    if (!beaconFixUsable(
        accuracyM: accuracyM, ageSeconds: now.difference(time).inSeconds)) {
      return _result;
    }
    final double d = metersBetween(refLat, refLon, lat, lon);
    if (d < thresholdM) {
      distanceM = d;
      return _result = BeaconMove.still;
    }
    if (_candidateTime == null) {
      _candidateTime = time;
      _candidateDistanceM = d;
      return _result;
    }
    // The same fix delivered twice confirms nothing.
    if (!time.isAfter(_candidateTime!)) return _result;
    distanceM = d;
    return _result = BeaconMove.moved;
  }
}
