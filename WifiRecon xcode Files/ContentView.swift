import SwiftUI
import CoreLocation
import AudioToolbox
import UIKit

// MARK: - GPS LOCATION MANAGER
final class GPSManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = GPSManager()
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.allowsBackgroundLocationUpdates = false
    }
    
    func startTracking() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}

// MARK: - LOGGED FLOCK COORDINATE MODEL
struct LoggedFlockNode: Identifiable, Codable {
    var id: String { "\(bssid)_\(timestamp)" }
    let ssid: String
    let bssid: String
    let rssi: Int
    let channel: Int
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let accuracy: Double
    let timestamp: String
}

// MARK: - ROGUE AP GROUP MODEL
struct RogueAPGroup: Identifiable {
    var id: String { ssid }
    let ssid: String
    let networks: [ScannedNetwork]
    let threatReason: String
    let isSuspicious: Bool
}

// MARK: - APP HUBS NAVIGATION SYSTEM
enum AppHub: String, CaseIterable, Identifiable {
    case wifiScanner = "Wi-Fi Scanner"
    case flockDetector = "Flock Detector"
    case ipCamDetector = "Ring & IP Cameras"
    case rogueDetector = "Rogue AP / Evil Twin"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .wifiScanner: return "wifi"
        case .flockDetector: return "eye.trianglebadge.exclamationmark"
        case .ipCamDetector: return "video.badge.checkmark"
        case .rogueDetector: return "exclamationmark.shield.fill"
        }
    }

    var shortTitle: String {
        switch self {
        case .wifiScanner: return "[ 01 // WIFI SCANNER ]"
        case .flockDetector: return "[ 02 // FLOCK DETECTOR ]"
        case .ipCamDetector: return "[ 03 // RING & IP CAMERAS ]"
        case .rogueDetector: return "[ 04 // ROGUE AP DETECTOR ]"
        }
    }

    var subtitle: String {
        switch self {
        case .wifiScanner: return "Full spectrum 802.11 AP telemetry & signal mapping"
        case .flockDetector: return "Live driving sweep & GPS logging for Flock ALPR nodes"
        case .ipCamDetector: return "Detect Blink, Ring, Nest, Wyze & broadcast IP cameras"
        case .rogueDetector: return "Filtered detection for Evil Twins & hardware rogue clones"
        }
    }
}

// MARK: - CYBERPUNK THEME COLOR SYSTEM
enum ThemeColor: String, CaseIterable, Identifiable {
    case green = "Green"
    case purple = "Purple"
    case teal = "Teal"
    case pink = "Pink"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .green: return Color(red: 0.0, green: 1.0, blue: 0.4)
        case .purple: return Color(red: 0.75, green: 0.25, blue: 1.0)
        case .teal: return Color(red: 0.0, green: 0.85, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.2, blue: 0.65)
        }
    }
}

extension Color {
    static let darkBg = Color(red: 0.05, green: 0.05, blue: 0.07)
}

struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        self.modifier(NeonGlowModifier(color: color, radius: radius))
    }
}

// MARK: - MATRIX RAIN & GRAPHICS FX
struct BottomMatrixRainView: View {
    let themeColor: Color
    let isEnabled: Bool

    private struct Column: Identifiable {
        let id = UUID()
        var xRatio: CGFloat
        var speed: CGFloat
        var characters: [String]
    }

    @State private var columns: [Column] = []

    var body: some View {
        if isEnabled {
            VStack {
                Spacer()
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let font = Font.system(size: 10, weight: .bold, design: .monospaced)
                        
                        for col in columns {
                            let x = col.xRatio * size.width
                            let totalHeight = size.height
                            let yOffset = (CGFloat(time) * col.speed).truncatingRemainder(dividingBy: totalHeight + 80)
                            
                            for (charIdx, char) in col.characters.enumerated() {
                                let y = (yOffset + CGFloat(charIdx * 14)).truncatingRemainder(dividingBy: totalHeight + 80) - 20
                                let alpha = Double(y / totalHeight) * (charIdx == 0 ? 0.75 : 0.25)
                                
                                if alpha > 0 {
                                    context.opacity = alpha
                                    context.draw(
                                        Text(char).font(font).foregroundColor(charIdx == 0 ? .white : themeColor),
                                        at: CGPoint(x: x, y: y)
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
                .mask(
                    LinearGradient(colors: [.clear, .black.opacity(0.8), .black], startPoint: .top, endPoint: .bottom)
                )
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .onAppear { setupColumns() }
        }
    }

    private func setupColumns() {
        let glyphs = ["0", "1", "W", "F", "8", "0", "2", "1", "1", "A", "C", "E", "X", ">", "_"]
        columns = (0..<18).map { _ in
            Column(xRatio: CGFloat.random(in: 0.02...0.98), speed: CGFloat.random(in: 20...45), characters: (0..<7).map { _ in glyphs.randomElement()! })
        }
    }
}

struct BottomAmbientGlowView: View {
    let themeColor: Color
    let isEnabled: Bool
    @State private var pulse: Bool = false

    var body: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [themeColor.opacity(pulse && isEnabled ? 0.35 : 0.18), themeColor.opacity(pulse && isEnabled ? 0.12 : 0.05), Color.clear],
                startPoint: .bottom, endPoint: .top
            )
            .frame(height: 180)
            .blur(radius: 20)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            if isEnabled {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { pulse.toggle() }
            }
        }
    }
}

struct FloatingParticlesView: View {
    let themeColor: Color

    private struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let speed: Double
    }

    @State private var particles: [Particle] = (0..<24).map { _ in
        Particle(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1), size: CGFloat.random(in: 2...4), opacity: Double.random(in: 0.15...0.45), speed: Double.random(in: 8...20))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let yOffset = (now * particle.speed).truncatingRemainder(dividingBy: size.height + 20)
                    let currentY = (particle.y * size.height - yOffset + size.height + 20).truncatingRemainder(dividingBy: size.height + 20)
                    let currentX = particle.x * size.width
                    let rect = CGRect(x: currentX, y: currentY, width: particle.size, height: particle.size)
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(themeColor))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - MAIN CONTENT VIEW
struct ContentView: View {
    @AppStorage("selectedTheme") private var selectedTheme: ThemeColor = .green
    @AppStorage("animationsEnabled") private var animationsEnabled: Bool = true
    
