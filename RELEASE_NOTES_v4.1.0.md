# 📍 Oksigenia SOS v4.1.0 — Smart Beacon

> Post-SOS tracking. Three new languages. One new sport.

---

## 📡 Smart Beacon — Post-SOS Position Updates

The flagship feature of v4.1.0. Solves a real outdoor rescue problem: **the victim may not stay where the SOS was triggered**.

Real scenarios:
- A hiker breaks a leg, sends SOS, gets disoriented and walks the wrong direction
- A trail runner crashes, recovers dazed, tries to descend before night falls
- A climber falls, sends SOS, then is carried by partners towards a rescue point

In all cases, the SMS the rescue team receives points to the **incident location**, not the victim's **current location**. By the time rescuers arrive 2–4 hours later, the victim may be hundreds of meters away.

### How Smart Beacon works

After an SOS SMS is sent (auto by Smart Sentinel or manual via the SOS button), Sylvia:

1. Stores the origin position and timestamp.
2. Polls GPS every 5 seconds (battery-friendly — uses the same passive subscription as Live Tracking).
3. If the user moves **>300 m** from the last reference point, sends an SMS update with the new coordinates.
4. Throttled: one SMS every 5 minutes max (no spam on bursty movement).
5. Capped: 20 updates over a 4-hour window (covers typical rescue timelines).
6. Stops automatically when the user taps **"Restart system"** on the sent screen.

### Battery cost

Essentially zero while stationary. The 5-second poll uses the same GPS stream that's already running for the active profile. SMS is only sent when movement is detected, so a victim who stays put consumes nothing extra.

### SMS format

```
📍 OKSIGENIA UPDATE — moved 420m
Maps: https://maps.google.com/?q=lat,lon
OSM: https://www.openstreetmap.org/?mlat=...
```

Resolves the request from [the team's tracking discussion](https://github.com/OksigeniaSL/oksigenia-sos): voluntary Live Tracking + automatic post-SOS Smart Beacon now coexist as complementary modes.

---

## 🐴 Equitation Profile

Seventh activity profile, for horse riding.

Impact detection is **disabled** by design — horse cadence (trot ~1.5 Hz, canter 2–3 Hz) interferes with the human-walk detector that powers Smart Sentinel. Without empirical phone-in-pocket-while-riding data, defaulting to "off" is the honest call rather than shipping unvalidated thresholds.

In flight: **Inactivity Monitor + manual SOS** protect the rider. Default GPS interval is 15 s / 20 m (similar to Kayak — moderate movement on terrain).

Same approach as the Paragliding and Kayak profiles. The full profile table is now:

| Profile | Impact | Yellow | Orange-direct | GPS |
|:---|:---:|:---:|:---:|:---:|
| 🥾 Trekking | ✓ | 6G | 10G | 30 s / 30 m |
| 🚵 Trail / MTB | ✓ | 8G | 13G | 5 s / 10 m |
| 🧗 Mountaineering | ✓ | 6G | 10G | 30 s / 30 m |
| 🪂 Paragliding | — | — | — | 2 s / 5 m |
| 🛶 Kayak | — | — | — | 15 s / 20 m |
| 🐴 Equitation | — | — | — | 15 s / 20 m |
| 👷 Professional | ✓ | 6G | 10G | 5 s / 10 m |

---

## 🌍 Three new languages

The app now supports **11 languages**.

- 🇵🇱 **Polish** (pl) — Tatra and Beskid hiking culture, active F-Droid community
- 🇷🇺 **Russian** (ru) — Caucasus, Altai, Urals, Kamchatka outdoor culture
- 🇳🇴 **Norwegian Bokmål** (nb) — friluftsliv, the cradle of outdoor lifestyle

Translations cover all UI strings and SMS templates. Quality is reasonable but not native-validated — community feedback welcome via GitHub Issues for any phrasing improvements.

---

## ⚙️ Technical

- Flutter **3.38.7** (exact, for Reproducible Builds)
- JDK 17 (Zulu)
- Android target SDK 35
- No Google Play Services / GMS
- Split APKs: `arm64-v8a`, `armeabi-v7a`
- **Zero new dependencies** vs v4.0.0
- **Zero new permissions** vs v4.0.0

---

## 🛡️ Permissions Required

Unchanged from v4.0.0. See `README.md` for the full table.

---

*Distributed via [IzzyOnDroid](https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos). Reproducible Builds compatible.*
