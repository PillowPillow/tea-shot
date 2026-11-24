import Foundation
import Observation

@Observable
final class AppSettings {
    var keepDisplayAwake: Bool { didSet { defaults.set(keepDisplayAwake, forKey: Key.keepDisplayAwake) } }
    var keepDiskAwake: Bool { didSet { defaults.set(keepDiskAwake, forKey: Key.keepDiskAwake) } }
    var preventSystemSleep: Bool { didSet { defaults.set(preventSystemSleep, forKey: Key.preventSystemSleep) } }
    var showRemainingTime: Bool { didSet { defaults.set(showRemainingTime, forKey: Key.showRemainingTime) } }
    var offerExtendInReminder: Bool { didSet { defaults.set(offerExtendInReminder, forKey: Key.offerExtendInReminder) } }
    var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Key.language) } }
    /// What ⌘E starts; `nil` means no limit.
    var defaultDuration: Duration? { didSet { defaults.set(Self.seconds(defaultDuration), forKey: Key.defaultDuration) } }
    /// How long before the end the reminder fires; `.zero` disables it.
    var reminderLead: Duration { didSet { defaults.set(Self.seconds(reminderLead), forKey: Key.reminderLead) } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.keepDisplayAwake: true,
            Key.keepDiskAwake: true,
            Key.preventSystemSleep: true,
            Key.showRemainingTime: true,
            Key.offerExtendInReminder: true,
            Key.defaultDuration: 0,
            Key.reminderLead: 300,
            Key.language: AppLanguage.system.rawValue,
        ])
        keepDisplayAwake = defaults.bool(forKey: Key.keepDisplayAwake)
        keepDiskAwake = defaults.bool(forKey: Key.keepDiskAwake)
        preventSystemSleep = defaults.bool(forKey: Key.preventSystemSleep)
        showRemainingTime = defaults.bool(forKey: Key.showRemainingTime)
        offerExtendInReminder = defaults.bool(forKey: Key.offerExtendInReminder)
        let duration = defaults.integer(forKey: Key.defaultDuration)
        defaultDuration = duration > 0 ? .seconds(duration) : nil
        reminderLead = .seconds(defaults.integer(forKey: Key.reminderLead))
        language = defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var assertionKinds: Set<PowerAssertionKind> {
        var kinds: Set<PowerAssertionKind> = [.preventIdleSystemSleep]
        if keepDisplayAwake { kinds.insert(.preventDisplaySleep) }
        if keepDiskAwake { kinds.insert(.preventDiskIdle) }
        if preventSystemSleep { kinds.insert(.preventSystemSleep) }
        return kinds
    }

    private static func seconds(_ duration: Duration?) -> Int {
        Int(duration?.components.seconds ?? 0)
    }

    private enum Key {
        static let keepDisplayAwake = "keepDisplayAwake"
        static let keepDiskAwake = "keepDiskAwake"
        static let preventSystemSleep = "preventSystemSleep"
        static let showRemainingTime = "showRemainingTime"
        static let offerExtendInReminder = "offerExtendInReminder"
        static let defaultDuration = "defaultDurationSeconds"
        static let reminderLead = "reminderLeadSeconds"
        static let language = "language"
    }
}
