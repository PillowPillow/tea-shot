import Foundation

nonisolated enum RemainingFormat {
    /// Menu bar style: `1:23`.
    static func compact(_ remaining: Duration) -> String {
        let minutes = roundedUpMinutes(remaining)
        return "\(minutes / 60):\(twoDigits(minutes % 60))"
    }

    /// Sentence style: `1 h 23` or `45 min`.
    static func spoken(_ remaining: Duration, in localization: Localization) -> String {
        let minutes = roundedUpMinutes(remaining)
        return minutes >= 60 ? localization("\(minutes / 60) h \(twoDigits(minutes % 60))") : localization("\(minutes) min")
    }

    /// VoiceOver style, units spelled out: `1 hour, 23 minutes`.
    static func accessible(_ remaining: Duration, in localization: Localization) -> String {
        Duration.seconds(roundedUpMinutes(remaining) * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide).locale(localization.locale))
    }

    /// Short label for a preset: `30 minutes`, `2 hours`.
    static func preset(_ duration: Duration, in localization: Localization) -> String {
        duration.formatted(.units(allowed: [.hours, .minutes], width: .wide).locale(localization.locale))
    }

    /// Clock time: `12:43`.
    static func clock(_ date: Date, in localization: Localization) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(localization.locale))
    }

    private static func roundedUpMinutes(_ duration: Duration) -> Int {
        max(1, Int((duration.timeInterval / 60).rounded(.up)))
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
