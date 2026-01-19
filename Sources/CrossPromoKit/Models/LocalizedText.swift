import Foundation

/// Localized text container with English as required fallback.
/// Supports Korean (ko), English (en), and Japanese (ja).
public struct LocalizedText: Codable, Sendable, Equatable {
    /// English text (required fallback)
    public let en: String
    /// Korean text (optional)
    public let ko: String?
    /// Japanese text (optional)
    public let ja: String?

    public init(en: String, ko: String? = nil, ja: String? = nil) {
        self.en = en
        self.ko = ko
        self.ja = ja
    }

    /// Returns the appropriate text based on device locale, falling back to English.
    public var localized: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "ko":
            return ko ?? en
        case "ja":
            return ja ?? en
        default:
            return en
        }
    }
}
