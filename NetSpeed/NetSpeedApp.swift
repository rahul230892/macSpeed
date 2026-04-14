import SwiftUI

@main
struct NetSpeedApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    @AppStorage("showUpload") private var showUpload = true
    @AppStorage("showDownload") private var showDownload = true
    
    var body: some Scene {
        #if os(macOS)
        // Menu bar app for macOS
        MenuBarExtra {
            MenuBarView(networkMonitor: networkMonitor)
        } label: {
            Text(menuBarLabel)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        
        Settings {
            SettingsView(networkMonitor: networkMonitor)
        }
        #else
        // Regular window for iOS/iPadOS
        WindowGroup {
            ContentView(networkMonitor: networkMonitor)
        }
        #endif
    }
    
    #if os(macOS)
    private var menuBarLabel: String {
        var parts: [String] = []
        
        if showUpload {
            parts.append("↑ \(SpeedFormatter.format(networkMonitor.uploadSpeed))")
        }
        if showDownload {
            parts.append("↓ \(SpeedFormatter.format(networkMonitor.downloadSpeed))")
        }
        
        if parts.isEmpty {
            return "⚡︎"
        }
        
        return parts.joined(separator: "  ")
    }
    #endif
}
