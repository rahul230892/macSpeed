import SwiftUI

/// Main content view for iOS/iPadOS - shows real-time speed with settings
struct ContentView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @AppStorage("showUpload") private var showUpload = true
    @AppStorage("showDownload") private var showDownload = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Connection status
                    HStack {
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                            .font(.system(size: 20))
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        
                        Text(networkMonitor.connectionType)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Speed display cards
                    VStack(spacing: 20) {
                        if showDownload {
                            SpeedCard(
                                title: "Download",
                                speed: networkMonitor.downloadSpeed,
                                icon: "arrow.down.circle.fill",
                                color: .cyan
                            )
                        }
                        
                        if showUpload {
                            SpeedCard(
                                title: "Upload",
                                speed: networkMonitor.uploadSpeed,
                                icon: "arrow.up.circle.fill",
                                color: .orange
                            )
                        }
                        
                        if !showUpload && !showDownload {
                            Text("Enable at least one speed indicator")
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    
                    Spacer()
                    
                    // Settings section
                    VStack(spacing: 16) {
                        Text("Display Options")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ToggleRow(
                            title: "Show Download Speed",
                            icon: "arrow.down.circle",
                            isOn: $showDownload,
                            color: .cyan
                        )
                        
                        ToggleRow(
                            title: "Show Upload Speed",
                            icon: "arrow.up.circle",
                            isOn: $showUpload,
                            color: .orange
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("NetSpeed")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }
}

/// Card displaying speed with icon and formatted value
struct SpeedCard: View {
    let title: String
    let speed: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            Text(SpeedFormatter.format(speed))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

/// Toggle row for settings
struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.vertical, 8)
    }
}