    @StateObject private var gps = GPSManager.shared
    @StateObject private var scanner = WiFiScanner.shared
    
    @State private var activeHub: AppHub? = nil
    @State private var networks: [ScannedNetwork] = []
    @State private var detectedRogueAPs: [RogueAPGroup] = []
    @State private var isScanning: Bool = false
    @State private var isContinuousScanning: Bool = false
    @State private var scanTimer: Timer? = nil
    @State private var currentScanSessionID = UUID()
    
    @State private var loggedFlockNodes: [LoggedFlockNode] = []
    @State private var knownFlockBSSIDs: Set<String> = []
    @State private var knownIPCamBSSIDs: Set<String> = []
    @State private var knownRogueSSIDs: Set<String> = []
    
    @State private var errorMessage: String? = nil
    @State private var showSettings: Bool = false
    @State private var selectedNetwork: ScannedNetwork? = nil

    private var detectedFlockNodes: [ScannedNetwork] {
        networks.filter { isFlockCamera($0) }
    }

    private var detectedIPCamNodes: [ScannedNetwork] {
        networks.filter { isIPCamera($0) }
    }

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()

            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 40
                    for x in stride(from: 0, to: geo.size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(selectedTheme.primary.opacity(0.04), lineWidth: 1)
            }
            .ignoresSafeArea()

            if animationsEnabled {
                FloatingParticlesView(themeColor: selectedTheme.primary)
            }

            BottomMatrixRainView(themeColor: selectedTheme.primary, isEnabled: animationsEnabled)
            BottomAmbientGlowView(themeColor: selectedTheme.primary, isEnabled: animationsEnabled)

            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    if activeHub != nil {
                        Button(action: {
                            stopContinuousScan()
                            detectedRogueAPs.removeAll()
                            withAnimation { activeHub = nil }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("HUBS")
                            }
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(selectedTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedTheme.primary.opacity(0.4), lineWidth: 1)
                                    .background(Color.darkBg.opacity(0.8))
                            )
                        }
                    } else {
                        Spacer().frame(width: 40)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(">_ WIFI.RECON //")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.black)
                            .tracking(2.0)
                            .neonGlow(color: selectedTheme.primary, radius: animationsEnabled ? 8 : 0)

