import CrossPromoKit
import Foundation
import SwiftUI

/// Observable state shared by the demo's two tabs.
///
/// Holds the selected ``DemoScenario`` and turns it into the `PromoConfig` the
/// promo list is built from, so switching scenarios is a config swap and not a
/// change of which view is drawn.
@Observable
@MainActor
final class DemoViewModel {
    /// The app ID the demo presents itself as; excluded from every list.
    static let currentAppID = "photomagic"

    /// Launch argument that preselects a scenario, for screenshot automation.
    ///
    /// `xcrun simctl launch <udid> com.finepocket.CrossPromoDemo -demoScenario empty`
    /// lands directly on that scenario, so capturing every state does not depend
    /// on driving the picker by hand.
    private static let scenarioArgumentKey = "demoScenario"

    /// The catalog currently handed to the package.
    var scenario: DemoScenario

    /// Text of the remote URL field in the Debug tab.
    ///
    /// Kept separate from ``remoteURL`` so a half-typed URL does not rebuild the
    /// service on every keystroke; the field is committed with a button.
    var remoteURLText = ""

    /// The remote URL last committed from ``remoteURLText``.
    private(set) var remoteURL: URL?

    /// Set to true to ask the promo list for a network refresh.
    ///
    /// Bound into `MoreAppsView(forceRefresh:)`, which resets it to false once
    /// the refresh finishes — the only signal the demo has that the refresh is
    /// over, and what ``forceRefreshAndWait()`` waits on.
    var forceRefreshRequested = false

    /// The editable catalog behind ``DemoScenario/catalog``.
    let catalogStore = DemoCatalogStore()

    /// Receives impressions and taps from the package.
    ///
    /// Owned here because `PromoService.eventDelegate` is weak and this object
    /// outlives every view that passes the handler in.
    let eventHandler = DemoEventHandler()

    /// Human-readable cache status for the current scenario, refreshed by
    /// ``refreshCacheStatus()``.
    ///
    /// Stored rather than computed because ``CacheManager`` is an actor and a
    /// computed property cannot await.
    ///
    /// Typed as `LocalizedStringResource` so `Text(_:)` resolves the value through the
    /// String Catalog. A plain `String` would bypass localization entirely.
    private(set) var cacheStatus: LocalizedStringResource = "Empty (no cache)"

    init(defaults: UserDefaults = .standard) {
        let requested = defaults.string(forKey: Self.scenarioArgumentKey)
        scenario = requested.flatMap(DemoScenario.init(rawValue:)) ?? .catalog
    }

    /// Current language code
    var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "Unknown"
    }

    /// The configuration for the selected scenario, or nil when it has no URL
    /// yet (the remote scenario before a URL is committed).
    var config: PromoConfig? {
        catalogURL.map { PromoConfig(jsonURL: $0, currentAppID: Self.currentAppID) }
    }

    /// The catalog URL each scenario points the package at.
    ///
    /// The failing cases are ordinary URLs that happen not to answer, so the
    /// package hits its own error paths instead of the demo pretending to.
    private var catalogURL: URL? {
        switch scenario {
        case .catalog:
            return catalogStore.url
        case .rules:
            return Bundle.main.url(forResource: "demo-apps-rules", withExtension: "json")
        case .remoteIcons:
            return Bundle.main.url(forResource: "demo-apps-icons", withExtension: "json")
        case .empty:
            return Bundle.main.url(forResource: "demo-apps-empty", withExtension: "json")
        case .offline:
            // A path inside the app bundle that was never shipped: the fetch
            // fails, nothing is cached under this URL, and the package lands on
            // the third tier of its fallback.
            return Bundle.main.bundleURL.appending(path: "no-such-catalog.json", directoryHint: .notDirectory)
        case .stalled:
            // Unroutable per RFC 1918: packets leave and are never answered, so
            // the request hangs instead of failing fast.
            return URL(string: "https://10.255.255.1/catalog.json")
        case .remote:
            return remoteURL
        }
    }

    /// Cache scoped to the current scenario's URL.
    ///
    /// Cache keys are derived from the catalog URL, so the scope has to follow
    /// the scenario rather than being fixed to one catalog.
    private var cacheManager: CacheManager? {
        catalogURL.map { CacheManager(scope: $0) }
    }

    /// Commits ``remoteURLText`` and selects the remote scenario.
    ///
    /// Only http(s) is accepted: a bare string like "example.com" parses into a
    /// scheme-less `URL` that fails in a way that says nothing about the package.
    func loadRemoteURL() {
        let trimmed = remoteURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" else {
            remoteURL = nil
            return
        }
        remoteURL = url
        scenario = .remote
    }

    /// Reloads ``cacheStatus`` from the cache for the current scenario's URL.
    func refreshCacheStatus() async {
        guard let cacheManager else {
            cacheStatus = "Unavailable (no catalog URL)"
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

    /// Drops the cached catalog for the current scenario.
    ///
    /// Separate from a refresh on purpose: a refresh keeps the cache so it can
    /// still stand in for a failed fetch, and clearing it is what leaves the
    /// package with nothing to fall back to.
    func clearCache() async {
        await cacheManager?.clearCache()
        await refreshCacheStatus()
    }

    /// Asks the promo list to refresh and waits for it to finish.
    ///
    /// Used by pull-to-refresh, which needs the spinner to stay up until the
    /// refresh is done. The wait is a poll because the binding is the only thing
    /// `MoreAppsView` reports completion through, and it is bounded so a
    /// deliberately stalled request cannot leave the spinner up forever.
    ///
    /// The flag is always cleared at the end, including on timeout. A flag left
    /// at `true` would make every later request a no-op — `onChange` only fires
    /// on an edge — and the button would quietly stop working.
    func forceRefreshAndWait() async {
        guard config != nil else { return }
        forceRefreshRequested = true

        let deadline = Date().addingTimeInterval(90)
        while forceRefreshRequested, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
        forceRefreshRequested = false
        await refreshCacheStatus()
    }
}
