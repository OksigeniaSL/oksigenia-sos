# 🛡️ Oksigenia SOS v4.0.0 — Smart Sentinel Complete

> Multi-sport outdoor safety, now with home screen widgets.

---

## 🧠 Smart Sentinel v4 — Feature Complete

The fall-detection state machine and activity profile system landed in v3.9.7. v4.0.0 closes the loop with three additions:

### Catastrophic Impact Path (orange-direct)

A second G-force threshold per profile fires the alarm **immediately**, bypassing the 60-second yellow observation window. For impacts so hard that observing for rhythmic movement would just delay the SMS unnecessarily.

| Profile | Yellow (observation) | Orange (direct alarm) |
|:---|:---:|:---:|
| 🥾 Trekking | 6G | **10G** |
| 🚵 Trail / MTB | 8G | **13G** |
| 🧗 Mountaineering | 6G | **10G** |
| 🪂 Paragliding | impact off | impact off |
| 🛶 Kayak | impact off | impact off |
| 👷 Professional | 6G | **10G** |

Calibrated empirically on Pixel 8: a deliberate hard hit against a chair arm peaks at 10.4G — comparable to a real moderate-strong fall on a hard surface.

The 30-second pre-alert on the alarm screen remains the safety net for cancellation.

### GPS Interval per Profile

Each profile now declares its own GPS sampling rate. Replaces the 5 s / 10 m hard-coded value used in v3.9.7.

| Profile | Interval | Distance filter |
|:---|:---:|:---:|
| 🥾 Trekking | 30 s | 30 m |
| 🚵 Trail / MTB | 5 s | 10 m |
| 🧗 Mountaineering | 30 s | 30 m |
| 🪂 Paragliding | 2 s | 5 m |
| 🛶 Kayak | 15 s | 20 m |
| 👷 Professional | 5 s | 10 m |

Slow-motion sports save battery; fast-motion sports get the resolution they need. The new interval applies mid-session when the user changes the active profile.

---

## 🏠 Home Screen Widgets

Two AppWidgets, both implemented in native Kotlin — no new Flutter dependencies, no new permissions.

### Panic Widget (1×1)

A red circular SOS button that lives on the home screen. Tap fires the alarm flow directly (`AlarmScreen` + 30 s pre-alert), even if monitoring is currently off — the foreground service is woken up if needed.

### Status Widget (2×2)

A compact dashboard showing:

- 🥾 **Active profile** (with emoji)
- Sentinel state (green / yellow / orange / red colour-coded dot)
- Active modes (fall detection, inactivity monitor with configured time, live tracking)
- 🔋 Battery level

Updates once per minute via `AlarmManager`. Tap opens the app.

---

## 🛠️ Resolves Issue #3 — Paragliding False Positives

[Issue #3](https://github.com/OksigeniaSL/oksigenia-sos/issues/3) (`@ulipo`, Jan 2026) reported false positives during flight. v4.0.0 ships a **Paragliding profile** with impact detection disabled entirely. In flight the user is protected by the Inactivity Monitor and manual SOS. No accelerometer-based false positive is possible.

The Kayak profile follows the same logic.

---

## ⚙️ Technical

- Flutter **3.38.7** (exact, for Reproducible Builds)
- JDK 17 (Zulu)
- Android target SDK 35
- No Google Play Services / GMS
- Split APKs: `arm64-v8a`, `armeabi-v7a`
- **Zero new dependencies** vs v3.9.7
- **Zero new permissions** vs v3.9.7

---

## 🛡️ Permissions Required

Unchanged from v3.9.6 / v3.9.7. See `README.md` for the full table.

---

*Distributed via [IzzyOnDroid](https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos). Reproducible Builds compatible.*
