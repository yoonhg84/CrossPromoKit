import CrossPromoKit
import Foundation
import SwiftUI

/// Owns an editable copy of the demo catalog on disk.
///
/// The bundled `demo-apps.json` cannot answer the questions this demo exists to
/// answer. It is read-only, so nothing can change underneath a cache entry, and
/// its `file://` URL contains the install's bundle UUID, so a cache written by a
/// previous install is keyed to a URL that no longer exists — the trap PR #52
/// walked into. A copy in Application Support avoids both: it can be rewritten
/// at will, and it lives in the same container as the `UserDefaults` the
/// package caches into, so the catalog URL and its cache are created and
/// destroyed together.
///
/// The copy carries one extra row, `Catalog v<n>`, whose number is bumped by
/// ``bumpVersion()``. Comparing that row against ``version`` is what makes
/// cache-first loading visible: after a bump, a list still showing the old
/// number was served from the cache, and a list showing the new one was read
/// from the file.
@MainActor
@Observable
final class DemoCatalogStore {
    /// UserDefaults key holding the version currently written to the file.
    private static let versionKey = "demo.catalogVersion"

    /// Version number embedded in the file's extra row.
    private(set) var version: Int

    /// Whether the catalog file is currently on disk.
    ///
    /// Deleting it makes fetches from ``url`` fail without changing the URL, so
    /// the cache stays keyed to the same scope — the only way to exercise the
    /// package's network-failure fallback against a catalog that used to work.
    private(set) var fileExists = false

    /// The catalog URL handed to `PromoConfig`.
    let url: URL

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: Self.versionKey)
        version = stored > 0 ? stored : 1

        let directory = URL.applicationSupportDirectory.appending(path: "DemoCatalog", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appending(path: "demo-apps.json", directoryHint: .notDirectory)

        fileExists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
        if !fileExists {
            write()
        }
    }

    /// Rewrites the file with the next version number.
    func bumpVersion() {
        version += 1
        defaults.set(version, forKey: Self.versionKey)
        write()
    }

    /// Removes the file so fetches from ``url`` start failing.
    func deleteFile() {
        try? FileManager.default.removeItem(at: url)
        fileExists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    /// Writes the file back at the current version.
    func restoreFile() {
        write()
    }

    /// Writes the bundled catalog plus the version row to ``url``.
    private func write() {
        guard let source = Bundle.main.url(forResource: "demo-apps", withExtension: "json"),
              let data = try? Data(contentsOf: source),
              let bundled = try? JSONDecoder().decode(AppCatalog.self, from: data) else {
            fileExists = false
            return
        }

        let catalog = AppCatalog(
            apps: [versionRow(version)] + bundled.apps,
            promoRules: bundled.promoRules
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let encoded = try? encoder.encode(catalog),
              (try? encoded.write(to: url, options: .atomic)) != nil else {
            fileExists = false
            return
        }
        fileExists = true
    }

    /// The row that reports which version of the file a list was built from.
    ///
    /// Catalog data rather than interface text, so its strings live here beside
    /// the other fixtures instead of in the String Catalog.
    private func versionRow(_ version: Int) -> PromoApp {
        PromoApp(
            id: "catalog-version",
            name: "Catalog v\(version)",
            appStoreID: "1234567899",
            iconURL: URL(string: "sf-symbol://number.circle.fill") ?? url,
            category: "Debug",
            tagline: LocalizedText(
                en: "This row is written by the demo; its number is the file version that was loaded.",
                ko: "데모가 직접 쓴 행입니다. 숫자는 로드된 파일 버전입니다.",
                ja: "デモが書き込む行です。数字は読み込まれたファイルのバージョンです。"
            )
        )
    }
}
