@testable import CrossPromoKit
import Foundation
import Testing

/// Covers which empty state ``MoreAppsView`` shows, and the ``PromoService``
/// states that select it.
///
/// The view body itself is not exercised here — SwiftUI bodies are not
/// renderable in this test target — so the branch is tested through
/// ``MoreAppsView/emptyState(for:)``, the pure function the body switches on,
/// paired with real ``PromoService/loadApps()`` runs that produce each input.
@Suite("MoreAppsView empty state")
@MainActor
struct MoreAppsViewEmptyStateTests {
    private func makeService(
        jsonURL: URL,
        currentAppID: String = "host",
        storage: IsolatedDefaults
    ) -> PromoService {
        PromoService(
            config: PromoConfig(jsonURL: jsonURL, currentAppID: currentAppID),
            networkClient: NetworkClient(),
            cacheManager: CacheManager(scope: jsonURL, userDefaults: storage.make())
        )
    }

    private func probeCache(_ storage: IsolatedDefaults, scope: URL) -> CacheManager {
        CacheManager(scope: scope, userDefaults: storage.make())
    }

    private var missingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CrossPromoKitTests-missing-\(UUID().uuidString).json")
    }

    // MARK: - Branch selection

    @Test("No error selects the 'no apps' state")
    func noErrorSelectsNoApps() {
        #expect(MoreAppsView.emptyState(for: nil) == .noApps)
    }

    @Test("Any load error selects the offline state")
    func errorSelectsOffline() {
        #expect(MoreAppsView.emptyState(for: URLError(.notConnectedToInternet)) == .offline)
        #expect(MoreAppsView.emptyState(for: URLError(.timedOut)) == .offline)
        // Not a URLError: a malformed catalog still leaves nothing to show, and
        // retry is still the only useful action, so it shares the offline copy.
        #expect(MoreAppsView.emptyState(for: DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "bad json")
        )) == .offline)
    }

    // MARK: - Service states that reach each branch

    @Test("Tier 3 (network failed, no cache) leaves the view offline")
    func networkFailureWithoutCacheShowsOffline() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let service = makeService(jsonURL: missingURL, storage: storage)

        await service.loadApps()

        // Preconditions for the empty branch of the body.
        #expect(service.isLoading == false)
        #expect(service.apps.isEmpty)
        #expect(MoreAppsView.emptyState(for: service.error) == .offline)
    }

    @Test("An empty but successful catalog still shows 'no apps'")
    func emptyCatalogShowsNoApps() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        // Only the host app is listed, so filtering leaves nothing to promote.
        let url = try makeTemporaryFile(contents: try Fixture.json(for: Fixture.catalog(ids: ["host"])))
        defer { removeTemporaryFile(at: url) }
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.isEmpty)
        #expect(service.error == nil)
        #expect(MoreAppsView.emptyState(for: service.error) == .noApps)
    }

    @Test("The cache fallback keeps rendering the list, not an empty state")
    func cacheFallbackIsUnchanged() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let url = missingURL
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "finebill"]))
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        // The network failed, but the cache answered: `error` stays nil so the
        // body never reaches the empty branch at all.
        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
        #expect(MoreAppsView.emptyState(for: service.error) == .noApps)
    }

    @Test("A retry that succeeds clears the offline state")
    func successfulRetryLeavesOfflineState() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let failing = makeService(jsonURL: missingURL, storage: storage)
        await failing.loadApps()
        #expect(MoreAppsView.emptyState(for: failing.error) == .offline)

        // The retry button calls `loadApps()` again; once it succeeds the view
        // leaves the empty branch entirely.
        let url = try makeTemporaryFile(contents: try Fixture.json(for: Fixture.catalog(ids: ["host", "finebill"])))
        defer { removeTemporaryFile(at: url) }
        let service = makeService(jsonURL: url, storage: storage)
        await service.loadApps()

        #expect(service.apps.isEmpty == false)
        #expect(MoreAppsView.emptyState(for: service.error) == .noApps)
    }
}
