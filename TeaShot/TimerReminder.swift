import Foundation
import OSLog
import UserNotifications

/// Warns before a timer ends, optionally offering to extend it from the notification.
final class TimerReminder: NSObject, UNUserNotificationCenterDelegate {
    nonisolated static let extendAction = "teashot.extend"
    private nonisolated static let category = "teashot.reminder"
    private nonisolated static let requestID = "teashot.reminder"

    var onExtend: (() -> Void)?

    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "local.teashot", category: "TimerReminder")

    override init() {
        super.init()
        center.delegate = self
        let extend = UNNotificationAction(identifier: Self.extendAction, title: "Prolonger de 30 min")
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Self.category, actions: [extend], intentIdentifiers: []),
        ])
    }

    nonisolated static func fireDate(end: Date, lead: Duration, now: Date = .now) -> Date? {
        guard lead > .zero else { return nil }
        let fire = end.addingTimeInterval(-lead.timeInterval)
        return fire > now ? fire : nil
    }

    func schedule(end: Date?, lead: Duration, offerExtend: Bool) {
        cancel()
        guard let end, let fire = Self.fireDate(end: end, lead: lead) else { return }

        let content = UNMutableNotificationContent()
        content.title = "TeaShot"
        content.body = "Le Mac pourra se mettre en veille dans \(RemainingFormat.spoken(lead))."
        if offerExtend { content.categoryIdentifier = Self.category }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger)

        Task {
            do {
                guard try await center.requestAuthorization(options: [.alert, .sound]) else { return }
                try await center.add(request)
            } catch {
                logger.error("Reminder scheduling failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
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
