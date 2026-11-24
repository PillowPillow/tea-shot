import Foundation

/// What TeaShot says about its state: shown in the menu, spoken by VoiceOver.
nonisolated struct StatusText: Equatable {
    let title: String
    let subtitle: String?
    let spoken: String

    init(isActive: Bool, remaining: Duration?, endDate: Date?, startDate: Date?) {
        guard isActive else {
            title = "Veille normale"
            subtitle = nil
            spoken = "Veille normale, le Mac peut se mettre en veille"
            return
        }
        if let remaining, let endDate {
            let until = "jusqu'à \(endDate.formatted(date: .omitted, time: .shortened))"
            title = "Éveillé, encore \(RemainingFormat.spoken(remaining))"
            subtitle = until
            spoken = "Éveillé encore \(RemainingFormat.accessible(remaining)), \(until)"
        } else {
            let since = startDate.map { "depuis \($0.formatted(date: .omitted, time: .shortened))" }
            title = "Éveillé, sans limite"
            subtitle = since
            spoken = ["Éveillé sans limite", since].compactMap(\.self).joined(separator: ", ")
        }
    }
}
