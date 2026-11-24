import Foundation
import Observation

/// Coordinates the sleep guard with the user's settings and the end-of-timer reminder.
@Observable
final class AppModel {
    static let extensionStep = Duration.seconds(30 * 60)

    let settings: AppSettings
    let sleepGuard: SleepGuard
    let launchAtLogin: LaunchAtLogin
    /// The preset the current timer came from, cleared once it is extended.
    private(set) var chosenPreset: Duration?

    @ObservationIgnored private let reminder: TimerReminder

    init(
        settings: AppSettings = AppSettings(),
        sleepGuard: SleepGuard = SleepGuard(),
        launchAtLogin: LaunchAtLogin = LaunchAtLogin(),
        reminder: TimerReminder = TimerReminder()
    ) {
        self.settings = settings
        self.sleepGuard = sleepGuard
        self.launchAtLogin = launchAtLogin
        self.reminder = reminder
        sleepGuard.kinds = settings.assertionKinds
        reminder.onExtend = { [weak self] in self?.extend() }
        followAssertionSettings()
    }

    var isTimed: Bool { sleepGuard.isActive && sleepGuard.endDate != nil }

    var status: StatusText {
        StatusText(
            isActive: sleepGuard.isActive,
            remaining: isTimed ? sleepGuard.remaining : nil,
            endDate: sleepGuard.endDate,
            startDate: sleepGuard.startDate
        )
    }

    func toggle() {
        if sleepGuard.isActive {
            stop()
        } else {
            start(settings.defaultDuration)
        }
    }

    func start(_ duration: Duration?) {
        sleepGuard.activate(for: duration)
        chosenPreset = duration
        rescheduleReminder()
    }

    func extend() {
        sleepGuard.extend(by: Self.extensionStep)
        chosenPreset = nil
        rescheduleReminder()
    }

    func stop() {
        sleepGuard.deactivate()
        reminder.cancel()
    }

    private func rescheduleReminder() {
        reminder.schedule(
            end: sleepGuard.endDate,
            lead: settings.reminderLead,
            offerExtend: settings.offerExtendInReminder
        )
    }

    private func followAssertionSettings() {
        withObservationTracking {
            _ = settings.assertionKinds
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.sleepGuard.kinds = self.settings.assertionKinds
                self.followAssertionSettings()
            }
        }
    }
}
