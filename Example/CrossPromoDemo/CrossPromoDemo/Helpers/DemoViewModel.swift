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

    /// Launch argument that runs a verification case's setup before anything is
    /// drawn, for the same reason.
    ///
    /// `xcrun simctl launch <udid> com.finepocket.CrossPromoDemo -demoCase staleFallback`
    /// performs every step of that case and lands on the screen it is checked
    /// on, so a case that needs four ordered operations can be captured without
    /// tapping through them.
    private static let caseArgumentKey = "demoCase"

    /// Launch argument that forces which tab is shown, overriding the tab a
    /// `-demoCase` would otherwise land on: `-demoTab cases`.
    private static let tabArgumentKey = "demoTab"

    /// Launch argument that shows the promo list before landing, so the
    /// readings a case can only take *after* the list has rendered are
    /// captureable too: `-demoVisitList 1`.
    private static let visitListArgumentKey = "demoVisitList"

    /// The catalog currently handed to the package.
    var scenario: DemoScenario

    /// The tab on screen. Owned here so a case can send the person to the
    /// screen its check happens on once its setup is done.
    var selectedTab: DemoTab

    /// The case whose detail is pushed in the Cases tab, if any.
    var selectedCase: DemoVerificationCase?

    /// What the last case run did, and what the demo can see afterwards.
    ///
    /// Written by ``run(_:)`` and ``refreshObservations()`` in
    /// `DemoViewModel+Cases.swift`, so it is not `private(set)`.
    var caseRun: DemoCaseRun?

    /// The case named by `-demoCase`, until it has been run.
    private var pendingCase: DemoVerificationCase?

    /// The tab named by `-demoTab`, which outranks a case's own destination.
    private let launchTab: DemoTab?

    /// Whether `-demoVisitList` asked for a detour through the promo list.
    private let visitListOnLaunch: Bool

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

    /// Bumped to give the embedded promo view a new identity.
    ///
    /// A `MoreAppsView` keeps its `PromoService` — and with it the apps it has
    /// already loaded and the impressions it has already reported — for as long
    /// as the view exists. Most cases need a load that starts from nothing, the
    /// way reopening a settings screen in a real host app would, so their setup
    /// ends by remounting the view rather than by asking for a refresh, which
    /// would bypass the very cache tier under test.
    var listGeneration = 0

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

        let requestedCase = defaults.string(forKey: Self.caseArgumentKey)
            .flatMap(DemoVerificationCase.init(rawValue:))
        let requestedTab = defaults.string(forKey: Self.tabArgumentKey).flatMap(DemoTab.init(rawValue:))
        pendingCase = requestedCase
        launchTab = requestedTab
        visitListOnLaunch = defaults.bool(forKey: Self.visitListArgumentKey)

        // A pending case starts on the Cases tab so its setup finishes before
        // the promo list is ever built: `MoreAppsView` loads on its first
        // appearance, and appearing mid-setup would capture a half-made state.
        selectedTab = requestedTab ?? (requestedCase == nil ? .settings : .cases)
    }

    /// Runs the case named by `-demoCase`, if any, and lands on its screen.
    ///
    /// Called once from the app's root task. Does nothing without the argument,
    /// so an ordinary launch is unaffected.
    func runLaunchArgumentCase() async {
        guard let pendingCase else { return }
        self.pendingCase = nil
        selectedCase = pendingCase
        await run(pendingCase)

        // Most readings only mean something once the package has actually
        // rendered something, which needs the list on screen. This detour puts
        // it there first, so a screenshot of the readings is not stuck on
        // "nothing to judge yet" where tapping cannot be automated.
        if visitListOnLaunch {
            selectedTab = .settings
            await waitForFirstImpression()
            await refreshObservations()
        }

        selectedTab = launchTab ?? pendingCase.destination
    }

    /// Waits, briefly, for the package to report that it rendered a row.
    ///
    /// Bounded because several scenarios never render one — an empty catalog
    /// and a stalled request both legitimately produce no impression at all.
    private func waitForFirstImpression() async {
        let deadline = Date().addingTimeInterval(10)
        while eventHandler.entries.isEmpty, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
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

    /// The catalog URL for the selected scenario.
    private var catalogURL: URL? { catalogURL(for: scenario) }

    /// The catalog URL a scenario points the package at.
    ///
    /// The failing cases are ordinary URLs that happen not to answer, so the
    /// package hits its own error paths instead of the demo pretending to.
    ///
    /// Takes the scenario rather than reading ``scenario`` so a case can look at
    /// a cache it is not currently pointed at — which is the whole of the
    /// per-URL cache scoping check.
    func catalogURL(for scenario: DemoScenario) -> URL? {
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
        cacheManager(for: scenario)
    }

    /// Cache scoped to a given scenario's URL.
    func cacheManager(for scenario: DemoScenario) -> CacheManager? {
        catalogURL(for: scenario).map { CacheManager(scope: $0) }
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

    /// Marks the cached catalog stale without dropping it.
    ///
    /// The Debug tab's way of reaching the expiry path: the next load has to go
    /// to the network, but the data stays, so deleting the catalog file first
    /// shows the stale cache standing in for the failed fetch.
    func expireCache() async {
        await cacheManager?.expire()
        await refreshCacheStatus()
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
