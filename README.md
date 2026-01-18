# Oksigenia SOS 🛟

**FOSS Emergency Alert System for Android.**
Privacy-first. Offline-first. No trackers.

Oksigenia SOS is a safety tool designed for hikers, elderly people, and activists. It detects falls or inactivity and sends an automatic SMS with your GPS coordinates to your trusted contacts.

![Oksigenia SOS Screenshot](screenshots/Captura09.jpg)

## ✨ New in v3.6.0
* **Privacy Hardening:** Removed dependency on Google Play Services location provider. Now uses raw GPS hardware directly via `forceLocationManager`.
* **Vibration Alert:** Haptic feedback added to the acoustic alarm for better awareness in pockets.
* **Smart Triggers:** Distinguishes between "Fall Detection" (G-Force impact) and "Inactivity Monitor" (Lack of movement).
* **Live Tracking:** Option to send periodic location updates to the main contact after an SOS.
* **Multi-language:** Full support for English, Spanish, French, Portuguese, and German.
* **Internationalization:** Smart phone prefix detection.
* **Test Mode:** Added a 30-second mode to safely test the Inactivity Monitor.

## 🚀 Key Features
* **Fall Detection:** Uses the accelerometer to detect severe impacts.
* **Dead Man's Switch (Inactivity):** Timer that triggers an alarm if the device doesn't move for a set time (1h, 2h).
* **Panic Button:** Hold the large red button to trigger an immediate manual SOS.
* **Offline Operation:** No internet required. Works via SMS and GPS satellites only.
* **Zero Data Collection:** No servers. No analytics. Your data stays on your phone.

## ⚠️ Disclaimer
This app is provided "as is". It relies on battery, GPS signal, and cellular coverage. It is a support tool, not a replacement for professional emergency services.

## 🔧 Build & Sign
Built with Flutter.
To build the release APKs (split per ABI):
```bash
flutter build apk --release --split-per-abi
