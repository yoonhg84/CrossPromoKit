import Foundation
import Testing
@testable import CrossPromoKit

@Suite("LocalizedText")
struct LocalizedTextTests {
    private let full = LocalizedText(en: "Track your bills", ko: "청구서 관리", ja: "請求書の管理")
    private let englishOnly = LocalizedText(en: "Track your bills")

    @Test("Returns the language-specific text when present")
    func returnsLanguageSpecificText() {
        #expect(full.localized(for: .english) == "Track your bills")
        #expect(full.localized(for: .korean) == "청구서 관리")
        #expect(full.localized(for: .japanese) == "請求書の管理")
    }

    @Test("Falls back to English when the translation is missing")
    func fallsBackToEnglish() {
        #expect(englishOnly.localized(for: .korean) == "Track your bills")
        #expect(englishOnly.localized(for: .japanese) == "Track your bills")
    }

    @Test("Falls back per language, not all-or-nothing")
    func fallsBackPerLanguage() {
        let koreanOnly = LocalizedText(en: "Track your bills", ko: "청구서 관리")
        #expect(koreanOnly.localized(for: .korean) == "청구서 관리")
        #expect(koreanOnly.localized(for: .japanese) == "Track your bills")
    }

    @Test("localized resolves through the current locale")
    func localizedUsesCurrentLocale() {
        // Locale.current is process-wide and not injectable, so assert the
        // property agrees with the explicit lookup for whatever locale is active.
        #expect(full.localized == full.localized(for: Locale.current.supportedLanguage))
    }

    @Test("Decodes from JSON with optional translations omitted")
    func decodesFromJSON() throws {
        let json = Data(#"{"en":"Hello","ko":"안녕"}"#.utf8)
        let text = try JSONDecoder().decode(LocalizedText.self, from: json)

        #expect(text.en == "Hello")
        #expect(text.ko == "안녕")
        #expect(text.ja == nil)
        #expect(text.localized(for: .japanese) == "Hello")
    }
}
