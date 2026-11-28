/// Timing rules of the inactivity backstop: the notification (id 889) that
/// AlarmManager fires when the phone has been still for too long and Sylvia,
/// whose own 5 s timer is the real detector, did not get to raise the alarm
/// (process killed, or frozen by the system).
library;

/// How long after Sylvia's own limit the backstop fires. It must never come
/// first: Sylvia cancels it the moment it raises the alarm, so a backstop that
/// does fire means Sylvia did not.
///
/// While the phone moves the backstop is only re-armed when a movement is more
/// than [backstopRescheduleSeconds] newer than the one it was armed from, so
/// the last movement can be that much later; Sylvia checks every 5 s and needs
/// a full second over the limit. 90 s leaves over 20 s of margin on top of
/// both.
const int backstopMarginSeconds = 90;

/// How much newer than the movement the backstop was armed from a movement
/// must be to re-arm it.
const int backstopRescheduleSeconds = 60;

/// A backstop that came due longer ago than this is history, not an alarm:
/// the phone was off, or the service could not start for a long time. Enough to
/// cover the restart watchdog, which may take around 10 minutes.
const int backstopMaxOverdueSeconds = 15 * 60;

/// When the backstop must fire for a phone last seen moving at [lastMovement]:
/// after Sylvia's own limit, and never right away.
DateTime backstopDue({
  required DateTime lastMovement,
  required int limitSeconds,
  required DateTime now,
}) {
  final DateTime due = lastMovement
      .add(Duration(seconds: limitSeconds + backstopMarginSeconds));
  final DateTime soonest =
      now.add(const Duration(seconds: backstopMarginSeconds));
  return due.isBefore(soonest) ? soonest : due;
}

/// After a backstop came due with the service down, how long the restarted
/// Sylvia watches the accelerometer before raising the alarm. The phone was
/// still when the previous Sylvia last saw it, but nobody watched afterwards:
/// a person walking shows up within seconds and gets no alarm; a phone that
/// stays still gets the normal one, siren and countdown included.
const int backstopGraceSeconds = 45;

/// True when a starting Sylvia finds a backstop that came due while it was not
/// running, recently enough to still mean "nobody has moved". [dueMs] is 0
/// when none is armed.
bool backstopCameDue({required int dueMs, required int nowMs}) {
  if (dueMs <= 0) return false;
  final int overdueMs = nowMs - dueMs;
  return overdueMs >= 0 && overdueMs <= backstopMaxOverdueSeconds * 1000;
}

/// The "last movement" a Sylvia starts with when [backstopCameDue]: such that
/// its own inactivity check, the same one as always, fires
/// [backstopGraceSeconds] from [now] unless the sensors see movement first.
DateTime lastMovementAfterMissedBackstop({
  required DateTime now,
  required int limitSeconds,
}) {
  final int already = limitSeconds - backstopGraceSeconds;
  return now.subtract(Duration(seconds: already > 0 ? already : 0));
}
