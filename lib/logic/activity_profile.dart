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
  professional,
}

class ActivityProfileConfig {
  /// G-force threshold above which an impact enters the yellow observation
  /// state. Measured in user-acceleration space (gravity removed); resting
  /// value is ~1.0G.
  final double yellowThreshold;

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

  const ActivityProfileConfig({
    required this.yellowThreshold,
    required this.settlingSeconds,
    required this.observationSeconds,
    required this.cvUpperBound,
    required this.impactDetectionEnabled,
  });
}

const Map<ActivityProfile, ActivityProfileConfig> activityProfileConfigs = {
  ActivityProfile.trekking: ActivityProfileConfig(
    yellowThreshold: 6.0,
    settlingSeconds: 5,
    observationSeconds: 60,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
  ),
  ActivityProfile.trailMtb: ActivityProfileConfig(
    yellowThreshold: 8.0,
    settlingSeconds: 5,
    observationSeconds: 60,
    cvUpperBound: 1.50,
    impactDetectionEnabled: true,
  ),
  ActivityProfile.mountaineering: ActivityProfileConfig(
    yellowThreshold: 6.0,
    settlingSeconds: 5,
    observationSeconds: 90,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
  ),
  ActivityProfile.paragliding: ActivityProfileConfig(
    yellowThreshold: 0,
    settlingSeconds: 0,
    observationSeconds: 0,
    cvUpperBound: 0,
    impactDetectionEnabled: false,
  ),
  ActivityProfile.kayak: ActivityProfileConfig(
    yellowThreshold: 0,
    settlingSeconds: 0,
    observationSeconds: 0,
    cvUpperBound: 0,
    impactDetectionEnabled: false,
  ),
  ActivityProfile.professional: ActivityProfileConfig(
    yellowThreshold: 6.0,
    settlingSeconds: 5,
    observationSeconds: 120,
    cvUpperBound: 1.30,
    impactDetectionEnabled: true,
  ),
};

ActivityProfile activityProfileFromName(String? name) {
  if (name == null) return ActivityProfile.trekking;
  for (final p in ActivityProfile.values) {
    if (p.name == name) return p;
  }
  return ActivityProfile.trekking;
}
