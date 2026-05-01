# 🛠️ Oksigenia SOS v4.1.1 — Reproducible Build hot-fix

> v4.1.0 feature set, now bit-for-bit reproducible.

---

## What changed vs v4.1.0

**Nothing in app behaviour.** Smart Beacon, the Equitation profile and the three new languages (Polish, Russian, Norwegian Bokmål) all behave identically.

The only change is in the GitHub Actions release workflow: a new step strips the build-id embedded by the linker into `libdartjni.so` (transitive `jni` dependency). Without this, each build produced a slightly different shared library, so the APK was not bit-for-bit reproducible and IzzyOnDroid could not certify it as RB-verified.

Reported by IzzySoft in [Issue #6](https://github.com/OksigeniaSL/oksigenia-sos/issues/6).

### Workflow patch

```yaml
- name: Patch jni for Reproducible Builds
  run: sed -i -e 's/-Wl,/-Wl,--build-id=none,/' $HOME/.pub-cache/hosted/*/jni-*/src/CMakeLists.txt
```

The patch runs after `flutter pub get` (so `jni` is already in the pub cache) and before `flutter build apk` (so the patched CMakeLists drives the actual build).

---

## v4.1.0 features (carried forward)

### 📡 Smart Beacon — Post-SOS Position Updates

After an SOS SMS is sent (auto by Smart Sentinel or manual via the SOS button), Sylvia watches the user's GPS position. If the user moves **>300 m** from the last reference point, an SMS update is sent with the new coordinates.

- Throttled: one SMS every 5 minutes
- Capped: 20 updates over a 4-hour window
- Battery cost while stationary: zero (no SMS sent until movement)
- Stops automatically when the user taps **"Restart system"**

Solves the real outdoor problem of rescuers arriving 2–4 hours later to a victim who has wandered hundreds of meters from the original incident point.

### 🐴 Equitation Profile

Seventh activity profile, for horse riding. Impact detection is disabled by design — horse cadence (trot ~1.5 Hz, canter 2–3 Hz) interferes with the human-walk detector. Inactivity Monitor and manual SOS remain active. GPS interval 15 s / 20 m.

### 🌍 Three new languages

- 🇵🇱 **Polish** (pl)
- 🇷🇺 **Russian** (ru)
- 🇳🇴 **Norwegian Bokmål** (nb)

Now **11 languages** total.

---

## ⚙️ Technical

- Flutter **3.38.7** (exact)
- JDK 17 (Zulu)
- Android target SDK 35
- No Google Play Services / GMS
- Split APKs: `arm64-v8a`, `armeabi-v7a`
- **Zero new dependencies** vs v4.1.0
- **Zero new permissions** vs v4.1.0

---

*Distributed via [IzzyOnDroid](https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos). Reproducible Builds compatible.*
