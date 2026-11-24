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
        sleepGuard.use(settings.assertionKinds)
        reminder.onExtend = { [weak self] in self?.extend() }
        followSettings()
    }

    var isTimed: Bool { sleepGuard.isActive && sleepGuard.endDate != nil }

    var localization: Localization { Localization(settings.language) }

    var status: StatusText {
        StatusText(
            isActive: sleepGuard.isActive,
            remaining: isTimed ? sleepGuard.remaining : nil,
            endDate: sleepGuard.endDate,
            startDate: sleepGuard.startDate,
            in: localization
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
        sleepGuard.activate(for: duration, holding: settings.assertionKinds)
        guard sleepGuard.failure == nil else { return }
        chosenPreset = duration
    }

    func extend() {
        sleepGuard.extend(by: Self.extensionStep)
        chosenPreset = nil
    }

    func stop() {
        sleepGuard.deactivate()
        // The reminder observer runs on a later turn, which never comes when the app is quitting.
        reminder.cancel()
    }

    private func followSettings() {
        followAssertionSettings()
        followReminderSettings()
    }

    private func followAssertionSettings() {
        withObservationTracking {
            _ = settings.assertionKinds
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.sleepGuard.use(self.settings.assertionKinds)
                self.followAssertionSettings()
            }
        }
    }

    /// The single place that schedules the reminder: it follows the timer's end date, the reminder settings and the language.
    private func followReminderSettings() {
        withObservationTracking {
            _ = settings.reminderLead
            _ = settings.offerExtendInReminder
            _ = settings.language
            _ = sleepGuard.endDate
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.reminder.schedule(
                    end: self.sleepGuard.endDate,
                    lead: self.settings.reminderLead,
                    offerExtend: self.settings.offerExtendInReminder,
                    in: self.localization
                )
                self.followReminderSettings()
            }
        }
    }
}
