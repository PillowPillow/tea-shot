import Foundation

/// What TeaShot says about its state: shown in the menu, spoken by VoiceOver.
nonisolated struct StatusText: Equatable {
    let title: String
    let subtitle: String?
    let spoken: String

    init(isActive: Bool, remaining: Duration?, endDate: Date?, startDate: Date?, in localization: Localization) {
        guard isActive else {
            title = localization("Normal sleep")
            subtitle = nil
            spoken = localization("Normal sleep, the Mac can go to sleep")
            return
        }
        if let remaining, let endDate {
            let until = localization("until \(RemainingFormat.clock(endDate, in: localization))")
            title = localization("Awake, \(RemainingFormat.spoken(remaining, in: localization)) left")
            subtitle = until
            spoken = localization("Awake for another \(RemainingFormat.accessible(remaining, in: localization)), \(until)")
        } else {
            let since = startDate.map { localization("since \(RemainingFormat.clock($0, in: localization))") }
            title = localization("Awake, no limit")
            subtitle = since
            spoken = [localization("Awake with no limit"), since].compactMap(\.self).joined(separator: ", ")
        }
    }
}
