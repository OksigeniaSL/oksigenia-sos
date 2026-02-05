# Oksigenia SOS 🏔️ v3.9.3

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

| Dashboard | Impact Alert | Inactivity Alert |
|:---:|:---:|:---:|
| <img src="screenshots/main_en.jpg" width="220" alt="Main Dashboard Dark Mode" /> | <img src="screenshots/impact_en.jpg" width="220" alt="Impact Alert Red" /> | <img src="screenshots/inactivity_en.jpg" width="220" alt="Inactivity Alert" /> |

| Test Mode | Languages | Settings |
|:---:|:---:|:---:|
| <img src="screenshots/main_testmode_en.jpg" width="220" alt="Test Mode Warning" /> | <img src="screenshots/lang_en.jpg" width="220" alt="Language Selector" /> | <img src="screenshots/settings_en.jpg" width="220" alt="Settings Screen" /> |

---

## 🚀 The 3.9.x Saga: Engineering Excellence

This version establishes the Granite Foundation of the 3.9 cycle. It locks down core stability to prepare for upcoming visual features.

| Feature | English | Español |
|:---|:---|:---|
| 📐 **Math Precision** | **3D Vector Calculation**. We don't just use the accelerometer; we calculate the **3D G-Force Vector**. This filters out "backpack noise" and hiking vibrations, triggering only on real, hard impacts (>12G). No more false alarms when jumping or running. | **Cálculo Vectorial 3D**. No usamos solo el acelerómetro; calculamos el **Vector de Fuerza G en 3D**. Esto filtra el "ruido de mochila" y vibraciones al andar, disparándose solo en impactos reales (>12G). Adiós a las falsas alarmas por saltar o correr. |
| 🛡️ **System Integrity** | **Granite Core**. Complete rewrite of the background service. We eliminated "zombie processes" and **shielded the timers** against screen-off events. The app now survives Android's aggressive battery saving modes. | **Núcleo de Granito**. Reescritura del servicio en segundo plano. Eliminados los "procesos zombie" y **blindados los temporizadores** contra apagados de pantalla. La app sobrevive al ahorro de batería agresivo de Android. |
| 🧤 **Extreme UX** | **"Fat Finger" Design**. Buttons, sliders, and cancel logic are designed for **gloved or frozen hands**. We increased touch targets and simplified the cancellation flow to avoid stress errors during false alarms. | **Diseño "Dedos Fríos"**. Botones, deslizadores y lógica de cancelación diseñados para **guantes o manos entumecidas**. Aumentamos las áreas táctiles y simplificamos la cancelación para evitar errores por estrés. |
| 🌑 **Tactical Mode** | **Native Dark Mode**. Enforced pure dark theme. This eliminates white flashes at startup (preserving your night vision in the dark) and drastically reduces battery consumption on AMOLED screens. | **Modo Táctico**. Tema oscuro puro forzado. Elimina los parpadeos blancos al inicio (preservando tu visión nocturna en la oscuridad) y reduce drásticamente el consumo en pantallas AMOLED. |
| 💬 **Smart Feedback** | **Haptic Language**. The app "talks" to you through vibration. Buttons buzz if contacts are missing. The SOS button vibrates progressively as you hold it. You know what's happening without looking at the screen. | **Lenguaje Háptico**. La app te "habla" mediante vibración. Los botones avisan si faltan contactos. El botón SOS vibra progresivamente al pulsarlo. Sabes lo que pasa sin mirar la pantalla. |
| 🚨 **Hold-to-Activate** | **Safety Trigger**. The SOS button now features a **3-second hold** with a visual loading ring. This prevents accidental triggers inside your pocket or backpack while leaning. | **Disparador Seguro**. El botón SOS ahora requiere **mantener 3 segundos** con un anillo de carga visual. Esto evita disparos accidentales dentro del bolsillo o la mochila al apoyarte. |
| 🌍 **Global Reach** | **8 Languages**. Full native support for **NL, SV, IT, ES, EN, FR, PT, DE**. Includes contextual help dialogs that explain technical details (GPS, SMS) in your local language. | **8 Idiomas**. Soporte nativo completo para **NL, SV, IT, ES, EN, FR, PT, DE**. Incluye diálogos de ayuda contextual que explican detalles técnicos (GPS, SMS) en tu idioma local. |

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
This project uses **Flutter 3.x** and `Provider`.

```bash
git clone [https://github.com/OksigeniaSL/oksigenia-sos.git](https://github.com/OksigeniaSL/oksigenia-sos.git)
cd oksigenia-sos
flutter pub get
# Create your key.properties first!
flutter build apk --release --split-per-abi
