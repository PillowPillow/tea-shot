import AppKit
import OSLog
import UserNotifications

/// Warns before a timer ends, optionally offering to extend it from the notification.
final class TimerReminder: NSObject, UNUserNotificationCenterDelegate {
    nonisolated static let extendAction = "teashot.extend"
    private nonisolated static let category = "teashot.reminder"
    private nonisolated static let requestID = "teashot.reminder"

    var onExtend: (() -> Void)?

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TeaShot", category: "TimerReminder")
    private let instance = UUID().uuidString
    private var generation = 0
    private var issued: [String] = []
    private var scheduledEnd: Date?

    override init() {
        super.init()
        center.delegate = self
        let extend = UNNotificationAction(identifier: Self.extendAction, title: "Prolonger de 30 min")
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.category, actions: [extend], intentIdentifiers: [])
        ])
        // Clears reminders left by a crash, unless another copy sharing the bundle ID (or the test host) still owns them.
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count <= 1 {
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
        }
    }

    nonisolated static func fireDate(end: Date, lead: Duration, now: Date = .now) -> Date? {
        guard lead > .zero else { return nil }
        let fire = end.addingTimeInterval(-lead.timeInterval)
        return fire > now ? fire : nil
    }

    func schedule(end: Date?, lead: Duration, offerExtend: Bool) {
        // A delivered reminder stays valid while the end date holds; only a new end date makes it stale.
        withdraw(delivered: end != scheduledEnd)
        scheduledEnd = end
        guard let end, let fire = Self.fireDate(end: end, lead: lead) else { return }

        let content = UNMutableNotificationContent()
        content.title = "TeaShot"
        content.body = "Le Mac pourra se mettre en veille dans \(RemainingFormat.spoken(lead))."
        if offerExtend { content.categoryIdentifier = Self.category }

        let scheduled = generation
        Task {
            do {
                // The authorization prompt can stay open for minutes, during which the timer may be stopped or changed.
                guard try await center.requestAuthorization(options: [.alert, .sound]), scheduled == generation else { return }
                let interval = fire.timeIntervalSinceNow
                guard interval > 0 else { return }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                // Unique per copy and generation: copies share the notification center, and a stale task must not remove a newer request.
                let identifier = "\(Self.requestID).\(instance).\(scheduled)"
                issued.append(identifier)
                try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
                if scheduled != generation {
                    center.removePendingNotificationRequests(withIdentifiers: [identifier])
                }
            } catch {
                logger.error("Reminder scheduling failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancel() {
        withdraw(delivered: true)
        scheduledEnd = nil
    }

    private func withdraw(delivered: Bool) {
        generation += 1
        center.removePendingNotificationRequests(withIdentifiers: issued)
        guard delivered else { return }
        center.removeDeliveredNotifications(withIdentifiers: issued)
        issued.removeAll()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == Self.extendAction else { return }
        await MainActor.run { onExtend?() }
    }
}
