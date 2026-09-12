import SwiftUI

#if os(macOS)
/// Animated Quit Button with red color and hover effects
struct AnimatedQuitButton: View {
    @State private var isHovered = false
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                NSApplication.shared.terminate(nil)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .bold))
                    .rotationEffect(.degrees(isHovered ? 180 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isHovered)
                
                Text("Quit NetSpeed")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: isHovered 
                            ? [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.1, blue: 0.1)]
                            : [Color(red: 0.85, green: 0.25, blue: 0.25), Color(red: 0.65, green: 0.15, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Pulsing glow when hovered
                    if isHovered {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                            .blur(radius: isPulsing ? 8 : 4)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isHovered ? Color.red.opacity(0.5) : Color.red.opacity(0.2), radius: isHovered ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
    }
}

/// Menu bar dropdown view for macOS
struct MenuBarView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    let updaterController: UpdaterController
    @AppStorage("showUpload") private var showUpload = true
    @AppStorage("showDownload") private var showDownload = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Connection status
            HStack {
                Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(networkMonitor.isConnected ? .green : .red)
                Text(networkMonitor.connectionType)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 8)
            
            Divider()
            
            // Speed display
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Download:")
                        .font(.system(size: 12))
                    Spacer()
                    Text(SpeedFormatter.format(networkMonitor.downloadSpeed))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.orange)
                    Text("Upload:")
                        .font(.system(size: 12))
                    Spacer()
                    Text(SpeedFormatter.format(networkMonitor.uploadSpeed))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
            }
            .padding(.horizontal, 8)
            
            Divider()
            
            // Display toggles
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Options")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Toggle("Show Download", isOn: $showDownload)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                
                Toggle("Show Upload", isOn: $showUpload)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            
            Divider()

            VStack(spacing: 4) {
                SettingsLink {
                    Label("Settings…", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    updaterController.checkForUpdates()
                } label: {
                    Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            Divider()
            
            // Animated Red Quit button
            AnimatedQuitButton()
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 12)
        .frame(width: 220)
    }
}
#endif
