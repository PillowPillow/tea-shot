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
    nonisolated private static let compactCases: [(Duration, String)] = [
        (.seconds(4980), "1:23"),
        (.seconds(4960), "1:23"),
        (.seconds(2700), "0:45"),
        (.seconds(30), "0:01"),
        (.seconds(43_200), "12:00"),
    ]

    nonisolated private static let spokenCases: [(Duration, String)] = [
        (.seconds(4980), "1 h 23"),
        (.seconds(7200), "2 h 00"),
        (.seconds(2700), "45 min"),
        (.seconds(10), "1 min"),
    ]

    @Test(arguments: compactCases)
    func compactRoundsUpToTheMinute(remaining: Duration, expected: String) {
        #expect(RemainingFormat.compact(remaining) == expected)
    }

    @Test(arguments: spokenCases)
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

    @Test func followsTheFrenchInterface() {
        #expect(RemainingFormat.preset(.seconds(7200)) == "2\u{A0}heures")
    }

    @Test func clockUsesTheFrenchTwentyFourHourFormat() throws {
        let afternoon = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 14, minute: 5)))
        #expect(RemainingFormat.clock(afternoon) == "14:05")
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
        #expect(status.subtitle == "depuis \(RemainingFormat.clock(start))")
        #expect(status.spoken == "Éveillé sans limite, depuis \(RemainingFormat.clock(start))")
    }

    @Test func timedSpeaksUnitsInFull() {
        let end = start.addingTimeInterval(83 * 60)
        let status = StatusText(isActive: true, remaining: .seconds(83 * 60), endDate: end, startDate: start)
        let until = RemainingFormat.clock(end)
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
