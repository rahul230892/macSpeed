import Foundation
import Network
import Combine

#if os(macOS)
import Darwin
#endif

/// Monitors network traffic and calculates real-time upload/download speeds.
/// Counters are tracked per interface so connecting or disconnecting an
/// interface does not produce a false spike or erase a complete sample.
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var uploadSpeed: Double = 0 // bytes per second
    @Published var downloadSpeed: Double = 0 // bytes per second
    @Published var isConnected: Bool = true
    @Published var connectionType: String = "Unknown"
    
    private var timer: Timer?
    private var previousCounters: [String: InterfaceCounters] = [:]
    private var lastCheckTime: Date = Date()
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    private struct InterfaceCounters {
        let received: UInt64
        let sent: UInt64
    }
    
    init() {
        setupPathMonitor()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        pathMonitor.cancel()
    }
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = "Ethernet"
                } else {
                    self.connectionType = path.status == .satisfied ? "Other" : "Offline"
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    func startMonitoring() {
        guard timer == nil else { return }

        previousCounters = getNetworkCounters()
        lastCheckTime = Date()
        
        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSpeeds()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSpeeds() {
        let currentCounters = getNetworkCounters()
        let currentTime = Date()
        
        let timeInterval = currentTime.timeIntervalSince(lastCheckTime)
        
        if timeInterval > 0 {
            var receivedDiff: UInt64 = 0
            var sentDiff: UInt64 = 0

            for (name, current) in currentCounters {
                guard let previous = previousCounters[name] else { continue }

                // A lower value indicates a reset or a wrapped legacy counter.
                // Treat it as a new baseline rather than displaying a huge spike.
                if current.received >= previous.received {
                    receivedDiff += current.received - previous.received
                }
                if current.sent >= previous.sent {
                    sentDiff += current.sent - previous.sent
                }
            }

            downloadSpeed = smoothed(previous: downloadSpeed, sample: Double(receivedDiff) / timeInterval)
            uploadSpeed = smoothed(previous: uploadSpeed, sample: Double(sentDiff) / timeInterval)
        }
        
        previousCounters = currentCounters
        lastCheckTime = currentTime
    }

    private func smoothed(previous: Double, sample: Double) -> Double {
        let smoothingFactor = 0.45
        return previous == 0 ? sample : smoothingFactor * sample + (1 - smoothingFactor) * previous
    }
    
    /// Reads counters for active physical network interfaces.
    private func getNetworkCounters() -> [String: InterfaceCounters] {
        var counters: [String: InterfaceCounters] = [:]
        
        #if os(macOS)
        // Use getifaddrs on macOS for accurate network statistics
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return [:]
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let family = interface.ifa_addr?.pointee.sa_family
            let flags = Int32(interface.ifa_flags)
            let isActive = flags & IFF_UP != 0 && flags & IFF_RUNNING != 0

            // Link-layer records contain the interface counters. Restricting the
            // default view to en* avoids counting VPN tunnel traffic twice.
            if family == UInt8(AF_LINK), isActive {
                let name = String(cString: interface.ifa_name)
                if name.hasPrefix("en"), let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    counters[name] = InterfaceCounters(
                        received: UInt64(networkData.ifi_ibytes),
                        sent: UInt64(networkData.ifi_obytes)
                    )
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        #else
        // iOS: Use a simpler approach with URLSession metrics or estimate
        // Note: iOS doesn't provide direct access to interface statistics
        // We'll use a file-based approach for demo purposes
        if let totals = readIOSNetworkCounters() {
            counters["combined"] = InterfaceCounters(
                received: totals.received,
                sent: totals.sent
            )
        }
        #endif
        
        return counters
    }
    
    #if os(iOS)
    private func readIOSNetworkCounters() -> (received: UInt64, sent: UInt64)? {
        // On iOS, we need to use the Network Extension framework or read from /proc
        // For now, use getifaddrs which works on iOS too
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)
            
            // Include WiFi (en0) and cellular (pdp_ip0) interfaces
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalReceived += UInt64(networkData.ifi_ibytes)
                    totalSent += UInt64(networkData.ifi_obytes)
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        
        return (totalReceived, totalSent)
    }
    #endif
}
