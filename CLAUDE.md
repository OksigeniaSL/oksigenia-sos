# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                          # Run debug on connected device
flutter build apk --release --split-per-abi --no-shrink  # Production build (matches CI)
flutter pub get                      # After pubspec.yaml changes
flutter gen-l10n                     # Regenerate after editing any app_*.arb file
```

There are no automated tests. Validation is manual on a Pixel 8 running GrapheneOS.

## Architecture

The app has two independent Dart runtimes that communicate via message passing:

**UI isolate** (`lib/logic/sos_logic.dart` + `lib/screens/`)
- `SOSLogic` is a `ChangeNotifier` (Provider pattern) that owns all UI state
- Status enum: `ready → scanning → locationFixed → preAlert → sent → error`
- Sends commands to the service via `FlutterBackgroundService().invoke("eventName", {...})`
- Listens to service events via `service.on("eventName")`
- `oksigeniaNavigatorKey` is a global navigator key used by the service to push screens when the app is in the background (e.g. alarm fires while screen is off)

**Service isolate — "Sylvia"** (`lib/services/background_service.dart`)
- Entry point: `onStart(ServiceInstance service)` — a top-level function, all variables are locals within it (not class fields)
- Dart local functions inside `onStart` are **not hoisted** — declare before use
- Runs as Android foreground service; notification channel id is `my_foreground`, notification id is `888`
- `flutterLocalNotificationsPlugin.show(id: 888, ...)` replaces the package's initial notification
- Service events it handles: `setConfig`, `setMonitoring`, `startAlarm`, `stopAlarm`, `stopService`, `updateNotification`

**Stopping the service correctly:**
`stopSystem()` in `sos_logic.dart` sends `stopService` and then waits 600ms before returning. This gives Sylvia time to run `cancelAll()` + `stopSelf()` before `SystemNavigator.pop()` closes the UI engine. Do not remove this delay.

## Smart Sentinel (fall detection algorithm)

1. Accelerometer streams at `SensorInterval.gameInterval` (~20ms)
2. G-force = `sqrt(x²+y²+z²) / 9.81`
3. Impact > 3.5G → enter **yellow state** (60s observation window)
4. Every 2s: check `_isRhythmicMovement()` on `_gBuffer` (last 60 samples, counts 1G crossings ≥3 = walking = false positive)
5. If rhythmic → `_returnToGreen()` (clears buffer, resets sentinel)
6. If 60s with no rhythmic movement → `_lanzarAlarma()`

`_returnToGreen()` **must clear `_gBuffer`** — stale buffer data causes every subsequent impact to be classified as a false positive.

`_lanzarAlarma()` **must set `_isAlarmActive = true` at the very first line** — the zombie timer checks this flag on every tick and aborts if false.

## Key guards in the sensor listener

```dart
if (DateTime.now().difference(serviceStartupTime).inSeconds < 3) return; // startup noise
if (DateTime.now().difference(_lastStopTimestamp).inSeconds < 10) return; // post-cancel block
if (_isAlarmActive || _sensorCooldown) return;
```

`_lastStopTimestamp` is set when `stopAlarm` is received. Buffer is frozen during this 10s window.

## Notification icon

Must be white-on-transparent. Use `ic_stat_oksigenia` (PNG, all density folders under `drawable-{mdpi→xxxhdpi}/`). The XML vector icons (`ic_stat_protected.xml`, `ic_stat_paused.xml`) exist but are legacy. `ic_launcher_monochrome.png` is a 40KB launcher asset — do not use it as a notification icon.

The service notification channel (`my_foreground`) must be `Importance.defaultImportance` so it appears outside the "silent notifications" group on strict Android (GrapheneOS). Individual notification calls use `playSound: false, enableVibration: false` to stay quiet.

## Localization

Edit `.arb` files in `lib/l10n/`, then run `flutter gen-l10n`. Never edit the generated `app_localizations_*.dart` files directly. 8 languages: en, es, fr, de, pt, it, nl, sv.

## Release process

Trigger: push a tag `v*` to GitHub. Actions builds split APKs (arm64-v8a, armeabi-v7a) and creates the GitHub Release. IzzyOnDroid bots pick it up automatically — do not publish there manually.

**Critical for Reproducible Builds (IzzyOnDroid requirement):**
- Flutter version in workflow must be exact: `flutter-version: '3.38.7'` — never `stable` or `3.x`
- JDK must be 17 (Zulu) — JDK 21 breaks RB
- `build.gradle.kts` signing must be conditional (only apply if keystore file exists)
- `dependenciesInfo { includeInApk = false }` must remain in `build.gradle`
- No Google Play Services / GMS (F-Droid compliance; explicitly excluded in gradle)
- Fastlane metadata (`metadata/en-US/`) must be committed **before** tagging

## Android manifest notes

`FOREGROUND_SERVICE_LOCATION` is declared in the manifest only — it is a normal (non-dangerous) permission and must not be requested at runtime via `permission_handler`. The runtime permissions to request are: `location`, `sms`, `notification`, `activityRecognition`, `ignoreBatteryOptimizations`.

## Sensitive files (never read or commit)

`android/key.properties`, `android/app/upload-keystore.jks`, `android/local.properties`
