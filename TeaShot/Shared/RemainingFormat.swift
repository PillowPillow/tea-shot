import Foundation

nonisolated enum RemainingFormat {
    /// The app's localization, not the system language, so durations and times match the French interface.
    static let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "fr")

    /// Menu bar style: `1:23`.
    static func compact(_ remaining: Duration) -> String {
        let minutes = roundedUpMinutes(remaining)
        return "\(minutes / 60):\(twoDigits(minutes % 60))"
    }

    /// Sentence style: `1 h 23` or `45 min`.
    static func spoken(_ remaining: Duration) -> String {
        let minutes = roundedUpMinutes(remaining)
        return minutes >= 60 ? "\(minutes / 60) h \(twoDigits(minutes % 60))" : "\(minutes) min"
    }

    /// VoiceOver style, units spelled out: `1 heure et 23 minutes`.
    static func accessible(_ remaining: Duration) -> String {
        Duration.seconds(roundedUpMinutes(remaining) * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide).locale(locale))
    }

    /// Short label for a preset: `30 minutes`, `2 heures`.
    static func preset(_ duration: Duration) -> String {
        duration.formatted(.units(allowed: [.hours, .minutes], width: .wide).locale(locale))
    }

    /// Clock time: `12:43`.
    static func clock(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }

    private static func roundedUpMinutes(_ duration: Duration) -> Int {
        max(1, Int((duration.timeInterval / 60).rounded(.up)))
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
