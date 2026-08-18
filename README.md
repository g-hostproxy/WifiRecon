# >_ WIFI.RECON // iOS Network Reconnaissance & Threat Detection Suite

An advanced, cyberpunk-styled iOS security utility engineered for 802.11 wireless spectrum analysis, automated license plate reader (ALPR) tracking, IP surveillance camera detection, and rogue access point monitoring. Designed for security research and mobile reconnaissance on jailbroken iOS 16 environments.

---

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

## 📱 Technical Requirements & Privileges

*   **OS:** iOS 16 (Jailbroken environment, e.g., `palera1n`).
*   **Privileges:** Requires system platform entitlements and `MobileWiFi.framework` access keys (`platform-application`, `com.apple.wifi.manager-access`) injected via `ldid`.
*   **Location Services:** Required active GPS authorization (`NSLocationWhenInUseUsageDescription`) to map wireless telemetry data during driving sweeps.

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
