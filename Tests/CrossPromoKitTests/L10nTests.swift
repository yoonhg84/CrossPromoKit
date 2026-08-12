import Foundation
import Testing
@testable import CrossPromoKit

/// Verifies the bundled String Catalog is actually processed into `Bundle.module`
/// and that every UI string resolves to a translation rather than falling back to its key.
@Suite("L10n")
struct L10nTests {
    private static let keys = [
        "common.retry",
        "common.cancel",
        "emptyState.noApps.title",
        "emptyState.noApps.message",
        "emptyState.offline.title",
        "emptyState.offline.message",
        "overlayError.title",
        "overlayError.message",
        "overlayError.openInAppStore",
    ]

    @Test("every key resolves in en, ko and ja")
    func allKeysTranslatedInEveryLanguage() throws {
        for language in Locale.SupportedLanguage.allCases {
            let path = try #require(
                Bundle.module.path(forResource: language.rawValue, ofType: "lproj"),
                "missing \(language.rawValue).lproj in Bundle.module"
            )
            let bundle = try #require(Bundle(path: path))

            for key in Self.keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                #expect(value != key, "\(key) is untranslated in \(language.rawValue)")
            }
        }
    }

    @Test("L10n exposes non-empty strings")
    func accessorsReturnStrings() {
        let values = [
            L10n.retry, L10n.cancel,
            L10n.noAppsTitle, L10n.noAppsMessage,
            L10n.offlineTitle, L10n.offlineMessage,
            L10n.overlayErrorTitle, L10n.overlayErrorMessage, L10n.overlayErrorOpenInAppStore,
        ]
        for (value, key) in zip(values, Self.keys) {
            #expect(!value.isEmpty)
            #expect(value != key, "\(key) resolved to its key")
        }
    }
}
