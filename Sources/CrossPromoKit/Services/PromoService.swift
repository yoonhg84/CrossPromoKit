import Foundation
import SwiftUI
import StoreKit

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
    private var catalog: AppCatalog?
    private var currentOverlay: SKOverlay?
    private var trackedImpressions: Set<String> = []

    // MARK: - Initialization

    public init(
        config: PromoConfig,
        networkClient: NetworkClient = NetworkClient(),
        cacheManager: CacheManager = CacheManager()
    ) {
        self.config = config
        self.networkClient = networkClient
        self.cacheManager = cacheManager
    }

    /// Convenience initializer with just currentAppID and default JSON URL.
    /// - Parameter currentAppID: The host app's identifier to exclude from the list
    public convenience init(currentAppID: String) {
        let defaultURL = URL(string: "https://raw.githubusercontent.com/user/repo/main/promo-catalog.json")!
        let config = PromoConfig(jsonURL: defaultURL, currentAppID: currentAppID)
        self.init(config: config)
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
            // Tier 2: Try cached data
            if let cachedCatalog = await cacheManager.loadIfValid() {
                catalog = cachedCatalog
                apps = filterApps(from: cachedCatalog)
                // Don't set error - we have valid cached data
            } else {
                // Tier 3: Empty state with error
                self.error = error
                apps = []
            }
        }

        isLoading = false
    }

    /// Forces a refresh from the network, ignoring cache.
    public func forceRefresh() async {
        // Clear cache to force network fetch
        await cacheManager.clearCache()
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

    // MARK: - Private Methods

    private func presentAppStoreOverlay(for app: PromoApp) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            handleOverlayError(for: app)
            return
        }

        let config = SKOverlay.AppConfiguration(appIdentifier: app.appStoreID, position: .bottom)
        let overlay = SKOverlay(configuration: config)
        currentOverlay = overlay
        overlay.present(in: windowScene)
    }

    private func handleOverlayError(for app: PromoApp) {
        overlayErrorAppID = app.appStoreID
        showingOverlayError = true
    }

    private func filterApps(from catalog: AppCatalog) -> [PromoApp] {
        // Exclude current app
        var filtered = catalog.apps.filter { $0.id != config.currentAppID }

        // Apply promo rules if they exist for this app
        if let rules = catalog.promoRules?[config.currentAppID] {
            filtered = filtered.filter { rules.contains($0.id) }
        }

        // Preserve JSON order (FR-016)
        return filtered
    }

    private func emit(_ event: PromoEvent) {
        eventDelegate?.promoService(self, didEmit: event)
    }
}
