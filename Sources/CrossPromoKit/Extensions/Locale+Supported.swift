import Foundation

extension Locale {
    /// Supported language codes for CrossPromoKit localization.
    public enum SupportedLanguage: String, CaseIterable, Sendable {
        case english = "en"
        case korean = "ko"
        case japanese = "ja"
    }

    /// Returns the current device's supported language, defaulting to English.
    public var supportedLanguage: SupportedLanguage {
        guard let languageCode = self.language.languageCode?.identifier else {
            return .english
        }
        return SupportedLanguage(rawValue: languageCode) ?? .english
    }

    /// Checks if the current locale matches a supported language.
    public var isSupportedLanguage: Bool {
        guard let languageCode = self.language.languageCode?.identifier else {
            return false
        }
        return SupportedLanguage(rawValue: languageCode) != nil
    }
}
