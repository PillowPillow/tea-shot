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

private let french = Localization(.french)
private let english = Localization(.english)

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
        #expect(RemainingFormat.spoken(remaining, in: french) == expected)
    }
}

struct AccessibleRemainingTests {
    @Test func spellsUnitsOut() {
        let spoken = RemainingFormat.accessible(.seconds(83 * 60), in: french)
        #expect(!spoken.contains(" h "))
        #expect(spoken.contains("23"))
    }

    @Test(arguments: [
        (AppLanguage.english, "2 hours"), (.french, "2\u{A0}heures"), (.italian, "2 ore"), (.spanish, "2 horas"),
    ])
    func followsTheInterfaceLanguage(language: AppLanguage, expected: String) {
        #expect(RemainingFormat.preset(.seconds(7200), in: Localization(language)) == expected)
    }

    @Test(arguments: [
        (AppLanguage.french, Locale.Region.france, "14:05"),
        (.english, .france, "14:05"),
        (.english, .unitedStates, "2:05\u{202F}PM"),
    ])
    func clockFollowsTheRegion(language: AppLanguage, region: Locale.Region, expected: String) throws {
        let afternoon = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 14, minute: 5)))
        #expect(RemainingFormat.clock(afternoon, in: Localization(language, region: region)) == expected)
    }

    @Test func roundsUpLikeTheVisibleText() {
        #expect(
            RemainingFormat.accessible(.seconds(83 * 60 - 20), in: french) == RemainingFormat.accessible(.seconds(83 * 60), in: french))
    }
}

struct StatusTextTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test func atRest() {
        let status = StatusText(isActive: false, remaining: nil, endDate: nil, startDate: nil, in: french)
        #expect(status.title == "Veille normale")
        #expect(status.subtitle == nil)
        #expect(status.spoken == "Veille normale, le Mac peut se mettre en veille")
    }

    @Test func awakeWithoutLimit() {
        let status = StatusText(isActive: true, remaining: nil, endDate: nil, startDate: start, in: french)
        let since = RemainingFormat.clock(start, in: french)
        #expect(status.title == "Éveillé, sans limite")
        #expect(status.subtitle == "depuis \(since)")
        #expect(status.spoken == "Éveillé sans limite, depuis \(since)")
    }

    @Test func timedSpeaksUnitsInFull() {
        let end = start.addingTimeInterval(83 * 60)
        let status = StatusText(isActive: true, remaining: .seconds(83 * 60), endDate: end, startDate: start, in: french)
        let until = RemainingFormat.clock(end, in: french)
        #expect(status.title == "Éveillé, encore 1 h 23")
        #expect(status.subtitle == "jusqu'à \(until)")
        #expect(status.spoken == "Éveillé encore \(RemainingFormat.accessible(.seconds(83 * 60), in: french)), jusqu'à \(until)")
    }

    @Test func timedInEnglish() {
        let end = start.addingTimeInterval(83 * 60)
        let status = StatusText(isActive: true, remaining: .seconds(83 * 60), endDate: end, startDate: start, in: english)
        let until = RemainingFormat.clock(end, in: english)
        #expect(status.title == "Awake, 1 h 23 left")
        #expect(status.subtitle == "until \(until)")
        #expect(status.spoken == "Awake for another 1 hour, 23 minutes, until \(until)")
    }
}

struct LocalizationTests {
    @Test(arguments: [
        (AppLanguage.english, "Stop"), (.french, "Arrêter"), (.italian, "Interrompi"), (.spanish, "Detener"),
    ])
    func translatesIntoTheChosenLanguage(language: AppLanguage, expected: String) {
        #expect(Localization(language)("Stop") == expected)
    }

    @Test func systemFollowsTheAppLocalization() {
        let code = Bundle.main.preferredLocalizations.first
        #expect(Localization(.system).locale.language.languageCode?.identifier == code)
    }

    @Test func keepsTheUserRegion() {
        #expect(Localization(.english).locale.region == Locale.current.region)
    }

    @Test func interpolatesTypedArguments() {
        let error = PowerAssertionError(kind: .preventDiskIdle, code: -536_870_212)
        #expect(error.message(in: Localization(.italian)) == "Impossibile creare l'asserzione PreventDiskIdle (codice -536870212).")
    }

    @Test func everyLanguageNamesItself() {
        let named = AppLanguage.allCases.filter { $0 != .system }
        #expect(named.allSatisfy { $0.nativeName != nil })
        #expect(AppLanguage.system.nativeName == nil)
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

// One fixed suite, reset per test: macOS keeps an empty plist for every removed domain.
@Suite(.serialized)
struct AppSettingsTests {
    nonisolated private static let suiteName = "teashot.tests"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: Self.suiteName)!
        defaults.removePersistentDomain(forName: Self.suiteName)
    }

    @Test func defaultsMatchTheDesign() {
        let settings = AppSettings(defaults: defaults)

        #expect(settings.keepDisplayAwake)
        #expect(settings.keepDiskAwake)
        #expect(settings.preventSystemSleep)
        #expect(settings.showRemainingTime)
        #expect(settings.defaultDuration == nil)
        #expect(settings.reminderLead == .seconds(300))
        #expect(settings.offerExtendInReminder)
        #expect(settings.language == .system)
        #expect(settings.assertionKinds == Set(PowerAssertionKind.allCases))
    }

    @Test func idleSleepIsAlwaysPrevented() {
        let settings = AppSettings(defaults: defaults)
        settings.keepDisplayAwake = false
        settings.keepDiskAwake = false
        settings.preventSystemSleep = false

        #expect(settings.assertionKinds == [.preventIdleSystemSleep])
    }

    @Test func valuesPersistAcrossInstances() {
        let first = AppSettings(defaults: defaults)
        first.keepDisplayAwake = false
        first.defaultDuration = .seconds(7200)
        first.reminderLead = .zero
        first.language = .italian

        let second = AppSettings(defaults: defaults)

        #expect(!second.keepDisplayAwake)
        #expect(second.defaultDuration == .seconds(7200))
        #expect(second.reminderLead == .zero)
        #expect(second.language == .italian)
    }
}
