import Foundation
@testable import CrossPromoKit

// MARK: - Model Fixtures

enum Fixture {
    static func app(
        id: String,
        name: String? = nil,
        appStoreID: String = "123456789",
        category: String = "생산성",
        tagline: LocalizedText = LocalizedText(en: "Tagline")
    ) -> PromoApp {
        PromoApp(
            id: id,
            name: name ?? id.capitalized,
            appStoreID: appStoreID,
            iconURL: URL(string: "https://example.com/\(id).png")!,
            category: category,
            tagline: tagline
        )
    }

    static func catalog(
        ids: [String],
        promoRules: [String: [String]]? = nil
    ) -> AppCatalog {
        AppCatalog(apps: ids.map { app(id: $0) }, promoRules: promoRules)
    }

    static func json(for catalog: AppCatalog) throws -> Data {
        try JSONEncoder().encode(catalog)
    }
}

// MARK: - Temporary Files

/// Writes `data` to a unique temporary file and returns its `file://` URL.
/// The caller is responsible for removing it via ``removeTemporaryFile(at:)``.
func makeTemporaryFile(contents data: Data, extension ext: String = "json") throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("CrossPromoKitTests-\(UUID().uuidString).\(ext)")
    try data.write(to: url)
    return url
}

func removeTemporaryFile(at url: URL) {
    try? FileManager.default.removeItem(at: url)
}

// MARK: - Isolated UserDefaults

/// A uniquely named `UserDefaults` suite so tests never touch the shared
/// standard defaults or each other's state.
///
/// ``make()`` hands out a fresh instance per call: `CacheManager` takes
/// ownership of the one it is given, so test-side pokes at the same storage use
/// a separate handle rather than sharing one across isolation domains.
struct IsolatedDefaults: Sendable {
    let suiteName = "CrossPromoKitTests.\(UUID().uuidString)"

    func make() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite \(suiteName)")
        }
        return defaults
    }

    func remove() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}
