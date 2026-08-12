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
        localized(for: Locale.current.supportedLanguage)
    }

    /// Returns the text for a specific language, falling back to English when missing.
    /// - Parameter language: The language to resolve
    /// - Returns: The localized text, or the English text if unavailable
    public func localized(for language: Locale.SupportedLanguage) -> String {
        switch language {
        case .korean:
            return ko ?? en
        case .japanese:
            return ja ?? en
        case .english:
            return en
        }
    }
}
