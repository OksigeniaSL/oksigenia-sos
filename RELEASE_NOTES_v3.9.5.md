# 🏔️ Oksigenia SOS v3.9.5 — "Immortal Sentinel"

> The alarm now breaks through the lock screen. The Sentinel never dies.

---

## 🔔 Alarm Over Lock Screen

The most critical UX fix in the app's history.

- **Before:** When a fall was detected with the screen locked, the alarm played audio but the screen stayed locked. The user had to unlock with PIN/pattern before cancelling — nearly impossible with cold hands or gloves.
- **After:** The alarm appears directly **on top of the lock screen** using Android's `fullScreenIntent`. The Cancel button is fully interactive without unlocking. The screen turns on automatically.
- **Bonus fix:** The app no longer shows a frozen, non-interactive screenshot when the screen locks during normal use. Lock screen behavior is now completely normal outside of alarm mode.

## 🔋 Battery Optimization — Now a Hard Gate

- Monitoring (fall detection / inactivity) **cannot be activated** unless battery optimization is disabled for Oksigenia SOS.
- This is not a warning. It is a block. A single tap on the battery icon opens the correct system setting.
- **Why this matters:** Without `Unrestricted` battery mode, Android's Doze can kill the Sentinel after a few hours of inactivity — exactly when you need it most.

## 🧠 Smart Sentinel — Critical Fixes

- **Re-arm after cancel:** The Sentinel now re-arms correctly after the user cancels an alarm. Previously, a stale sensor buffer caused every subsequent impact to be classified as a false positive.
- **Alarm loop fixed:** The alarm sound now plays in a continuous loop for the full 30-second countdown. Previously it played once and went silent.
- **Zombie timer guard:** The auto-send countdown no longer aborts on the first tick when triggered by Smart Sentinel or inactivity (was a race condition with `_isAlarmActive` flag).

## 🔧 Other Fixes

- Notification icon corrected at all screen densities (was a white rectangle, now shows the proper app silhouette).
- Sylvia's persistent notification now appears in the notification drawer on strict Android (GrapheneOS). Was being placed in the silent/hidden group due to incorrect channel importance.
- `updateNotification` now uses the correct icon across all notification states.
- `sleepScreen` is called when the user cancels an alarm, properly restoring normal lock screen behavior.

---

## ⚙️ Technical

- Flutter 3.38.7 (exact, for Reproducible Builds)
- Android target SDK 35
- Reproducible Builds compatible (IzzyOnDroid verified)
- No Google Play Services / GMS
- Split APKs: `arm64-v8a` and `armeabi-v7a`

---

## 🛡️ Permissions Required

| Permission | Purpose | Required to monitor? |
|:---|:---|:---:|
| SMS | Send emergency alerts | ✅ Yes |
| Location | Include GPS in SMS | ✅ Yes |
| Battery Optimization (Unrestricted) | Keep Sentinel alive in deep sleep | ✅ Yes |
| Full-Screen Notifications (Android 14+) | Alarm appears over lock screen | ✅ Yes |
| Notifications | Show Sentinel status bar | Recommended |
| Activity Recognition | Sensor access | Recommended |

---

*Named in honor of Sylvia van Os (@TheLastProject), IzzyOnDroid maintainer, whose early device testing and detailed feedback made this app possible.*