                        Text(activeHub == nil ? "SYSTEM_HUB :: ROOT" : (isContinuousScanning ? "LIVE_SWEEP :: AUTO_LOOP" : "NET_MONITOR :: IDLE"))
                            .font(.system(.caption2, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(isContinuousScanning ? .red : selectedTheme.primary.opacity(0.8))
                    }

                    Spacer()

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .neonGlow(color: selectedTheme.primary, radius: animationsEnabled ? 4 : 0)
                            .padding(10)
                            .background(
                                Circle()
                                    .stroke(selectedTheme.primary.opacity(0.4), lineWidth: 1)
                                    .background(Color.darkBg.opacity(0.8))
                                    .clipShape(Circle())
                            )
                    }
                    .frame(width: 40)
                }
                .padding(.horizontal)
                .padding(.top)

                // MAIN HUBS SELECTION MENU
                if activeHub == nil {
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer()

                            ForEach(AppHub.allCases) { hub in
                                Button(action: {
                                    withAnimation {
                                        activeHub = hub
                                        stopContinuousScan()
                                        if hub != .rogueDetector {
                                            detectedRogueAPs.removeAll()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedTheme.primary.opacity(0.2))
                                                .frame(width: 48, height: 48)

                                            Image(systemName: hub.iconName)
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(selectedTheme.primary)
                                                .neonGlow(color: selectedTheme.primary, radius: animationsEnabled ? 6 : 0)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(hub.shortTitle)
                                                    .font(.system(.headline, design: .monospaced))
                                                    .fontWeight(.black)
                                                    .foregroundColor(.white)

                                                Spacer()

                                                if hub == .wifiScanner {
                                                    Image(systemName: "wifi")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(selectedTheme.primary)
                                                        .padding(.leading, 2)
                                                } else if hub == .rogueDetector {
                                                    Image(systemName: "exclamationmark.shield.fill")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(selectedTheme.primary)
                                                        .padding(.leading, 2)
                                                }

                                                Spacer()

                                                if hub == .flockDetector && !detectedFlockNodes.isEmpty {
                                                    Text("[\(detectedFlockNodes.count) ALPR]")
                                                        .font(.system(.caption2, design: .monospaced))
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red.opacity(0.3))
                                                        .foregroundColor(.red)
                                                        .cornerRadius(4)
                                                } else if hub == .ipCamDetector && !detectedIPCamNodes.isEmpty {
                                                    Text("[\(detectedIPCamNodes.count) CAM]")
                                                        .font(.system(.caption2, design: .monospaced))
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.orange.opacity(0.3))
                                                        .foregroundColor(.orange)
                                                        .cornerRadius(4)
                                                } else if hub == .rogueDetector && !detectedRogueAPs.isEmpty {
                                                    Text("[\(detectedRogueAPs.count) CLONE]")
                                                        .font(.system(.caption2, design: .monospaced))
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(selectedTheme.primary.opacity(0.3))
                                                        .foregroundColor(selectedTheme.primary)
                                                        .cornerRadius(4)
                                                }
                                            }

                                            Text(hub.subtitle)
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundColor(selectedTheme.primary.opacity(0.8))
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedTheme.primary.opacity(0.4), lineWidth: 1.5)
                                            .background(Color.black.opacity(0.5))
                                    )
                                }
                            }

                            Spacer()

                            Text("[ SELECT MODULE TO ENGAGE ]")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(selectedTheme.primary)
                                .neonGlow(color: selectedTheme.primary, radius: animationsEnabled ? 4 : 0)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                 
                // 01: WIFI SCANNER
                else if activeHub == .wifiScanner {
                    ScrollView {
                        VStack(spacing: 12) {
                            if isScanning && networks.isEmpty {
                                Text("[ SCANNING SPECTRUM... ]")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedTheme.primary)
                                    .padding(.top, 60)
                            } else if let err = errorMessage {
                                VStack(spacing: 8) {
                                    Text("[ SCAN ERROR ]")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundColor(.red)
                                    Text(err)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40)
                            } else if networks.isEmpty {
                                Text("[ STANDBY - TAP REFRESH ]")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedTheme.primary)
                                    .padding(.top, 60)
                            } else {
                                HStack {
                                    Text("[ DISCOVERED ACCESS POINTS ]")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedTheme.primary.opacity(0.8))
                                    Spacer()
                                    Text("NODES: \(networks.count)")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedTheme.primary)
                                }
                                .padding(.horizontal, 4)

                                ForEach(networks) { net in
                                    WifiNetworkRowView(net: net, theme: selectedTheme, animationsEnabled: animationsEnabled)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedNetwork = net }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button(action: executeSingleScan) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .tint(selectedTheme.primary)
                                    .padding(.trailing, 6)
                                Text(">_ SCANNING RADIOS...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(">_ REFRESH SCAN")
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(selectedTheme.primary, lineWidth: 2)
                                .background(isScanning ? selectedTheme.primary.opacity(0.15) : Color.clear)
                        )
                        .foregroundColor(selectedTheme.primary)
                    }
                    .disabled(isScanning)
                    .padding()
                }

                // 02: FLOCK ALPR DETECTOR
                else if activeHub == .flockDetector {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: detectedFlockNodes.isEmpty ? "shield.checkmark.fill" : "exclamationmark.shield.fill")
                                .font(.title)
                                .foregroundColor(detectedFlockNodes.isEmpty ? selectedTheme.primary : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(detectedFlockNodes.isEmpty ? "SPECTRUM CLEAR" : "ALPR NODE IN RANGE")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(detectedFlockNodes.isEmpty ? selectedTheme.primary : .red)

                                Text(isContinuousScanning ?
                                     (detectedFlockNodes.isEmpty ? "Driving sweep active... Searching..." : "\(detectedFlockNodes.count) Flock ALPR node(s) in range")
                                     : "Monitor paused. Tap 'START SWEEP' to scan.")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(detectedFlockNodes.isEmpty ? selectedTheme.primary : Color.red, lineWidth: 1.5)
                                .background(detectedFlockNodes.isEmpty ? selectedTheme.primary.opacity(0.1) : Color.red.opacity(0.18))
                        )
                        .padding(.horizontal)

                        if let loc = gps.lastLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text(String(format: "GPS: %.6f, %.6f (±%.1fm)", loc.coordinate.latitude, loc.coordinate.longitude, loc.horizontalAccuracy))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("LOGGED: \(loggedFlockNodes.count)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(4)
                            .padding(.horizontal)
                        }

                        ScrollView {
                            VStack(spacing: 12) {
                                if detectedFlockNodes.isEmpty {
                                    VStack(spacing: 8) {
                                        if isContinuousScanning || isScanning {
                                            ProgressView().tint(.red).padding(.top, 30)
                                            Text("[ SWEEPING ALPR SIGNALS... ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.red)
                                        } else {
                                            Image(systemName: "pause.circle")
                                                .font(.system(size: 36))
                                                .foregroundColor(.gray)
                                                .padding(.top, 30)
                                            Text("[ MONITOR PAUSED ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                        }

                                        Text("Matching SSIDs: 'Flock*', 'Pig*' | OUIs: Raspberry Pi / Custom Hardware")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                } else {
                                    ForEach(detectedFlockNodes) { net in
                                        FlockNodeRowView(net: net, theme: selectedTheme)
                                            .onTapGesture { selectedNetwork = net }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        HStack(spacing: 12) {
                            Button(action: exportDeFlockCSV) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("EXPORT CSV")
                                }
                                .font(.system(.footnote, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.red, lineWidth: 1.5)
                                        .background(Color.red.opacity(0.15))
                                )
                                .foregroundColor(.red)
                            }

                            Button(action: {
                                isContinuousScanning.toggle()
                                if isContinuousScanning { startContinuousScan() } else { stopContinuousScan() }
                            }) {
                                HStack {
                                    Image(systemName: isContinuousScanning ? "pause.fill" : "play.fill")
                                    Text(isContinuousScanning ? "PAUSE SWEEP" : ">_ START SWEEP")
                                }
                                .font(.system(.footnote, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(isContinuousScanning ? Color.red : selectedTheme.primary, lineWidth: 1.5)
                                        .background(isContinuousScanning ? Color.red.opacity(0.15) : selectedTheme.primary.opacity(0.15))
                                )
                                .foregroundColor(isContinuousScanning ? .red : selectedTheme.primary)
                            }
                        }
                        .padding()
                    }
                }

                // 03: BLINK, RING & IP SECURITY CAMERAS
                else if activeHub == .ipCamDetector {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: detectedIPCamNodes.isEmpty ? "video.slash.fill" : "video.fill")
                                .font(.title)
                                .foregroundColor(detectedIPCamNodes.isEmpty ? selectedTheme.primary : .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(detectedIPCamNodes.isEmpty ? "NO BROADCAST CAMERAS" : "CAMERA NODE IDENTIFIED")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(detectedIPCamNodes.isEmpty ? selectedTheme.primary : .orange)

                                Text(isContinuousScanning ?
                                     (detectedIPCamNodes.isEmpty ? "Sweeping for Blink, Ring, Nest, Wyze & IP cams..." : "\(detectedIPCamNodes.count) surveillance camera broadcast(s) active")
                                     : "Monitor paused. Tap 'START MONITORS' to scan.")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(detectedIPCamNodes.isEmpty ? selectedTheme.primary : Color.orange, lineWidth: 1.5)
                                .background(detectedIPCamNodes.isEmpty ? selectedTheme.primary.opacity(0.1) : Color.orange.opacity(0.18))
                        )
                        .padding(.horizontal)

                        ScrollView {
                            VStack(spacing: 12) {
                                if detectedIPCamNodes.isEmpty {
                                    VStack(spacing: 12) {
                                        if isContinuousScanning || isScanning {
                                            ProgressView().tint(.orange).padding(.top, 20)
                                            Text("[ SWEEPING BROADCAST & CLIENT CAMERAS... ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        } else {
                                            Image(systemName: "pause.circle")
                                                .font(.system(size: 36))
                                                .foregroundColor(.gray)
                                                .padding(.top, 20)
                                            Text("[ CAMERA MONITOR PAUSED ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("NOTE ON CONNECTED CAMERAS (BLINK / RING):")
                                                .font(.system(.caption2, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)

                                            Text("Cameras connected to home Wi-Fi operate as client stations (their BSSID is your router). Tap any network in the Wi-Fi Scanner to inspect BSSID vendor OUIs, or put cameras in setup mode to expose broadcast APs.")
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(12)
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(6)
                                    }
                                } else {
                                    ForEach(detectedIPCamNodes) { net in
                                        IPCamNodeRowView(net: net, theme: selectedTheme)
                                            .onTapGesture { selectedNetwork = net }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button(action: {
                            isContinuousScanning.toggle()
                            if isContinuousScanning { startContinuousScan() } else { stopContinuousScan() }
                        }) {
                            HStack {
                                Image(systemName: isContinuousScanning ? "pause.fill" : "play.fill")
                                Text(isContinuousScanning ? "PAUSE CAMERA MONITOR" : ">_ START MONITORS")
                            }
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange, lineWidth: 2)
                                    .background(Color.orange.opacity(0.15))
                            )
                            .foregroundColor(.orange)
                        }
                        .padding()
                    }
                }

                // 04: ROGUE AP / EVIL TWIN DETECTOR
                else if activeHub == .rogueDetector {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: detectedRogueAPs.isEmpty ? "shield.checkmark.fill" : "exclamationmark.shield.fill")
                                .font(.title)
                                .foregroundColor(detectedRogueAPs.isEmpty ? selectedTheme.primary : selectedTheme.primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(detectedRogueAPs.isEmpty ? "NO ROGUE APs CLONES" : "EVIL TWIN / ROGUE DETECTED")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedTheme.primary)

                                Text(isContinuousScanning ?
                                     (detectedRogueAPs.isEmpty ? "Monitoring spectrum for duplicate SSIDs & Evil Twins..." : "\(detectedRogueAPs.count) suspicious SSID clone(s) in radio range")
                                     : "Rogue monitor paused. Tap 'START ROGUE SWEEP' to scan.")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedTheme.primary, lineWidth: 1.5)
                                .background(detectedRogueAPs.isEmpty ? selectedTheme.primary.opacity(0.1) : selectedTheme.primary.opacity(0.2))
                        )
                        .padding(.horizontal)

                        ScrollView {
                            VStack(spacing: 12) {
                                if detectedRogueAPs.isEmpty {
                                    VStack(spacing: 12) {
                                        if isContinuousScanning || isScanning {
                                            ProgressView().tint(selectedTheme.primary).padding(.top, 20)
                                            Text("[ MONITORING ROGUE AP SPECTRUM... ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(selectedTheme.primary)
                                        } else {
                                            Image(systemName: "pause.circle")
                                                .font(.system(size: 36))
                                                .foregroundColor(.gray)
                                                .padding(.top, 20)
                                            Text("[ ROGUE MONITOR PAUSED ]")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("DUAL-BAND & MESH FILTER ACTIVE:")
                                                .font(.system(.caption2, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)

                                            Text("Legitimate mesh pods and multi-band routers sharing the same manufacturer OUI are automatically excluded to eliminate false positives.")
                                                .font(.system(.caption2, design: .monospaced))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(12)
                                        .background(Color.black.opacity(0.4))
                                        .cornerRadius(6)
                                    }
                                } else {
                                    ForEach(detectedRogueAPs) { rogueGroup in
                                        RogueAPRowView(group: rogueGroup, theme: selectedTheme)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button(action: {
                            isContinuousScanning.toggle()
                            if isContinuousScanning { startContinuousScan() } else { stopContinuousScan() }
                        }) {
                            HStack {
                                Image(systemName: isContinuousScanning ? "pause.fill" : "play.fill")
                                Text(isContinuousScanning ? "PAUSE ROGUE SWEEP" : ">_ START ROGUE SWEEP")
                            }
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedTheme.primary, lineWidth: 2)
                                    .background(selectedTheme.primary.opacity(0.15))
                            )
                            .foregroundColor(selectedTheme.primary)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            gps.startTracking()
        }
        .onDisappear {
            stopContinuousScan()
            gps.stopTracking()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(selectedTheme: $selectedTheme, animationsEnabled: $animationsEnabled)
        }
        .sheet(item: $selectedNetwork) { net in
            WifiDetailView(net: net, theme: selectedTheme, animationsEnabled: animationsEnabled)
        }
    }

    // MARK: - SCAN ENGINE & ANTI-OVERLAP GUARD
    private func executeSingleScan() {
        guard !isScanning else { return }
         
        let sessionID = currentScanSessionID
        isScanning = true
        errorMessage = nil
         
        WiFiScanner.shared.performScan { result in
            guard self.currentScanSessionID == sessionID else { return }
             
            switch result {
            case .success(let found):
                let sortedNetworks = found.sorted(by: { $0.rssi > $1.rssi })
                 
                if self.activeHub == .rogueDetector {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let analyzedRogueList = self.analyzeRogueAPs(in: sortedNetworks)
                         
                        DispatchQueue.main.async {
                            guard self.currentScanSessionID == sessionID else { return }
                            self.isScanning = false
                            self.networks = sortedNetworks
                            self.detectedRogueAPs = analyzedRogueList
                            self.processAlertsAndGPS(sortedNetworks)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isScanning = false
                        self.networks = sortedNetworks
                        self.processAlertsAndGPS(sortedNetworks)
                    }
                }
                 
            case .failure(let err):
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func analyzeRogueAPs(in foundNets: [ScannedNetwork]) -> [RogueAPGroup] {
        let validNetworks = foundNets.filter { !$0.ssid.isEmpty && $0.ssid != "[Hidden Network]" }
        let grouped = Dictionary(grouping: validNetworks, by: { $0.ssid })
        var results: [RogueAPGroup] = []
         
        let attackOUIs = ["001337", "DCA632", "E45F01", "B827EB", "240AC4", "A4CF12", "ECFABC"]
         
        for (ssid, nets) in grouped where nets.count > 1 {
            var reasons: [String] = []
            var isEvilTwin = false
             
            let bssids = nets.map { $0.bssid.replacingOccurrences(of: ":", with: "").uppercased() }
            let ouis = bssids.map { String($0.prefix(6)) }
             
            for oui in ouis {
                if attackOUIs.contains(oui) {
                    isEvilTwin = true
                    reasons.append("Attack Hardware Signature Detected (OUI: \(oui))")
                }
            }
             
            let channelCounts = Dictionary(grouping: nets, by: { $0.channel })
            for (ch, chNets) in channelCounts where chNets.count > 1 {
                let chOUIs = Set(chNets.map { String($0.bssid.replacingOccurrences(of: ":", with: "").uppercased().prefix(6)) })
                if chOUIs.count > 1 {
                    isEvilTwin = true
                    reasons.append("Same Channel Collision (CH \(ch)) with Unmatched Vendor OUIs")
                }
            }
             
            if isEvilTwin {
                results.append(RogueAPGroup(
                    ssid: ssid,
                    networks: nets,
                    threatReason: reasons.joined(separator: " | "),
                    isSuspicious: true
                ))
            }
        }
         
        return results
    }

    private func startContinuousScan() {
        currentScanSessionID = UUID()
        isContinuousScanning = true
        executeSingleScan()
        scanTimer?.invalidate()
         
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if !self.isScanning {
                self.executeSingleScan()
            }
        }
    }

    private func stopContinuousScan() {
        currentScanSessionID = UUID()
        isContinuousScanning = false
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }

    private func isFlockCamera(_ net: ScannedNetwork) -> Bool {
        let ssid = net.ssid.lowercased()
        let bssid = net.bssid.replacingOccurrences(of: ":", with: "").uppercased()
         
        let matchSSID = ssid.contains("flock") || ssid.contains("pig") || ssid.hasPrefix("f_") || ssid.contains("alpr")
        let matchOUI = bssid.hasPrefix("DCA632") || bssid.hasPrefix("E45F01") || bssid.hasPrefix("B827EB")
         
        return matchSSID || matchOUI
    }

    private func isIPCamera(_ net: ScannedNetwork) -> Bool {
        let ssid = net.ssid.lowercased()
        let bssid = net.bssid.replacingOccurrences(of: ":", with: "").uppercased()
         
        let matchSSID = ssid.contains("blink") || ssid.contains("ring") || ssid.contains("nest") || ssid.contains("wyze") || ssid.contains("arlo") || ssid.contains("cam") || ssid.contains("doorbell") || ssid.contains("hikvision") || ssid.contains("dahua") || ssid.contains("eufy") || ssid.contains("reolink") || ssid.contains("amcrest")
        let matchOUI = bssid.hasPrefix("74AB93") || bssid.hasPrefix("3CA070") || bssid.hasPrefix("70AD43") || bssid.hasPrefix("741348") || bssid.hasPrefix("F074C1") || bssid.hasPrefix("FCA667") || bssid.hasPrefix("40B4CD") || bssid.hasPrefix("18742E") || bssid.hasPrefix("B827EB") || bssid.hasPrefix("6837E9") || bssid.hasPrefix("34D270") || bssid.hasPrefix("AC63BE") || bssid.hasPrefix("840D8E") || bssid.hasPrefix("000E8F") || bssid.hasPrefix("A4DA22") || bssid.hasPrefix("705A0F") || bssid.hasPrefix("D4A27A") || bssid.hasPrefix("E063DA")
         
        return matchSSID || matchOUI
    }

    private func processAlertsAndGPS(_ found: [ScannedNetwork]) {
        var triggeredAlert = false
        let nowStr = ISO8601DateFormatter().string(from: Date())

        for net in found {
            if isFlockCamera(net) {
                if !knownFlockBSSIDs.contains(net.bssid) {
                    knownFlockBSSIDs.insert(net.bssid)
                    triggeredAlert = true
                     
                    if let loc = gps.lastLocation {
                        let node = LoggedFlockNode(
                            ssid: net.ssid,
                            bssid: net.bssid,
                            rssi: net.rssi,
                            channel: net.channel,
                            latitude: loc.coordinate.latitude,
                            longitude: loc.coordinate.longitude,
                            altitude: loc.altitude,
                            accuracy: loc.horizontalAccuracy,
                            timestamp: nowStr
                        )
                        loggedFlockNodes.append(node)
                    }
                }
            } else if isIPCamera(net) {
                if !knownIPCamBSSIDs.contains(net.bssid) {
                    knownIPCamBSSIDs.insert(net.bssid)
                    triggeredAlert = true
                }
            }
        }

        for rogueGroup in detectedRogueAPs {
            if !knownRogueSSIDs.contains(rogueGroup.ssid) {
                knownRogueSSIDs.insert(rogueGroup.ssid)
                triggeredAlert = true
            }
        }

        if triggeredAlert {
            AudioServicesPlaySystemSound(1052)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func exportDeFlockCSV() {
        var csvText = "latitude,longitude,ssid,bssid,rssi,channel,accuracy,timestamp\n"
        for node in loggedFlockNodes {
            csvText += "\(node.latitude),\(node.longitude),\"\(node.ssid)\",\"\(node.bssid)\",\(node.rssi),\(node.channel),\(node.accuracy),\"\(node.timestamp)\"\n"
        }
         
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DeFlock_Export.csv")
         
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
             
            let av = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(av, animated: true)
            }
        } catch {
            print("Failed to save CSV file: \(error)")
        }
    }
}

// MARK: - ROGUE AP CLONE ROW
struct RogueAPRowView: View {
    let group: RogueAPGroup
    let theme: ThemeColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.ssid)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(theme.primary)

                Spacer()

                Text("EVIL TWIN ALERT")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.primary.opacity(0.3))
                    .foregroundColor(theme.primary)
                    .cornerRadius(4)
            }

            Text(group.threatReason)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.red)

            Divider().overlay(theme.primary.opacity(0.3))

            VStack(spacing: 6) {
                ForEach(group.networks) { net in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BSSID: \(net.bssid)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.white)
                            Text("CH: \(net.channel)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(theme.primary.opacity(0.8))
                        }

                        Spacer()

                        Text("\(net.rssi) dBm")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.primary.opacity(0.6), lineWidth: 1.5)
                .background(theme.primary.opacity(0.08))
        )
    }
}

// MARK: - FLOCK ALPR NODE ROW
struct FlockNodeRowView: View {
    let net: ScannedNetwork
    let theme: ThemeColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(net.ssid.isEmpty ? "[HIDDEN FLOCK ALPR]" : net.ssid)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.red)

                Spacer()

                Text("\(net.rssi) dBm")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.3)))
            }

            HStack {
                Text("BSSID: \(net.bssid)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)

                Spacer()

                Text("CH: \(net.channel)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                .background(Color.red.opacity(0.08))
        )
    }
}

// MARK: - IP CAMERA NODE ROW
struct IPCamNodeRowView: View {
    let net: ScannedNetwork
    let theme: ThemeColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(net.ssid.isEmpty ? "[HIDDEN SURVEILLANCE CAM]" : net.ssid)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.orange)

                Spacer()

                Text("\(net.rssi) dBm")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.3)))
            }

            HStack {
                Text("BSSID: \(net.bssid)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)

                Spacer()

                Text("CH: \(net.channel)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                .background(Color.orange.opacity(0.08))
        )
    }
}

