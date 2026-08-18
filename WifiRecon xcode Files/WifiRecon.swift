import Foundation
import Combine
import CoreLocation

// MARK: - Data Model
struct ScannedNetwork: Identifiable {
    let id = UUID()
    let ssid: String
    let bssid: String
    let rssi: Int
    let channel: Int
}

// MARK: - C Function Signatures & Types
private typealias WiFiManagerRef = OpaquePointer
private typealias WiFiDeviceClientRef = OpaquePointer
private typealias WiFiNetworkRef = OpaquePointer

private typealias WiFiManagerClientCreateFunc = @convention(c) (CFAllocator?, Int32) -> WiFiManagerRef?
private typealias WiFiManagerClientCopyDevicesFunc = @convention(c) (WiFiManagerRef) -> Unmanaged<CFArray>?
private typealias WiFiManagerClientScheduleWithRunLoopFunc = @convention(c) (WiFiManagerRef, CFRunLoop, CFString) -> Void
private typealias WiFiDeviceClientCopyNetworksFunc = @convention(c) (WiFiDeviceClientRef) -> Unmanaged<CFArray>?

private typealias WiFiDeviceClientScanCallback = @convention(c) (WiFiDeviceClientRef, CFArray?, CFError?, UnsafeMutableRawPointer?) -> Void
private typealias WiFiDeviceClientScanAsyncFunc = @convention(c) (WiFiDeviceClientRef, CFDictionary?, WiFiDeviceClientScanCallback, UnsafeMutableRawPointer?) -> Int32

private typealias WiFiNetworkGetSSIDFunc = @convention(c) (WiFiNetworkRef) -> Unmanaged<CFString>?
private typealias WiFiNetworkGetBSSIDFunc = @convention(c) (WiFiNetworkRef) -> Unmanaged<CFTypeRef>?
private typealias WiFiNetworkGetPropertyFunc = @convention(c) (WiFiNetworkRef, CFString) -> Unmanaged<CFTypeRef>?

// MARK: - C Callback Handler Box
private class ScanCompletionBox {
    let handler: (Result<[ScannedNetwork], Error>) -> Void
    init(handler: @escaping (Result<[ScannedNetwork], Error>) -> Void) {
        self.handler = handler
    }
}

private let scanCallbackHandler: WiFiDeviceClientScanCallback = { device, results, error, contextToken in
    guard let token = contextToken else { return }
    let box = Unmanaged<ScanCompletionBox>.fromOpaque(token).takeRetainedValue()
    
    if let err = error {
        DispatchQueue.main.async { box.handler(.failure(err as Error)) }
        return
    }
    
    guard let results = results else {
        DispatchQueue.main.async { box.handler(.success([])) }
        return
    }
    
    var scannedList: [ScannedNetwork] = []
    let count = CFArrayGetCount(results)
    
    for i in 0..<count {
        let rawPointer = CFArrayGetValueAtIndex(results, i)
        let networkRef = unsafeBitCast(rawPointer, to: WiFiNetworkRef.self)
        
        let ssid = WiFiScanner.shared.getSSID(networkRef) ?? "[Hidden Network]"
        let bssid = WiFiScanner.shared.getBSSID(networkRef) ?? "00:00:00:00:00:00"
        let rssi = WiFiScanner.shared.getIntProperty(networkRef, key: "RSSI") ?? 0
        let channel = WiFiScanner.shared.getIntProperty(networkRef, key: "CHANNEL") ?? 0
        
        scannedList.append(ScannedNetwork(ssid: ssid, bssid: bssid, rssi: rssi, channel: channel))
    }
    
    DispatchQueue.main.async {
        box.handler(.success(scannedList))
    }
}

