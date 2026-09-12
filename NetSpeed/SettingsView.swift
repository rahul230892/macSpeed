import SwiftUI
#if os(macOS)
import ServiceManagement
#endif

#if os(macOS)
/// Settings view for macOS Settings window
struct SettingsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    let updaterController: UpdaterController
    @AppStorage("showUpload") private var showUpload = true
    @AppStorage("showDownload") private var showDownload = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?
    @State private var isRevertingLaunchAtLogin = false
    
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
                    .onChange(of: launchAtLogin) { _, newValue in
                        if isRevertingLaunchAtLogin {
                            isRevertingLaunchAtLogin = false
                            return
                        }
                        toggleLaunchAtLogin(enabled: newValue)
                    }
                if let launchAtLoginError {
                    Label(launchAtLoginError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
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
                    Text(appVersion)
                }
                LabeledContent("Developer") {
                    Text("Rahul")
                }
                Button("Check for Updates…") {
                    updaterController.checkForUpdates()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 410)
        .onAppear {
            // Refresh the launch at login status when the view appears
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
            isRevertingLaunchAtLogin = true
            launchAtLogin = !enabled
        }
    }
}
#else
/// Settings view placeholder for iOS (settings are in main view)
struct SettingsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    let updaterController: UpdaterController
    
    var body: some View {
        Text("Settings")
    }
}
#endif
