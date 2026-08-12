import CrossPromoKit
import Foundation
import SwiftUI

/// Observable view model for managing demo state across views.
@Observable
@MainActor
final class DemoViewModel {
    /// Current demo state for UI testing
    var demoState: DemoState = .loaded

    /// Human-readable cache status, refreshed by ``refreshCacheStatus()``.
    ///
    /// Stored rather than computed because ``CacheManager`` is an actor and a
    /// computed property cannot await.
    ///
    /// Typed as `LocalizedStringResource` so `Text(_:)` resolves the value through the
    /// String Catalog. A plain `String` would bypass localization entirely.
    private(set) var cacheStatus: LocalizedStringResource = "Empty (no cache)"

    /// Cache scoped to the demo's catalog URL, or nil when the bundled JSON is missing.
    ///
    /// Cache keys are derived from the catalog URL, so the scope has to match the
    /// one ``SettingsView`` builds its ``PromoConfig`` with.
    private let cacheManager: CacheManager?

    init() {
        if let catalogURL = Bundle.main.url(forResource: "demo-apps", withExtension: "json") {
            cacheManager = CacheManager(scope: catalogURL)
        } else {
            cacheManager = nil
        }
    }

    /// Current language code
    var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "Unknown"
    }

    /// Reloads ``cacheStatus`` from the cache for the demo's catalog URL.
    func refreshCacheStatus() async {
        guard let cacheManager else {
            cacheStatus = "Unavailable (demo-apps.json not found)"
            return
        }

        guard let age = await cacheManager.cacheAge() else {
            cacheStatus = "Empty (no cache)"
            return
        }

        // RelativeDateTimeFormatter already localizes its own output, so only the
        // surrounding phrasing needs a catalog entry; the formatted time goes in as
        // the "%@" argument of the "Expired/Valid (cached %@)" keys.
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let cachedAt = Date().addingTimeInterval(-age)
        let relativeTime = formatter.localizedString(for: cachedAt, relativeTo: Date())

        if await cacheManager.isExpired() {
            cacheStatus = "Expired (cached \(relativeTime))"
        } else {
            cacheStatus = "Valid (cached \(relativeTime))"
        }
    }

    /// Force refresh by clearing the cache for the demo's catalog URL.
    func forceRefresh() async {
        await cacheManager?.clearCache()
        // Reset to loaded state to trigger reload
        demoState = .loaded
        await refreshCacheStatus()
    }
}