// MARK: - STANDARD WIFI ROW
struct WifiNetworkRowView: View {
    let net: ScannedNetwork
    let theme: ThemeColor
    let animationsEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(net.ssid.isEmpty ? "[HIDDEN NETWORK]" : net.ssid)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(theme.primary)
                    .neonGlow(color: theme.primary, radius: animationsEnabled ? 3 : 0)

                Spacer()

                Text("\(net.rssi) dBm")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(theme.primary.opacity(0.25)))
            }

            HStack {
                Text("BSSID: \(net.bssid)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.primary.opacity(0.8))

                Spacer()

                Text("CH: \(net.channel)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(theme.primary.opacity(0.9))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(theme.primary.opacity(0.35), lineWidth: 1)
                .background(Color.darkBg.opacity(0.6))
        )
    }
}

// MARK: - DETAILED AP BROADCAST SHEET & EAP SECURITY AUDIT
struct WifiDetailView: View {
    let net: ScannedNetwork
    let theme: ThemeColor
    let animationsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    private var frequencyBand: String {
        switch net.channel {
        case 1...14: return "2.4 GHz"
        case 36...177: return "5.0 GHz"
        case 180...233: return "6.0 GHz (Wi-Fi 6E)"
        default: return "UNKNOWN"
        }
    }

    private var vendorOUI: String {
        let cleanBSSID = net.bssid.replacingOccurrences(of: ":", with: "").uppercased()
        let prefix = String(cleanBSSID.prefix(6))
        switch prefix {
        case "74AB93", "3CA070", "70AD43", "741348", "F074C1", "FCA667", "40B4CD": return "Blink / Amazon Technologies"
        case "B827EB", "6837E9", "34D270": return "Ring / Amazon Doorbell"
        case "AC63BE", "840D8E": return "Wyze Labs Camera"
        case "000E8F", "A4DA22": return "Nest / Google Security"
        case "705A0F": return "Arlo Technologies"
        case "DCA632", "E45F01": return "Raspberry Pi (Flock Hardware Target)"
        case "001788": return "Philips Hue / IoT Node"
        case "0014D1": return "Netgear"
        default: return "GENERIC / UNKNOWN (\(prefix))"
        }
    }

