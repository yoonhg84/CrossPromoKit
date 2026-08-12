import Foundation
import Testing
@testable import CrossPromoKit

@Suite("Locale.supportedLanguage")
struct LocaleSupportedTests {
    @Test("Maps supported identifiers to their language", arguments: [
        ("en_US", Locale.SupportedLanguage.english),
        ("ko_KR", .korean),
        ("ja_JP", .japanese),
        ("ko", .korean),
        ("en", .english)
    ])
    func mapsSupportedIdentifiers(identifier: String, expected: Locale.SupportedLanguage) {
        #expect(Locale(identifier: identifier).supportedLanguage == expected)
        #expect(Locale(identifier: identifier).isSupportedLanguage)
    }

    @Test("Falls back to English for unsupported languages", arguments: [
        "fr_FR", "de_DE", "zh_Hans_CN", "es_ES"
    ])
    func fallsBackToEnglish(identifier: String) {
        let locale = Locale(identifier: identifier)

        #expect(locale.supportedLanguage == .english)
        #expect(locale.isSupportedLanguage == false)
    }

    @Test("Regional variants resolve to their base language")
    func regionalVariantsResolve() {
        #expect(Locale(identifier: "en_GB").supportedLanguage == .english)
        #expect(Locale(identifier: "ko_KP").supportedLanguage == .korean)
    }

    @Test("SupportedLanguage covers exactly en/ko/ja")
    func allCasesAreStable() {
        #expect(Set(Locale.SupportedLanguage.allCases.map(\.rawValue)) == ["en", "ko", "ja"])
    }
}
