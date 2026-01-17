# Oksigenia SOS 🆘

**Oksigenia SOS** is an open-source emergency response application designed for outdoor enthusiasts, solo travelers, and anyone needing a reliable safety net. It detects falls/impacts and automatically sends an SMS with your precise GPS coordinates to a predefined emergency contact.

<p align="center">
  <img src="assets/images/screen_main.jpg" width="240" alt="Main Screen"/>
  &nbsp;&nbsp;
  <img src="assets/images/screen_settings.jpg" width="240" alt="Settings"/>
  &nbsp;&nbsp;
  <img src="assets/images/screen_alert.jpg" width="240" alt="Alert Mode"/>
</p>

## 🚀 Key Features

* **🛡️ Automatic Fall Detection:** Uses device accelerometer to detect high-impact events.
* **📡 Native Background SMS:** Bypasses standard app limitations to send SMS even when the screen is off (Android).
* **🛰️ Parallel GPS Locking:** Starts searching for satellites immediately upon impact detection.
* **⚡ Zero-Server Architecture:** No accounts, no cloud tracking. Your data stays on your phone.
* **🌍 Multi-language:** EN, ES, FR, PT, DE.

## 🛠️ Installation

### Option 1: Direct APK (Community)
Download the latest `app-community-release.apk` from our website.
* *Note:* Requires enabling "Install from unknown sources".

### Option 2: Build from Source
1.  Clone the repository.
2.  Run: `flutter pub get`
3.  Build: `flutter build apk --release --flavor community`

## ⚠️ Disclaimer

**Oksigenia SOS is a support tool, NOT a replacement for professional emergency services.**
Functionality depends on battery life, GPS signal, and cellular coverage. Use at your own risk.

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.
See the [LICENSE](LICENSE) file for details.
