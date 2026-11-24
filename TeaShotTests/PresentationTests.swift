import AppKit
import Testing
@testable import TeaShot

struct CupLevelTests {
    @Test(arguments: [
        (1.0, 1.0), (0.9, 1.0), (0.76, 1.0),
        (0.75, 0.75), (0.6, 0.75),
        (0.5, 0.5), (0.3, 0.5),
        (0.25, 0.25), (0.01, 0.25),
        (0.0, 0.0),
    ])
    func quantizesToFiveSteps(progress: Double, expected: Double) {
        #expect(CupGlyph.level(for: progress) == expected)
    }

    @Test func glyphIsAMenuBarTemplate() {
        let glyph = CupGlyph.image(level: 0.5)

        #expect(glyph.size == NSSize(width: 18, height: 18))
        #expect(glyph.isTemplate)
    }
}

struct RemainingFormatTests {
    @Test(arguments: [
        (Duration.seconds(83 * 60), "1:23"),
        (.seconds(83 * 60 - 20), "1:23"),
        (.seconds(45 * 60), "0:45"),
        (.seconds(30), "0:01"),
        (.seconds(12 * 3600), "12:00"),
    ])
    func compactRoundsUpToTheMinute(remaining: Duration, expected: String) {
        #expect(RemainingFormat.compact(remaining) == expected)
    }

    @Test(arguments: [
        (Duration.seconds(83 * 60), "1 h 23"),
        (.seconds(2 * 3600), "2 h 00"),
        (.seconds(45 * 60), "45 min"),
        (.seconds(10), "1 min"),
    ])
    func spokenReadsNaturally(remaining: Duration, expected: String) {
        #expect(RemainingFormat.spoken(remaining) == expected)
    }
}

struct AccessibleRemainingTests {
    @Test func spellsUnitsOut() {
        let spoken = RemainingFormat.accessible(.seconds(83 * 60))
        #expect(!spoken.contains(" h "))
        #expect(spoken.contains("23"))
    }

    @Test func roundsUpLikeTheVisibleText() {
        #expect(RemainingFormat.accessible(.seconds(83 * 60 - 20)) == RemainingFormat.accessible(.seconds(83 * 60)))
    }
}

struct StatusTextTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test func atRest() {
        let status = StatusText(isActive: false, remaining: nil, endDate: nil, startDate: nil)
        #expect(status.title == "Veille normale")
        #expect(status.subtitle == nil)
        #expect(status.spoken == "Veille normale, le Mac peut se mettre en veille")
    }

    @Test func awakeWithoutLimit() {
        let status = StatusText(isActive: true, remaining: nil, endDate: nil, startDate: start)
        #expect(status.title == "Éveillé, sans limite")
        #expect(status.subtitle == "depuis \(start.formatted(date: .omitted, time: .shortened))")
        #expect(status.spoken == "Éveillé sans limite, depuis \(start.formatted(date: .omitted, time: .shortened))")
    }

    @Test func timedSpeaksUnitsInFull() {
        let end = start.addingTimeInterval(83 * 60)
        let status = StatusText(isActive: true, remaining: .seconds(83 * 60), endDate: end, startDate: start)
        let until = end.formatted(date: .omitted, time: .shortened)
        #expect(status.title == "Éveillé, encore 1 h 23")
        #expect(status.subtitle == "jusqu'à \(until)")
        #expect(status.spoken == "Éveillé encore \(RemainingFormat.accessible(.seconds(83 * 60))), jusqu'à \(until)")
    }
}

struct TimerReminderTests {
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    @Test func firesLeadTimeBeforeTheEnd() {
        let end = now.addingTimeInterval(3600)
        #expect(TimerReminder.fireDate(end: end, lead: .seconds(300), now: now) == end.addingTimeInterval(-300))
    }

    @Test func skipsWhenTheLeadIsAlreadyPast() {
        let end = now.addingTimeInterval(120)
        #expect(TimerReminder.fireDate(end: end, lead: .seconds(300), now: now) == nil)
    }

    @Test func skipsWhenDisabled() {
        let end = now.addingTimeInterval(3600)
        #expect(TimerReminder.fireDate(end: end, lead: .zero, now: now) == nil)
    }
}

struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let name = "teashot.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func defaultsMatchTheDesign() {
        let settings = AppSettings(defaults: freshDefaults())

        #expect(settings.keepDisplayAwake)
        #expect(settings.keepDiskAwake)
        #expect(settings.preventSystemSleep)
        #expect(settings.showRemainingTime)
        #expect(settings.defaultDuration == nil)
        #expect(settings.reminderLead == .seconds(300))
        #expect(settings.offerExtendInReminder)
        #expect(settings.assertionKinds == Set(PowerAssertionKind.allCases))
    }

    @Test func idleSleepIsAlwaysPrevented() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.keepDisplayAwake = false
        settings.keepDiskAwake = false
        settings.preventSystemSleep = false

        #expect(settings.assertionKinds == [.preventIdleSystemSleep])
    }

    @Test func valuesPersistAcrossInstances() {
        let defaults = freshDefaults()
        let first = AppSettings(defaults: defaults)
        first.keepDisplayAwake = false
        first.defaultDuration = .seconds(7200)
        first.reminderLead = .zero

        let second = AppSettings(defaults: defaults)

        #expect(!second.keepDisplayAwake)
        #expect(second.defaultDuration == .seconds(7200))
        #expect(second.reminderLead == .zero)
    }
}
