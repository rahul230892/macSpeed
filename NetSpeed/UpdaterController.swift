import Foundation
import Sparkle

/// Owns Sparkle for the lifetime of the application and exposes the manual
/// update action used by the menu bar and Settings views.
@MainActor
final class UpdaterController {
    let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