// MARK: - Scanner Service Singleton
final class WiFiScanner: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WiFiScanner()
    
    @Published var statusLog: String = "INITIALIZING..."
    
    private var handle: UnsafeMutableRawPointer?
    private var managerRef: WiFiManagerRef?
    private let locationManager = CLLocationManager()
    
    private var clientCreate: WiFiManagerClientCreateFunc?
    private var copyDevices: WiFiManagerClientCopyDevicesFunc?
    private var scheduleRunLoop: WiFiManagerClientScheduleWithRunLoopFunc?
    private var copyNetworksFunc: WiFiDeviceClientCopyNetworksFunc?
    private var scanAsyncFunc: WiFiDeviceClientScanAsyncFunc?
    
    private var getSSIDFunc: WiFiNetworkGetSSIDFunc?
    private var getBSSIDFunc: WiFiNetworkGetBSSIDFunc?
    private var getPropertyFunc: WiFiNetworkGetPropertyFunc?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        requestLocationPermission()
        loadFramework()
    }
    
    func requestLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func loadFramework() {
        handle = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY)
        guard let handle = handle else {
            statusLog = "ERR: MobileWiFi dlopen failed"
            return
        }
        
        clientCreate = loadSymbol("WiFiManagerClientCreate", handle: handle)
        copyDevices = loadSymbol("WiFiManagerClientCopyDevices", handle: handle)
        scheduleRunLoop = loadSymbol("WiFiManagerClientScheduleWithRunLoop", handle: handle)
        copyNetworksFunc = loadSymbol("WiFiDeviceClientCopyNetworks", handle: handle)
        scanAsyncFunc = loadSymbol("WiFiDeviceClientScanAsync", handle: handle)
        
        getSSIDFunc = loadSymbol("WiFiNetworkGetSSID", handle: handle)
        getBSSIDFunc = loadSymbol("WiFiNetworkGetBSSID", handle: handle)
        getPropertyFunc = loadSymbol("WiFiNetworkGetProperty", handle: handle)
    }
    
    private func obtainManagerHandle() -> WiFiManagerRef? {
        if let existing = managerRef {
            return existing
        }
        
        guard let clientCreate = clientCreate,
              let scheduleRunLoop = scheduleRunLoop else { return nil }
        
        // Try System Client (Type 1) first, fallback to User Client (Type 0)
        var newMgr = clientCreate(kCFAllocatorDefault, 1)
        if newMgr == nil {
            newMgr = clientCreate(kCFAllocatorDefault, 0)
        }
        
        if let mgr = newMgr {
            self.managerRef = mgr
            scheduleRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            return mgr
        }
        return nil
    }
    
    private func resetManagerHandle() {
        managerRef = nil
    }
    
    private func loadSymbol<T>(_ name: String, handle: UnsafeMutableRawPointer) -> T? {
        guard let sym = dlsym(handle, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }
    
    func performScan(completion: @escaping (Result<[ScannedNetwork], Error>) -> Void) {
        requestLocationPermission()
        
        guard let copyDevices = copyDevices else {
            let err = "MobileWiFi C symbols missing"
            statusLog = "ERR: \(err)"
            completion(.failure(NSError(domain: "WifiRecon", code: -1, userInfo: [NSLocalizedDescriptionKey: err])))
            return
        }
        
        guard var manager = obtainManagerHandle() else {
            let err = "WiFiManagerClientHandle is null"
            statusLog = "ERR: \(err)"
            completion(.failure(NSError(domain: "WifiRecon", code: -2, userInfo: [NSLocalizedDescriptionKey: err])))
            return
        }
        
        var unmanagedDevices = copyDevices(manager)
        
        // Handle recovery if IPC socket was dropped
        if unmanagedDevices == nil {
            resetManagerHandle()
            if let freshManager = obtainManagerHandle() {
                manager = freshManager
                unmanagedDevices = copyDevices(freshManager)
            }
        }
        
        guard let devicesArray = unmanagedDevices else {
            let err = "Wi-Fi radio disabled or IPC blocked (CopyDevices null)"
            statusLog = "ERR: \(err)"
            completion(.failure(NSError(domain: "WifiRecon", code: -3, userInfo: [NSLocalizedDescriptionKey: err])))
            return
        }
        
        let devices = devicesArray.takeRetainedValue()
        let deviceCount = CFArrayGetCount(devices)
        
        guard deviceCount > 0 else {
            let err = "No active Wi-Fi radio interfaces found"
            statusLog = "ERR: \(err)"
            completion(.failure(NSError(domain: "WifiRecon", code: -4, userInfo: [NSLocalizedDescriptionKey: err])))
            return
        }
        
        let rawDevice = CFArrayGetValueAtIndex(devices, 0)
        let deviceClient = unsafeBitCast(rawDevice, to: WiFiDeviceClientRef.self)
        
        // 1. Direct Network Cache Copy
        if let copyNetworks = copyNetworksFunc, let unmanagedNetworks = copyNetworks(deviceClient) {
            let netArray = unmanagedNetworks.takeRetainedValue()
            let count = CFArrayGetCount(netArray)
            
            var scannedList: [ScannedNetwork] = []
            for i in 0..<count {
                let rawNet = CFArrayGetValueAtIndex(netArray, i)
                let networkRef = unsafeBitCast(rawNet, to: WiFiNetworkRef.self)
                
                let ssid = getSSID(networkRef) ?? "[Hidden Network]"
                let bssid = getBSSID(networkRef) ?? "00:00:00:00:00:00"
                let rssi = getIntProperty(networkRef, key: "RSSI") ?? 0
                let channel = getIntProperty(networkRef, key: "CHANNEL") ?? 0
                
                scannedList.append(ScannedNetwork(ssid: ssid, bssid: bssid, rssi: rssi, channel: channel))
            }
            
            if !scannedList.isEmpty {
                statusLog = "SCAN OK: \(scannedList.count) APs"
                completion(.success(scannedList))
                return
            }
        }
        
        // 2. Active Radio Sweep
        if let scanAsync = scanAsyncFunc {
            let box = ScanCompletionBox { [weak self] result in
                switch result {
                case .success(let nets):
                    self?.statusLog = "SCAN OK: \(nets.count) APs"
                case .failure(let err):
                    self?.statusLog = "ERR: \(err.localizedDescription)"
                }
                completion(result)
            }
            
            let contextToken = Unmanaged.passRetained(box).toOpaque()
            let scanParams = NSDictionary() as CFDictionary
            
            let status = scanAsync(deviceClient, scanParams, scanCallbackHandler, contextToken)
            if status != 0 {
                _ = Unmanaged<ScanCompletionBox>.fromOpaque(contextToken).takeRetainedValue()
                let err = "WiFiDeviceClientScanAsync status \(status)"
                statusLog = "ERR: \(err)"
                completion(.failure(NSError(domain: "WifiRecon", code: Int(status), userInfo: [NSLocalizedDescriptionKey: err])))
            } else {
                statusLog = "SWEEPING SPECTRUM..."
            }
        } else {
            statusLog = "SCAN COMPLETE: 0 APs"
            completion(.success([]))
        }
    }
    
    fileprivate func getSSID(_ network: WiFiNetworkRef) -> String? {
        if let getSSIDFunc = getSSIDFunc, let unmanagedSSID = getSSIDFunc(network) {
            return unmanagedSSID.takeUnretainedValue() as String
        }
        
        guard let getPropertyFunc = getPropertyFunc,
              let unmanagedValue = getPropertyFunc(network, "SSID" as CFString) else { return nil }
        
        let value = unmanagedValue.takeUnretainedValue()
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return (value as! CFString) as String
        } else if CFGetTypeID(value) == CFDataGetTypeID() {
            let data = value as! Data
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    fileprivate func getBSSID(_ network: WiFiNetworkRef) -> String? {
        if let getBSSIDFunc = getBSSIDFunc, let unmanagedBSSID = getBSSIDFunc(network) {
            let rawBSSID = unmanagedBSSID.takeUnretainedValue()
            let typeID = CFGetTypeID(rawBSSID)
            if typeID == CFStringGetTypeID() {
                return (rawBSSID as! CFString) as String
            } else if typeID == CFDataGetTypeID() {
                let data = rawBSSID as! Data
                if data.count == 6 {
                    return data.map { String(format: "%02X", $0) }.joined(separator: ":")
                }
            }
        }
        
        guard let getPropertyFunc = getPropertyFunc,
              let unmanagedValue = getPropertyFunc(network, "BSSID" as CFString) else { return nil }
        
        let value = unmanagedValue.takeUnretainedValue()
        let typeID = CFGetTypeID(value)
        
        if typeID == CFStringGetTypeID() {
            return (value as! CFString) as String
        } else if typeID == CFDataGetTypeID() {
            let data = value as! Data
            if data.count == 6 {
                return data.map { String(format: "%02X", $0) }.joined(separator: ":")
            }
        }
        
        return nil
    }
    
    fileprivate func getIntProperty(_ network: WiFiNetworkRef, key: String) -> Int? {
        guard let getPropertyFunc = getPropertyFunc,
              let unmanagedValue = getPropertyFunc(network, key as CFString) else { return nil }
        
        let value = unmanagedValue.takeUnretainedValue()
        if CFGetTypeID(value) == CFNumberGetTypeID() {
            var intVal: Int = 0
            if CFNumberGetValue((value as! CFNumber), .sInt64Type, &intVal) {
                return intVal
            }
        }
        return nil
    }
}
