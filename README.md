# >_ WIFI.RECON // iOS Network Reconnaissance & Threat Detection Suite

An advanced, cyberpunk-styled iOS security utility engineered for 802.11 wireless spectrum analysis, automated license plate reader (ALPR) tracking, IP surveillance camera detection, and rogue access point monitoring. Designed for security research and mobile reconnaissance on iOS environments.

---

⚠️ Disclaimers & Security Notice
AI-Assisted Development: Portions of this codebase, architecture, and documentation were written and structured with the assistance of artificial intelligence.

No Security Audit: This application has not undergone a professional third-party security audit. The code interacts with low-level system frameworks and private APIs, and users should review all source files before deployment.

Educational Use Only: This tool is created strictly for educational purposes, personal security research, and academic network auditing. Use responsibly and only on networks and hardware you own or have explicit authorization to test.

## 🚀 Core Modules

*   **[ 01 // WIFI SCANNER ]**
    *   Full-spectrum 802.11 AP telemetry, real-time signal strength (RSSI) monitoring, channel tracking, and BSSID discovery utilizing private `MobileWiFi.framework` bindings.
*   **[ 02 // FLOCK DETECTOR ]**
    *   Real-time driving sweeps and GPS-logged spatial coordinate tracking specifically tuned to detect Flock Safety Automated License Plate Reader (ALPR) nodes and associated hardware OUIs.
    *   Instant CSV export capability for collected geo-tagged coordinates.
*   **[ 03 // RING & IP CAMERAS ]**
    *   Identifies broadcast signatures and surveillance presence for consumer and enterprise cameras including Blink, Ring, Nest, Wyze, Arlo, Hikvision, and Dahua.
*   **[ 04 // ROGUE AP / EVIL TWIN ]**
    *   Heuristic filtering for duplicate SSID clones, channel collisions, and unauthorized hardware signature detection.
*   **[ 05 // EAP SECURITY AUDIT ]**
    *   Enterprise-grade authentication and cipher suite inspection embedded directly within individual network inspection profiles.

---

## 🎨 Cyberpunk Aesthetic & UI

*   Dynamic Matrix rain background simulation and ambient neon glow layers.
*   Customizable interface color matrix palettes (**Green, Purple, Teal, Pink**).
*   Monospaced hacker terminal styling complete with tactile audio-haptic alert feedback.

---

## 📲 Installation Guide (TrollStore Method)

Because this app utilizes elevated system entitlements and private framework bindings, standard sideloading methods will fail or sandbox the wireless manager. **TrollStore** is the recommended installation method for persistence and full entitlement injection:

1. Ensure your device is running a compatible TrollStore installation version/iOS build.
2. Build and sign your elevated `.ipa` (e.g., `WifiScanner+_Elevated.ipa`) using the build script with root entitlements.
3. Transfer the `.ipa` file to your iOS device (via AirDrop, Files app, or a local web server).
4. Open the file in **TrollStore** and tap **Install**.
5. Once installed, the application will run with full persistent entitlements without revokes.

---

## ⚙️ Build & Sign (CLI Method)

Save the following enterprise entitlements as `Entitlements.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "[http://www.apple.com/DTDs/PropertyList-1.0.dtd](http://www.apple.com/DTDs/PropertyList-1.0.dtd)">
<plist version="1.0">
<dict>
    <key>com.apple.private.apple80211.external</key>
    <true/>
    <key>com.apple.wifi.manager-access</key>
    <true/>
    <key>com.apple.system.security.network.wifi</key>
    <true/>
    <key>com.apple.private.network.socket-delegate</key>
    <true/>
    <key>platform-application</key>
    <true/>
    <key>com.apple.private.security.no-sandbox</key>
    <true/>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
