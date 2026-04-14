import Foundation

/// Formats network speed into human-readable strings
struct SpeedFormatter {
    /// Format bytes per second into a readable string (e.g., "1.5 MB/s")
    static func format(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }
    
    /// Format for compact display (shorter)
    static func formatCompact(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0fB", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.0fK", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1fM", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.1fG", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }
}
