import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case english = "en"
    case french = "fr"
    case italian = "it"
    case spanish = "es"

    /// Each language names itself, so readers find their own whatever the current interface language.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .english: "English"
        case .french: "Français"
        case .italian: "Italiano"
        case .spanish: "Español"
        }
    }
}

/// Translates the interface into one language, switchable while the app runs, and formats durations and times to match it.
nonisolated struct Localization: Equatable, Sendable {
    let locale: Locale

    init(_ language: AppLanguage) {
        let code = language == .system ? Bundle.main.preferredLocalizations.first ?? "en" : language.rawValue
        // The user's region keeps their clock convention, such as 24-hour time with English text in France.
        locale = Locale(components: Locale.Components(languageCode: Locale.LanguageCode(code), languageRegion: Locale.current.region))
    }

    func callAsFunction(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }
}
