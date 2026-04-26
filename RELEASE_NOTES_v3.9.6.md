# 🥾 Oksigenia SOS v3.9.6 — "The Trekking Update"

> Stay connected on the trail. Live Tracking keeps your contact informed — automatically.

---

## 📡 Live Tracking

New feature for long routes where you want your emergency contact to know you're still moving.

- **Periodic check-ins:** Sends your GPS position via SMS every 30, 60, or 120 minutes.
- **Countdown timer:** "Next check-in in: MM:SS" visible in the status pill and the telemetry panel.
- **Pause / Resume:** Suspend check-ins temporarily without disabling fall detection.
- **"I'm OK" button:** Manual instant check-in that resets the countdown clock.
- **Auto-Pause on SOS:** Check-ins suspend automatically when a fall or inactivity alarm fires, and resume if the alarm is cancelled.

---

## ⏰ Doze Mode — Field Verified

After 1 hour of real-world deep sleep on a Pixel 8 running GrapheneOS, the alarm broke through the lock screen correctly and allowed cancellation without unlocking.

- `AlarmManager.alarmClock` is used for alarm scheduling — it bypasses Doze and survives deep sleep.
- `Timer.periodic` (the previous approach) freezes when the CPU enters Doze. It has been removed from the alarm path.

---

## 🧭 Onboarding Overhaul

### SMS Permission on Sideloaded APKs (Android 13+)
Android 13+ blocks SMS for sideloaded apps until the user explicitly unlocks "restricted settings". The required sequence is non-obvious:

1. Tap "Grant SMS" — Android shows "App was denied access to SMS" (this notice is required to unlock the ⋮ menu)
2. Go to **Settings → Apps → Oksigenia SOS** → tap **⋮** → **"Allow restricted settings"** → enter PIN
3. Go to **Permissions → SMS → Allow**

The onboarding wizard now guides through each step with confirmation checkpoints.

### Motion Sensor Detection
GrapheneOS has a dedicated "Sensors" toggle that blocks accelerometer access silently — no permission dialog, no error, just no events. Oksigenia now detects this on startup with a 2-second probe and blocks monitoring until sensor access is restored.

### "Why Permissions?" Sheet
Swipe up the bottom sheet in onboarding to read a plain-language explanation of exactly what each permission is used for and what stops working if you deny it.

### Language Selector
The app language can now be changed directly from the onboarding screen without navigating to system settings.

---

## 🔒 Privacy Fix

`READ_PHONE_STATE` was being injected as an implied permission by a transitive dependency. Root cause: `TelephonyManager.getSimCountryIso()` in `MainActivity.kt`. Replaced with `resources.configuration.locales[0].country` — no permission required. The APK no longer declares or implies this permission.

---

## ⚙️ Technical

- Flutter 3.38.7 (exact, for Reproducible Builds)
- Android target SDK 35
- Reproducible Builds compatible
- No Google Play Services / GMS
- Split APKs: `arm64-v8a` and `armeabi-v7a`

---

## 🛡️ Permissions Required

| Permission | Purpose | Required to monitor? |
|:---|:---|:---:|
| SMS | Send emergency alerts | ✅ Yes |
| Location | Include GPS in SMS | ✅ Yes |
| Motion Sensors | Detect falls and movement | ✅ Yes |
| Battery Optimization (Unrestricted) | Keep Sentinel alive in deep sleep | ✅ Yes |
| Full-Screen Notifications (Android 14+) | Alarm appears over lock screen | ✅ Yes |
| Notifications | Show Sentinel status bar | Recommended |
| Activity Recognition | Step detection | Recommended |

---

*Distributed via [IzzyOnDroid](https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos).*
