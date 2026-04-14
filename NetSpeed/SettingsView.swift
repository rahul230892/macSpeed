import SwiftUI
#if os(macOS)
import ServiceManagement
#endif

#if os(macOS)
/// Settings view for macOS Settings window
struct SettingsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @AppStorage("showUpload") private var showUpload = true
    @AppStorage("showDownload") private var showDownload = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Download Speed", isOn: $showDownload)
                Toggle("Show Upload Speed", isOn: $showUpload)
            } header: {
                Text("Display Options")
            } footer: {
                Text("Choose which speeds to show in the menu bar")
            }
            
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        toggleLaunchAtLogin(enabled: newValue)
                    }
            } header: {
                Text("Startup")
            } footer: {
                Text("Automatically start NetSpeed when you log in")
            }
            
            Section("Current Speed") {
                LabeledContent("Download") {
                    Text(SpeedFormatter.format(networkMonitor.downloadSpeed))
                        .font(.system(.body, design: .monospaced))
                }
                
                LabeledContent("Upload") {
                    Text(SpeedFormatter.format(networkMonitor.uploadSpeed))
                        .font(.system(.body, design: .monospaced))
                }
                
                LabeledContent("Connection") {
                    HStack {
                        Image(systemName: networkMonitor.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        Text(networkMonitor.connectionType)
                    }
                }
            }
            
            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                }
                LabeledContent("Developer") {
                    Text("NetSpeed")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 350)
        .onAppear {
            // Refresh the launch at login status when the view appears
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle launch at login: \(error.localizedDescription)")
            // Revert the toggle if the operation failed
            launchAtLogin = !enabled
        }
    }
}
#else
/// Settings view placeholder for iOS (settings are in main view)
struct SettingsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        Text("Settings")
    }
}
#endif

