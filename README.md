# Oksigenia SOS 🏔️ v3.9.3 (RC1)

**Outdoor Emergency Assistant | FOSS | Privacy-First**

![Oksigenia Feature Graphic](metadata/en-US/images/featureGraphic.jpg)

[ES] **Oksigenia SOS** es una herramienta de seguridad personal diseñada para deportes de montaña y situaciones de riesgo. Detecta caídas o inactividad y envía SMS automáticos con coordenadas GPS y telemetría vital. Funciona de manera autónoma, sin depender de servidores externos.

[EN] **Oksigenia SOS** is a personal safety tool designed for mountain sports and risky situations. It detects falls or inactivity and sends automatic SMS with GPS coordinates and vital telemetry. It operates autonomously without relying on proprietary servers.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)]()
[![Privacy](https://img.shields.io/badge/Privacy-Offline%20%20No%20Trackers-blue)]()

<br>

<p align="center">
  <a href="https://apt.izzysoft.de/packages/com.oksigenia.oksigenia_sos">
    <img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" height="70" alt="Get it on IzzyOnDroid">
  </a>
</p>

👉 **[Donate via PayPal / Donar con PayPal](https://www.paypal.com/donate/?business=paypal@oksigenia.cc&currency_code=EUR)** 💙

---

## 📸 Interface / Interfaz (v3.9.3)

| Live Dashboard | Impact Alert | Settings | Menu |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/main_en.jpg" width="185" alt="Main Dashboard Telemetry" /> | <img src="screenshots/impact_en.jpg" width="185" alt="Impact Alert Red" /> | <img src="screenshots/settings_en.jpg" width="185" alt="Settings Screen" /> | <img src="screenshots/menu_en.jpg" width="185" alt="Navigation Drawer" /> |

| Inactivity Alert | Test Mode | Languages | About / Legal |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/inactivity_en.jpg" width="185" alt="Inactivity Alert" /> | <img src="screenshots/main_testmode_en.jpg" width="185" alt="Test Mode Warning" /> | <img src="screenshots/lang_en.jpg" width="185" alt="Language Selector" /> | <img src="screenshots/About_en.jpg" width="185" alt="About Screen" /> |

---

## 🚀 The 3.9.x Saga: Stability & Power

**New in v3.9.3 (The Stability Update):**
This version introduces a complete architectural rewrite using **Provider**, eliminating "ghost screens" and ensuring lifecycle shielding.

| Feature | English | Español |
|:---|:---|:---|
| 🛡️ **Core Shielding** | **Unbreakable Logic**. The timer and sensors are now "shielded" against lifecycle restarts. The alarm won't freeze or reset even if you switch apps or turn the screen off during an emergency. | **Blindaje de Núcleo**. Temporizadores y sensores "blindados" contra reinicios. La alarma no se congela ni reinicia aunque cambies de app o apagues la pantalla en una emergencia. |
| 🎮 **Hold-to-SOS** | **No more false clicks**. The main SOS button now requires a **3-second hold** with a visual loading ring and haptic feedback to prevent accidental triggers in your pocket. | **Adiós toques falsos**. El botón SOS ahora requiere **mantener pulsado 3s** con un anillo de carga visual y vibración para evitar disparos accidentales en el bolsillo. |
| 📡 **Live Telemetry** | **Real-Time Dashboard**. New icons on the home screen show live **G-Force, Battery %, and GPS Accuracy**. Monitor your sensor health at a glance before starting your activity. | **Telemetría en Vivo**. Nuevos iconos en el home muestran **Fuerza G, Batería % y Precisión GPS** en tiempo real. Verifica la salud de tus sensores antes de iniciar la actividad. |
| 🔊 **Smart Siren** | **Sync & Silence**. The alarm siren automatically cuts off the exact millisecond the SMS is successfully sent, giving instant auditory confirmation of help request. | **Sirena Sincronizada**. La sirena de alarma se corta automáticamente en el milisegundo exacto en que el SMS se envía, confirmando auditivamente la petición de ayuda. |
| 🌍 **Global Reach** | **9 Languages**. Full native support for **ES, EN, FR, PT, DE, IT, NL, SV** and regional languages like **Galician & Catalan**. | **9 Idiomas**. Soporte nativo completo para **ES, EN, FR, PT, DE, IT, NL, SV** y lenguas regionales como **Gallego y Catalán**. |
| 🌑 **Native Dark Mode** | **Tactical UI**. High-contrast interface with pure blacks to reduce battery consumption and glare during night operations. | **Interfaz Táctica**. Alto contraste con negros puros para reducir el consumo de batería y el deslumbramiento en operaciones nocturnas. |

---

## ⚠️ Critical Configuration / Configuración Crítica

### 🔋 1. Battery Optimization / Optimización de Batería
[EN] To ensure sensors and GPS never "sleep", you **must** disable battery optimization:
[ES] Para asegurar que los sensores y el GPS no se "duerman", **debes** desactivar la optimización:

1. Long press icon > **App Info (i)** / Mantén pulsado icono > **Información (i)**.
2. Go to **App battery usage** / Ve a **Uso de batería**.
3. Select **"Unrestricted"** / Selecciona **"Sin restricciones"**.

### 🛡️ 2. "Restricted Settings" (Android 13+)

[ES] Si ves un aviso de "Ajustes Restringidos" al activar los SMS:
1. Ve a **Ajustes > Apps > Oksigenia SOS**.
2. Pulsa los **tres puntos (⋮)** (arriba derecha) -> **"Permitir ajustes restringidos"**.

[EN] If you see a "Restricted Setting" warning when enabling SMS:
1. Go to **Settings > Apps > Oksigenia SOS**.
2. Tap **three dots (⋮)** (top right) -> **"Allow restricted settings"**.

<br clear="right"/>

---

## 🛠️ Download & Build

### 📦 Download APK
Check the **[Releases Section](https://github.com/OksigeniaSL/oksigenia-sos/releases)** for the latest signed APKs.

### 💻 Build from source
This project uses **Flutter 3.x** and `Provider` for state management.

```bash
git clone [https://github.com/OksigeniaSL/oksigenia-sos.git](https://github.com/OksigeniaSL/oksigenia-sos.git)
cd oksigenia-sos
flutter pub get
# Create your key.properties first!
flutter build apk --release --split-per-abi