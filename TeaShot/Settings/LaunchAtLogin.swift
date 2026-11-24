import OSLog
import Observation
import ServiceManagement

@Observable
final class LaunchAtLogin {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled

    @ObservationIgnored private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TeaShot", category: "LaunchAtLogin")

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            logger.error("Login item update failed: \(error.localizedDescription, privacy: .public)")
        }

        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        isEnabled = service.status == .enabled
    }
}
