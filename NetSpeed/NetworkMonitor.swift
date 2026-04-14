import Foundation
import Network
import Combine

#if os(macOS)
import Darwin
#endif

/// Monitors network traffic and calculates real-time upload/download speeds
class NetworkMonitor: ObservableObject {
    @Published var uploadSpeed: Double = 0 // bytes per second
    @Published var downloadSpeed: Double = 0 // bytes per second
    @Published var isConnected: Bool = true
    @Published var connectionType: String = "Unknown"
    
    private var timer: Timer?
    private var lastBytesReceived: UInt64 = 0
    private var lastBytesSent: UInt64 = 0
    private var lastCheckTime: Date = Date()
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        setupPathMonitor()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        pathMonitor.cancel()
    }
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "Ethernet"
                } else {
                    self?.connectionType = "Unknown"
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    func startMonitoring() {
        // Get initial values
        let (received, sent) = getNetworkBytes()
        lastBytesReceived = received
        lastBytesSent = sent
        lastCheckTime = Date()
        
        // Update every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeeds()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSpeeds() {
        let (currentReceived, currentSent) = getNetworkBytes()
        let currentTime = Date()
        
        let timeInterval = currentTime.timeIntervalSince(lastCheckTime)
        
        if timeInterval > 0 {
            let receivedDiff = currentReceived > lastBytesReceived ? currentReceived - lastBytesReceived : 0
            let sentDiff = currentSent > lastBytesSent ? currentSent - lastBytesSent : 0
            
            DispatchQueue.main.async {
                self.downloadSpeed = Double(receivedDiff) / timeInterval
                self.uploadSpeed = Double(sentDiff) / timeInterval
            }
        }
        
        lastBytesReceived = currentReceived
        lastBytesSent = currentSent
        lastCheckTime = currentTime
    }
    
    /// Get total bytes received and sent across all network interfaces
    private func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0
        
        #if os(macOS)
        // Use getifaddrs on macOS for accurate network statistics
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback interface
            if name != "lo0" {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalReceived += UInt64(networkData.ifi_ibytes)
                    totalSent += UInt64(networkData.ifi_obytes)
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        #else
        // iOS: Use a simpler approach with URLSession metrics or estimate
        // Note: iOS doesn't provide direct access to interface statistics
        // We'll use a file-based approach for demo purposes
        if let counters = readIOSNetworkCounters() {
            totalReceived = counters.received
            totalSent = counters.sent
        }
        #endif
        
        return (totalReceived, totalSent)
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
