import Foundation
import SwiftUI

/// Main service for managing cross-promotion functionality.
/// Handles fetching, caching, and filtering of promotable apps.
@MainActor
@Observable
public final class PromoService: Sendable {
    // MARK: - Public Properties

    /// Current list of filtered apps to display
    public private(set) var apps: [PromoApp] = []

    /// Loading state indicator
    public private(set) var isLoading = false

    /// Error state for display
    public private(set) var error: Error?

    /// Event delegate for analytics
    public weak var eventDelegate: PromoEventDelegate?

    /// Tracks whether the overlay failed to show (for fallback handling)
    public private(set) var showingOverlayError = false

    /// App ID for the overlay error alert
    public private(set) var overlayErrorAppID: String?

    // MARK: - Private Properties

    private let config: PromoConfig
    private let networkClient: NetworkClient
    private let cacheManager: CacheManager
    private let overlayPresenter: AppStoreOverlayPresenting
    private var catalog: AppCatalog?
    private var trackedImpressions: Set<String> = []

    // MARK: - Initialization

    /// Creates a service for the given configuration.
    /// - Parameters:
    ///   - config: The catalog URL and host app identifier.
    ///   - networkClient: The client used to fetch the catalog.
    ///   - cacheManager: Cache to read and write. Defaults to one scoped to
    ///     `config.jsonURL`, so services built from different configurations do
    ///     not share cache entries.
    public convenience init(
        config: PromoConfig,
        networkClient: NetworkClient = NetworkClient(),
        cacheManager: CacheManager? = nil
    ) {
        self.init(
            config: config,
            networkClient: networkClient,
            cacheManager: cacheManager,
            overlayPresenter: SKOverlayPresenter()
        )
    }

    /// Designated initializer allowing the overlay presenter to be substituted in tests.
    init(
        config: PromoConfig,
        networkClient: NetworkClient = NetworkClient(),
        cacheManager: CacheManager? = nil,
        overlayPresenter: AppStoreOverlayPresenting
    ) {
        self.config = config
        self.networkClient = networkClient
        self.cacheManager = cacheManager ?? CacheManager(scope: config.jsonURL)
        self.overlayPresenter = overlayPresenter
    }

    // MARK: - Public Methods

    /// Loads apps using three-tier fallback: Network → Cache → Empty State.
    /// Automatically saves successful network responses to cache.
    public func loadApps() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        // Tier 1: Try network fetch
        do {
            let fetchedCatalog = try await networkClient.fetchCatalog(from: config.jsonURL)
            catalog = fetchedCatalog
            apps = filterApps(from: fetchedCatalog)

            // Save to cache on successful network fetch
            await cacheManager.save(fetchedCatalog)
        } catch {
            // Tier 2: Fall back to cached data, even if expired - stale
            // promotions are more useful than an empty list while offline
            if let cachedCatalog = await cacheManager.load() {
                catalog = cachedCatalog
                apps = filterApps(from: cachedCatalog)
                // Don't set error - we have cached data to show
            } else {
                // Tier 3: Empty state with error
                self.error = error
                apps = []
            }
        }

        isLoading = false
    }

    /// Forces a refresh from the network, ignoring cache.
    ///
    /// The existing cache is kept so it can still serve as a fallback if the
    /// network fetch fails; a successful fetch overwrites it.
    public func forceRefresh() async {
        await loadApps()
    }

    /// Handles app row tap event and presents App Store overlay.
    /// - Parameter app: The app that was tapped
    public func handleAppTap(_ app: PromoApp) {
        emit(.tap(appID: app.id))
        presentAppStoreOverlay(for: app)
    }

    /// Handles app row appearance for impression tracking.
    /// - Parameter app: The app that appeared
    public func handleAppImpression(_ app: PromoApp) {
        // Only track each impression once per session
        guard !trackedImpressions.contains(app.id) else { return }
        trackedImpressions.insert(app.id)
        emit(.impression(appID: app.id))
    }

    /// Dismisses the App Store overlay this service is currently presenting, if any.
    ///
    /// The overlay lives on the window scene rather than on any particular view,
    /// so it outlives the view that triggered it. Call this when the promo UI
    /// goes away — ``MoreAppsView`` does so on `onDisappear`. Calling it when no
    /// overlay is presented is a no-op.
    public func dismissOverlay() {
        overlayPresenter.dismiss()
    }

    /// Dismisses the current overlay error alert.
    public func dismissOverlayError() {
        showingOverlayError = false
        overlayErrorAppID = nil
    }

    /// Opens the App Store directly for the specified app.
    /// - Parameter appID: The App Store ID of the app
    public func openAppStoreDirectly(appStoreID: String) {
        let urlString = "https://apps.apple.com/app/id\(appStoreID)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Internal Methods

    /// Filters the catalog down to the apps this host app should promote.
    ///
    /// Removes the host app itself, applies `promoRules` when the catalog
    /// defines them for this host, and preserves the catalog's JSON order (FR-016).
    /// - Parameter catalog: The catalog to filter
    /// - Returns: The apps to display, in catalog order
    func filterApps(from catalog: AppCatalog) -> [PromoApp] {
        // Exclude current app
        var filtered = catalog.apps.filter { $0.id != config.currentAppID }

        // Apply promo rules if they exist for this app
        if let rules = catalog.promoRules?[config.currentAppID] {
            filtered = filtered.filter { rules.contains($0.id) }
        }

        // Preserve JSON order (FR-016)
        return filtered
    }

    // MARK: - Private Methods

    private func presentAppStoreOverlay(for app: PromoApp) {
        // Tapping a second app while an overlay is up would otherwise stack a new
        // overlay on top of the old one, so retire the previous one first.
        overlayPresenter.dismiss()

        guard overlayPresenter.present(appStoreID: app.appStoreID) else {
            handleOverlayError(for: app)
            return
        }
    }

    private func handleOverlayError(for app: PromoApp) {
        overlayErrorAppID = app.appStoreID
        showingOverlayError = true
    }

    private func emit(_ event: PromoEvent) {
        eventDelegate?.promoService(self, didEmit: event)
    }
}
