# Oksigenia SOS 🏔️ v3.9.4 "Advanced Dashboard"

**The Ultimate Outdoor Guardian | FOSS | Privacy-First | Autonomous**

![Oksigenia Feature Graphic](metadata/en-US/images/featureGraphic.jpg)

<p align="center">
  <a href="https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos">
    <img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" height="60" alt="Get it on IzzyOnDroid">
  </a>
</p>

---

## 🦅 Why Oksigenia SOS?

When you are alone in the mountains, technology is your last line of defense. Most safety apps rely on internet connection, proprietary servers, or paid subscriptions. **Oksigenia SOS is different.**

It is an **autonomous bio-telemetry system** designed to detect life-threatening situations (severe falls or prolonged unconsciousness) and automatically trigger a rescue protocol using pure SMS.

* **No Servers:** Your data never leaves your phone.
* **No Internet:** Works via GSM/SMS (2G/3G/4G/5G).
* **No Accounts:** Install, configure, and you are protected.

---

## 📸 Visual Tour (v3.9.4)

The new **v3.9.4** interface has been redesigned for high-stress situations. High contrast, large touch targets for gloved hands, and clear status indicators.

| **Flight Deck** | **Fall Detected** | **Inactivity Alert** | **Configuration** |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/main_en.jpg" width="180" /> | <img src="screenshots/impact_en.jpg" width="180" /> | <img src="screenshots/inactivity_en.jpg" width="180" /> | <img src="screenshots/settings_en.jpg" width="180" /> |
| *Real-time telemetry & status* | *30s countdown before SMS* | *Triggered by lack of motion* | *Local contacts & settings* |

| **Test Mode** | **Alert Sent** | **SMS Payload** | **Localization** |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/main_testmode_en.jpg" width="180" /> | <img src="screenshots/sent_en.jpg" width="180" /> | <img src="screenshots/sms_sos_en.png" width="180" /> | <img src="screenshots/lang_en.jpg" width="180" /> |
| *Safe testing environment* | *Confirmation screen* | *Direct GPS coordinates* | *8 Native languages* |

---

## 🚀 The v3.9.x Saga: Engineering Excellence

This version represents a massive leap in stability and sensor fusion logic. We call it the **"Granite Core"** update.

### 🧠 Core Features

| Feature | Technical Detail |
|:---|:---|
| **📊 Live Telemetry** | The footer now displays real-time sensor data. **G-Force Meter** visualizes acceleration vector sum. **Battery Voltage** monitoring ensures you don't run dry. **GPS Accuracy** lets you know if satellites are locked. |
| **📐 Vector Physics** | We moved from simple threshold detection to **3D Vector Magnitude Calculation** ($\sqrt{x^2+y^2+z^2}$). This filters out running, jumping, or backpack noise, triggering only on genuine, high-energy impacts (>12G). |
| **🧟 Zombie Killer** | Complete rewrite of the background service architecture. The app now handles Android's lifecycle aggressively, ensuring the background monitor starts when needed and **dies completely** when closed, saving battery. |
| **🛡️ Permission Semaphores** | A new "Traffic Light" header instantly shows if you are safe. **Green:** Systems Go. **Red:** Critical permission missing (SMS, GPS). Clicking a red icon guides you directly to the specific Android setting to fix it. |
| **🌑 Tactical Dark Mode** | Enforced pure dark theme (OLED friendly). This preserves your night vision during night treks and maximizes battery life in cold environments. |
| **💬 Haptic Language** | The app communicates via vibration patterns. You can "feel" the state of the app (countdown, activation, error) without taking your phone out of your pocket. |

---

## ⚠️ Critical Configuration

To guarantee 100% reliability, you must override Android's aggressive battery saving features.

### 🔋 1. Disable Battery Optimization
* **Why?** Android kills background apps to save power. We need the sensors awake.
* **How:** Long press App Icon > **App Info (i)** > **Battery** > Select **"Unrestricted"**.

### 🛡️ 2. Allow "Restricted Settings" (Android 13+)
* **Why?** To prevent malware, Android blocks apps from sending SMS automatically. You must authorize Oksigenia manually.
* **How:** Go to **Settings > Apps > Oksigenia SOS** > Tap **three dots (⋮)** (top right) > **"Allow restricted settings"**.

---

## 🌍 Global Availability

Oksigenia SOS is fully localized by native speakers:
* 🇬🇧 English
* 🇪🇸 Español
* 🇮🇹 Italiano
* 🇫🇷 Français
* 🇩🇪 Deutsch
* 🇵🇹 Português
* 🇳🇱 Nederlands
* 🇸🇪 Svenska

---

## 🛠️ Build & Contribute

We believe safety tools should be open and auditable.

### 📦 Download
Get the latest signed APKs from the **[Releases Section](https://github.com/OksigeniaSL/oksigenia-sos/releases)** or via **IzzyOnDroid**.

### 💻 Build from Source
Requirements: **Flutter 3.x**

```bash
git clone [https://github.com/OksigeniaSL/oksigenia-sos.git](https://github.com/OksigeniaSL/oksigenia-sos.git)
cd oksigenia-sos
flutter pub get
# Note: You need your own key.properties for release builds
flutter build apk --release --split-per-abi