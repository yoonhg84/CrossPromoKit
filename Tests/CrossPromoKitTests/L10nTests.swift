@testable import CrossPromoKit
import Foundation
import Testing

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
        "promoRow.accessibilityLabel",
        "promoRow.accessibilityHint"
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
            L10n.promoRowLabel(name: "FineBill", category: "Finance", tagline: "Track bills"),
            L10n.promoRowHint
        ]
        #expect(values.count == Self.keys.count)
        for (value, key) in zip(values, Self.keys) {
            #expect(!value.isEmpty)
            #expect(value != key, "\(key) resolved to its key")
        }
    }

    /// Words that only belong in a load-failure message. The "no apps" state is
    /// reached *after* a successful load, so telling that user to check their
    /// connection describes a problem they do not have — the bug this guards.
    private static let networkFailureTerms = [
        "en": ["network", "connection", "couldn't load", "try again"],
        "ko": ["네트워크", "연결", "불러올 수 없"],
        "ja": ["ネットワーク", "接続", "読み込めませんでした"]
    ]

    @Test("the no-apps copy does not blame the network, and differs from the offline copy")
    func noAppsCopyDescribesAnEmptyCatalog() throws {
        for language in Locale.SupportedLanguage.allCases {
            let path = try #require(Bundle.module.path(forResource: language.rawValue, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            func value(_ key: String) -> String {
                bundle.localizedString(forKey: key, value: nil, table: nil)
            }

            let title = value("emptyState.noApps.title")
            let message = value("emptyState.noApps.message")
            let terms = try #require(Self.networkFailureTerms[language.rawValue])

            for term in terms {
                #expect(
                    !title.lowercased().contains(term),
                    "no-apps title in \(language.rawValue) reads as a load failure: \(term)"
                )
                #expect(
                    !message.lowercased().contains(term),
                    "no-apps message in \(language.rawValue) reads as a load failure: \(term)"
                )
            }

            #expect(title != value("emptyState.offline.title"))
            #expect(message != value("emptyState.offline.message"))
        }
    }

    @Test("promo row label substitutes name, category and tagline in every language")
    func promoRowLabelSubstitutesArguments() throws {
        let name = "FineBill"
        let category = "Finance"
        let tagline = "Track bills"

        for language in Locale.SupportedLanguage.allCases {
            let path = try #require(Bundle.module.path(forResource: language.rawValue, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            let format = bundle.localizedString(
                forKey: "promoRow.accessibilityLabel",
                value: nil,
                table: nil
            )

            for placeholder in ["%1$@", "%2$@", "%3$@"] {
                #expect(
                    format.contains(placeholder),
                    "\(placeholder) missing from \(language.rawValue) label format"
                )
            }

            let label = String(format: format, name, category, tagline)
            #expect(label.contains(name))
            #expect(label.contains(category))
            #expect(label.contains(tagline))
            #expect(!label.contains("%"), "unsubstituted placeholder in \(language.rawValue)")

            let nameIndex = try #require(label.range(of: name))
            let categoryIndex = try #require(label.range(of: category))
            let taglineIndex = try #require(label.range(of: tagline))
            #expect(nameIndex.lowerBound < categoryIndex.lowerBound)
            #expect(categoryIndex.lowerBound < taglineIndex.lowerBound)
        }
    }

    @Test("promo row label composed through L10n reads name first")
    func promoRowLabelThroughL10n() {
        let label = L10n.promoRowLabel(name: "FineBill", category: "Finance", tagline: "Track bills")
        #expect(label.hasPrefix("FineBill"))
        #expect(label.contains("Finance"))
        #expect(label.hasSuffix("Track bills"))
    }
}