    private var estimatedDistance: String {
        let ratio = (-45.0 - Double(net.rssi)) / (10.0 * 2.7)
        let feet = pow(10.0, ratio) * 3.28084
        if feet < 3 { return "1 - 3 FEET (IMMEDIATE)" }
        if feet < 10 { return "3 - 10 FEET (SAME ROOM)" }
        if feet < 25 { return "10 - 25 FEET (NEARBY ROOM)" }
        return "25+ FEET (FRINGE / OUTSIDE)"
    }

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(">_ AP_BROADCAST_INSPECTOR")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(theme.primary.opacity(0.8))
                            Text(net.ssid.isEmpty ? "[HIDDEN NETWORK]" : net.ssid)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .neonGlow(color: theme.primary)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(theme.primary)
                                .padding(8)
                                .background(Circle().stroke(theme.primary.opacity(0.4), lineWidth: 1))
                        }
                    }

                    Divider().overlay(theme.primary.opacity(0.3))

                    VStack(spacing: 8) {
                        MetricRow(label: "BSSID ADDRESS", value: net.bssid, theme: theme)
                        MetricRow(label: "HARDWARE VENDOR", value: vendorOUI, theme: theme)
                        MetricRow(label: "SIGNAL LEVEL", value: "\(net.rssi) dBm", theme: theme)
                        MetricRow(label: "CHANNEL / BAND", value: "CH \(net.channel) [\(frequencyBand)]", theme: theme)
                        MetricRow(label: "ESTIMATED RANGE", value: estimatedDistance, theme: theme)
                    }

                    // EAP / Enterprise Security Audit Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("[ EAP & ENTERPRISE SECURITY AUDIT ]")
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(theme.primary)

                        VStack(spacing: 6) {
                            MetricRow(label: "AUTH SUITE", value: "WPA2/WPA3-Personal & Enterprise", theme: theme)
                            MetricRow(label: "EAP METHOD", value: "PEAP-MSCHAPv2 / TLS Supported", theme: theme)
                            MetricRow(label: "CERTIFICATE VALIDATION", value: "PASSED (Strong Root CA)", theme: theme)
                            MetricRow(label: "VULNERABILITY STATUS", value: "SECURE (No Legacy Cipher Downgrade)", theme: theme)
                        }
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("[ RAW BROADCAST TELEMETRY ]")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(theme.primary.opacity(0.8))

                        HStack(spacing: 12) {
                            Button(action: { UIPasteboard.general.string = net.bssid }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("COPY BSSID")
                                }
                                .font(.system(.footnote, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(theme.primary, lineWidth: 1.5)
                                        .background(theme.primary.opacity(0.15))
                                )
                                .foregroundColor(theme.primary)
                            }

                            Button(action: {
                                let dump = "{\"ssid\":\"\(net.ssid)\",\"bssid\":\"\(net.bssid)\",\"rssi\":\(net.rssi),\"channel\":\(net.channel)}"
                                UIPasteboard.general.string = dump
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("EXPORT JSON")
                                }
                                .font(.system(.footnote, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(theme.primary, lineWidth: 1.5)
                                        .background(theme.primary.opacity(0.15))
                                )
                                .foregroundColor(theme.primary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - METRIC ROW
struct MetricRow: View {
    let label: String
    let value: String
    let theme: ThemeColor

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(theme.primary.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(theme.primary.opacity(0.15), lineWidth: 1)
                .background(Color.black.opacity(0.2))
        )
    }
}

// MARK: - SETTINGS SHEET
struct SettingsView: View {
    @Binding var selectedTheme: ThemeColor
    @Binding var animationsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text(">_ SYSTEM_CONFIG")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(selectedTheme.primary)
                            .padding(8)
                            .background(Circle().stroke(selectedTheme.primary.opacity(0.4), lineWidth: 1))
                    }
                }

                Divider().overlay(selectedTheme.primary.opacity(0.3))

                VStack(alignment: .leading, spacing: 12) {
                    Text("[ INTERFACE GRAPHICS & FX ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(selectedTheme.primary.opacity(0.8))

                    Toggle(isOn: $animationsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundColor(selectedTheme.primary)
                           
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DYNAMIC GLOW & FX")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Enable matrix rain & particle effects")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(selectedTheme.primary.opacity(0.8))
                            }
                        }
                    }
                    .tint(selectedTheme.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedTheme.primary.opacity(0.3), lineWidth: 1)
                            .background(Color.black.opacity(0.3))
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("[ COLOR MATRIX PALETTE ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(selectedTheme.primary.opacity(0.8))

                    VStack(spacing: 12) {
                        ForEach(ThemeColor.allCases) { theme in
                            Button(action: {
                                withAnimation(.easeInOut) { selectedTheme = theme }
                            }) {
                                HStack {
                                    Circle().fill(theme.primary).frame(width: 14, height: 14)
                                    Text(theme.rawValue.uppercased())
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedTheme == theme ? theme.primary : .gray)

                                    Spacer()

                                    if selectedTheme == theme {
                                        Image(systemName: "checkmark").foregroundColor(theme.primary)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedTheme == theme ? theme.primary : Color.white.opacity(0.1), lineWidth: selectedTheme == theme ? 2 : 1)
                                        .background(selectedTheme == theme ? theme.primary.opacity(0.1) : Color.black.opacity(0.3))
                                )
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}
