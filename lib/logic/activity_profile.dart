/// Activity profiles tune the Smart Sentinel detection to the sport in use.
///
/// Parameter rationale lives in `memory/research_fall_detection.md` — every
/// value here was either validated empirically (Trekking baseline, P7+P8 logs
/// 2026-04-30) or derived from the literature (Bourke 2007 thresholds, Musci
/// 2021 settling windows). Do not edit values without updating that doc.
enum ActivityProfile {
  trekking,
  trailMtb,
  mountaineering,
  paragliding,
  kayak,
  equitation,
  professional,
}

class ActivityProfileConfig {
  /// G-force threshold above which an impact enters the yellow observation
  /// state. Measured in user-acceleration space (gravity removed); resting
  /// value is ~1.0G.
  final double yellowThreshold;

  /// G-force threshold above which an impact is considered catastrophic and
  /// fires the alarm directly, skipping the yellow observation window. The
  /// 30 s pre-alert on AlarmScreen remains the user's last chance to cancel.
  /// Set to 0 to disable orange-direct (alarm only fires after observation).
  final double orangeThreshold;

  /// Seconds after impact during which rhythm checks are ignored — accounts
  /// for tumbling, secondary impacts and failed recovery attempts.
  final int settlingSeconds;

  /// Total observation window before firing the alarm if no rhythm is found.
  final int observationSeconds;

  /// Upper bound for the coefficient of variation of inter-crossing intervals
  /// during rhythm validation. Higher = more permissive (tolerates noisier
  /// gait, e.g. phone in pocket while running on uneven ground).
  final double cvUpperBound;

  /// When false, impact-driven detection is disabled entirely. The user is
  /// only protected by Inactivity Monitor + manual SOS. Required for
  /// activities where impact patterns are uninformative (paragliding, kayak).
  final bool impactDetectionEnabled;

  /// Passive GPS sampling interval. Slower for activities where the user
  /// moves at low speeds (trekking, mountaineering); fast for high-speed
  /// activities where position drifts quickly (paragliding, MTB).
  final int gpsIntervalSeconds;

  /// Distance filter: a new GPS sample is only delivered after the device
  /// has moved this many meters. Larger value = fewer wakeups, less battery.
  final int gpsDistanceFilterMeters;

  const ActivityProfileConfig({
    required this.yellowThreshold,
    required this.orangeThreshold,
    required this.settlingSeconds,
    required this.observationSeconds,
    required this.cvUpperBound,
    required this.impactDetectionEnabled,
    required this.gpsIntervalSeconds,
    required this.gpsDistanceFilterMeters,
  });
}

const Map<ActivityProfile, ActivityProfileConfig> activityProfileConfigs = {
  ActivityProfile.trekking: ActivityProfileConfig(
    yellowThreshold: 6.0,
    orangeThreshold: 10.0,
    settlingSeconds: 5,
    observationSeconds: 60,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
    gpsIntervalSeconds: 30,
    gpsDistanceFilterMeters: 30,
  ),
  ActivityProfile.trailMtb: ActivityProfileConfig(
    yellowThreshold: 8.0,
    orangeThreshold: 13.0,
    settlingSeconds: 5,
    observationSeconds: 60,
    cvUpperBound: 1.50,
    impactDetectionEnabled: true,
    gpsIntervalSeconds: 5,
    gpsDistanceFilterMeters: 10,
  ),
  ActivityProfile.mountaineering: ActivityProfileConfig(
    yellowThreshold: 6.0,
    orangeThreshold: 10.0,
    settlingSeconds: 5,
    observationSeconds: 90,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
    gpsIntervalSeconds: 30,
    gpsDistanceFilterMeters: 30,
  ),
  ActivityProfile.paragliding: ActivityProfileConfig(
    yellowThreshold: 0,
    orangeThreshold: 0,
    settlingSeconds: 0,
    observationSeconds: 0,
    cvUpperBound: 0,
    impactDetectionEnabled: false,
    gpsIntervalSeconds: 2,
    gpsDistanceFilterMeters: 5,
  ),
  ActivityProfile.kayak: ActivityProfileConfig(
    yellowThreshold: 0,
    orangeThreshold: 0,
    settlingSeconds: 0,
    observationSeconds: 0,
    cvUpperBound: 0,
    impactDetectionEnabled: false,
    gpsIntervalSeconds: 15,
    gpsDistanceFilterMeters: 20,
  ),
  // Horse cadence (trot ~1.5Hz, canter 2-3Hz) interferes with the human-walk
  // cadence-CV detector. Without empirical data on phone-in-pocket while
  // riding, impact detection is disabled (Paragliding/Kayak approach).
  // Inactivity Monitor + manual SOS remain. Revisit with field data.
  ActivityProfile.equitation: ActivityProfileConfig(
    yellowThreshold: 0,
    orangeThreshold: 0,
    settlingSeconds: 0,
    observationSeconds: 0,
    cvUpperBound: 0,
    impactDetectionEnabled: false,
    gpsIntervalSeconds: 15,
    gpsDistanceFilterMeters: 20,
  ),
  ActivityProfile.professional: ActivityProfileConfig(
    yellowThreshold: 6.0,
    orangeThreshold: 10.0,
    settlingSeconds: 5,
    observationSeconds: 120,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
    gpsIntervalSeconds: 5,
    gpsDistanceFilterMeters: 10,
  ),
};

ActivityProfile activityProfileFromName(String? name) {
  if (name == null) return ActivityProfile.trekking;
  for (final p in ActivityProfile.values) {
    if (p.name == name) return p;
  }
  return ActivityProfile.trekking;
}
