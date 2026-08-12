@testable import CrossPromoKit
import Foundation
import Testing

@MainActor
final class RecordingEventDelegate: PromoEventDelegate {
    private(set) var events: [PromoEvent] = []

    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        events.append(event)
    }
}

/// Records overlay presentation calls in place of the real `SKOverlay`, which
/// cannot be presented without a foreground window scene.
@MainActor
final class StubOverlayPresenter: AppStoreOverlayPresenting {
    enum Call: Equatable {
        case present(appStoreID: String)
        case dismiss
    }

    /// Controls whether ``present(appStoreID:)`` reports success, standing in
    /// for the presence or absence of a foreground window scene.
    var canPresent = true
    private(set) var calls: [Call] = []

    @discardableResult
    func present(appStoreID: String) -> Bool {
        calls.append(.present(appStoreID: appStoreID))
        return canPresent
    }

    func dismiss() {
        calls.append(.dismiss)
    }
}

@Suite("PromoService.filterApps")
@MainActor
struct PromoServiceFilterTests {
    private func service(currentAppID: String) -> PromoService {
        PromoService(config: PromoConfig(
            jsonURL: URL(string: "https://example.com/apps.json")!,
            currentAppID: currentAppID
        ))
    }

    @Test("Excludes the host app itself")
    func excludesCurrentApp() {
        let catalog = Fixture.catalog(ids: ["finebill", "pocketstash", "finetimer"])

        let filtered = service(currentAppID: "pocketstash").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["finebill", "finetimer"])
    }

    @Test("Without promoRules every other app is shown")
    func noPromoRulesShowsEverythingElse() {
        let catalog = Fixture.catalog(ids: ["finebill", "pocketstash"], promoRules: nil)

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["pocketstash"])
    }

    @Test("Applies the promoRules entry for the host app")
    func appliesPromoRules() {
        let catalog = Fixture.catalog(
            ids: ["finebill", "pocketstash", "finetimer", "finenote"],
            promoRules: ["finebill": ["finetimer", "finenote"]]
        )

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["finetimer", "finenote"])
    }

    @Test("Rules for other hosts are ignored")
    func ignoresRulesForOtherHosts() {
        let catalog = Fixture.catalog(
            ids: ["finebill", "pocketstash", "finetimer"],
            promoRules: ["pocketstash": ["finebill"]]
        )

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["pocketstash", "finetimer"])
    }

    @Test("An empty rules array hides everything")
    func emptyRulesHidesEverything() {
        let catalog = Fixture.catalog(
            ids: ["finebill", "pocketstash"],
            promoRules: ["finebill": []]
        )

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.isEmpty)
    }

    @Test("Rules naming unknown apps contribute nothing")
    func unknownRuleIDsAreIgnored() {
        let catalog = Fixture.catalog(
            ids: ["finebill", "pocketstash"],
            promoRules: ["finebill": ["pocketstash", "nonexistent"]]
        )

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["pocketstash"])
    }

    @Test("Rules cannot re-admit the host app")
    func rulesCannotReadmitHostApp() {
        let catalog = Fixture.catalog(
            ids: ["finebill", "pocketstash"],
            promoRules: ["finebill": ["finebill", "pocketstash"]]
        )

        let filtered = service(currentAppID: "finebill").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["pocketstash"])
    }

    @Test("JSON order wins over rule order (FR-016)")
    func preservesJSONOrder() {
        let catalog = Fixture.catalog(
            ids: ["appA", "appB", "appC", "appD"],
            promoRules: ["host": ["appD", "appB", "appA"]]
        )

        let filtered = service(currentAppID: "host").filterApps(from: catalog)

        #expect(filtered.map(\.id) == ["appA", "appB", "appD"])
    }

    @Test("An empty catalog yields no apps")
    func emptyCatalog() {
        let filtered = service(currentAppID: "finebill").filterApps(from: Fixture.catalog(ids: []))

        #expect(filtered.isEmpty)
    }
}

@Suite("PromoService.loadApps")
@MainActor
struct PromoServiceLoadTests {
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

    /// A cache handle for inspecting or seeding the same storage and scope the
    /// service uses.
    private func probeCache(_ storage: IsolatedDefaults, scope: URL) -> CacheManager {
        CacheManager(scope: scope, userDefaults: storage.make())
    }

    private var missingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CrossPromoKitTests-missing-\(UUID().uuidString).json")
    }

    @Test("Network success populates apps and fills the cache")
    func networkSuccessPopulatesAppsAndCache() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let catalog = Fixture.catalog(ids: ["host", "finebill", "pocketstash"])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: catalog))
        defer { removeTemporaryFile(at: url) }
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["finebill", "pocketstash"])
        #expect(service.error == nil)
        #expect(service.isLoading == false)
        #expect(await probeCache(storage, scope: url).load() == catalog)
    }

    /// Backdates the cache timestamp past the expiration window so the next load
    /// treats the entry as stale.
    private func expireCache(_ storage: IsolatedDefaults, scope: URL) {
        storage.make().set(
            Date().timeIntervalSince1970 - CacheManager.expirationInterval - 60,
            forKey: probeCache(storage, scope: scope).timestampKey
        )
    }

    @Test("Network failure falls back to cached data without surfacing an error")
    func networkFailureFallsBackToCache() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let url = missingURL
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "finebill"]))
        let service = makeService(jsonURL: url, storage: storage)

        // forceRefresh, not loadApps: the cache is still valid here, so a plain
        // load would be answered from it without ever attempting the fetch this
        // test is about.
        await service.forceRefresh()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
        #expect(service.isLoading == false)
    }

    @Test("An expired cache still serves as the offline fallback")
    func expiredCacheStillServesAsFallback() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let url = missingURL
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "finebill"]))
        expireCache(storage, scope: url)
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
    }

    @Test("After expire() a failed fetch is still covered by the retained cache")
    func expiredByAPIStillFallsBackToCache() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let url = missingURL
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "finebill"]))
        // Marks the cache stale without touching internal keys - what a host app
        // can actually do. The URL does not exist, so the load this provokes
        // fails and the retained data has to answer.
        await probeCache(storage, scope: url).expire()
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
    }

    @Test("After clearCache() the same failure leaves the empty state")
    func clearedCacheLeavesNoFallback() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let url = missingURL
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "finebill"]))
        // The contrast that motivates expire(): same setup, same failing fetch,
        // but clearing destroys the fallback.
        await probeCache(storage, scope: url).clearCache()
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.isEmpty)
        #expect(service.error != nil)
    }

    @Test("A valid cache is used as-is and the network is never consulted")
    func validCacheShortCircuitsTheNetwork() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let cached = Fixture.catalog(ids: ["host", "cached"])
        // The catalog served by the URL differs from the cached one, so a fetch
        // would be visible in both `apps` and the cache.
        let url = try makeTemporaryFile(contents: try Fixture.json(for: Fixture.catalog(ids: ["host", "remote"])))
        defer { removeTemporaryFile(at: url) }
        await probeCache(storage, scope: url).save(cached)
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["cached"])
        #expect(service.error == nil)
        #expect(service.isLoading == false)
        #expect(await probeCache(storage, scope: url).load() == cached)
    }

    @Test("An expired cache falls through to the network")
    func expiredCacheFallsThroughToTheNetwork() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let remote = Fixture.catalog(ids: ["host", "remote"])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: remote))
        defer { removeTemporaryFile(at: url) }
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "cached"]))
        expireCache(storage, scope: url)
        let service = makeService(jsonURL: url, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["remote"])
        #expect(await probeCache(storage, scope: url).load() == remote)
    }

    @Test("forceRefresh ignores a valid cache and fetches anyway")
    func forceRefreshIgnoresValidCache() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let remote = Fixture.catalog(ids: ["host", "remote"])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: remote))
        defer { removeTemporaryFile(at: url) }
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "cached"]))
        // Not expired: a plain loadApps() would stop at the cache here.
        let service = makeService(jsonURL: url, storage: storage)

        await service.forceRefresh()

        #expect(service.apps.map(\.id) == ["remote"])
        #expect(await probeCache(storage, scope: url).load() == remote)
    }

    @Test("A valid cache belonging to another catalog URL is not used")
    func validCacheIsNotSharedAcrossCatalogURLs() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let urlOne = missingURL
        let urlTwo = missingURL
        await probeCache(storage, scope: urlOne).save(Fixture.catalog(ids: ["host", "finebill"]))

        let serviceTwo = makeService(jsonURL: urlTwo, storage: storage)
        await serviceTwo.loadApps()

        #expect(serviceTwo.apps.isEmpty)
        #expect(serviceTwo.error != nil)
    }

    @Test("Network failure with no cache reports the error and shows nothing")
    func networkFailureWithoutCacheReportsError() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let service = makeService(jsonURL: missingURL, storage: storage)

        await service.loadApps()

        #expect(service.apps.isEmpty)
        #expect(service.error != nil)
        #expect(service.isLoading == false)
    }

    @Test("A later network success clears a previous error")
    func successClearsPreviousError() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let failing = makeService(jsonURL: missingURL, storage: storage)
        await failing.loadApps()
        #expect(failing.error != nil)

        let url = try makeTemporaryFile(contents: try Fixture.json(for: Fixture.catalog(ids: ["host", "finebill"])))
        defer { removeTemporaryFile(at: url) }
        let service = makeService(jsonURL: url, storage: storage)
        await service.loadApps()

        #expect(service.error == nil)
        #expect(service.apps.map(\.id) == ["finebill"])
    }

    @Test("forceRefresh overwrites the cache with fresh data")
    func forceRefreshOverwritesCache() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let fresh = Fixture.catalog(ids: ["host", "finebill"])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: fresh))
        defer { removeTemporaryFile(at: url) }
        await probeCache(storage, scope: url).save(Fixture.catalog(ids: ["host", "stale"]))
        let service = makeService(jsonURL: url, storage: storage)

        await service.forceRefresh()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(await probeCache(storage, scope: url).load() == fresh)
    }

    @Test("A failed forceRefresh leaves the cache intact")
    func failedForceRefreshKeepsCache() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let cached = Fixture.catalog(ids: ["host", "finebill"])
        let url = missingURL
        await probeCache(storage, scope: url).save(cached)
        let service = makeService(jsonURL: url, storage: storage)

        await service.forceRefresh()

        #expect(await probeCache(storage, scope: url).load() == cached)
        #expect(service.apps.map(\.id) == ["finebill"])
    }

    @Test("Two configurations in one app do not share cached catalogs")
    func separateConfigurationsKeepSeparateCaches() async throws {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let catalogOne = Fixture.catalog(ids: ["host", "finebill"])
        let urlOne = try makeTemporaryFile(contents: try Fixture.json(for: catalogOne))
        defer { removeTemporaryFile(at: urlOne) }
        let urlTwo = missingURL

        // Service one fills its own cache from the network.
        await makeService(jsonURL: urlOne, storage: storage).loadApps()
        // Service two fails and must not pick up service one's catalog.
        let serviceTwo = makeService(jsonURL: urlTwo, storage: storage)
        await serviceTwo.loadApps()

        #expect(serviceTwo.apps.isEmpty)
        #expect(serviceTwo.error != nil)
        #expect(await probeCache(storage, scope: urlOne).load() == catalogOne)
        #expect(await probeCache(storage, scope: urlTwo).load() == nil)
    }
}

@Suite("PromoService overlay presentation")
@MainActor
struct PromoServiceOverlayTests {
    private func makeService(
        presenter: StubOverlayPresenter
    ) -> (PromoService, RecordingEventDelegate) {
        let service = PromoService(
            config: PromoConfig(
                jsonURL: URL(string: "https://example.com/apps.json")!,
                currentAppID: "host"
            ),
            overlayPresenter: presenter
        )
        let delegate = RecordingEventDelegate()
        service.eventDelegate = delegate
        return (service, delegate)
    }

    @Test("A tap dismisses any previous overlay before presenting the new one")
    func tapDismissesPreviousOverlayFirst() {
        let presenter = StubOverlayPresenter()
        let (service, _) = makeService(presenter: presenter)

        service.handleAppTap(Fixture.app(id: "finebill", appStoreID: "111"))
        service.handleAppTap(Fixture.app(id: "pocketstash", appStoreID: "222"))

        #expect(presenter.calls == [
            .dismiss,
            .present(appStoreID: "111"),
            .dismiss,
            .present(appStoreID: "222")
        ])
    }

    @Test("A tap still emits its tap event")
    func tapEmitsEvent() {
        let presenter = StubOverlayPresenter()
        let (service, delegate) = makeService(presenter: presenter)

        service.handleAppTap(Fixture.app(id: "finebill"))

        #expect(delegate.events == [.tap(appID: "finebill")])
        #expect(service.showingOverlayError == false)
    }

    @Test("dismissOverlay forwards to the presenter")
    func dismissOverlayForwardsToPresenter() {
        let presenter = StubOverlayPresenter()
        let (service, _) = makeService(presenter: presenter)

        service.dismissOverlay()

        #expect(presenter.calls == [.dismiss])
    }

    @Test("A failed presentation raises the App Store fallback alert")
    func failedPresentationRaisesFallbackAlert() {
        let presenter = StubOverlayPresenter()
        presenter.canPresent = false
        let (service, _) = makeService(presenter: presenter)

        service.handleAppTap(Fixture.app(id: "finebill", appStoreID: "999"))

        #expect(service.showingOverlayError == true)
        #expect(service.overlayErrorAppID == "999")
    }

    @Test("Dismissing the overlay leaves the error alert state alone")
    func dismissOverlayDoesNotTouchErrorState() {
        let presenter = StubOverlayPresenter()
        presenter.canPresent = false
        let (service, _) = makeService(presenter: presenter)
        service.handleAppTap(Fixture.app(id: "finebill", appStoreID: "999"))

        service.dismissOverlay()

        #expect(service.showingOverlayError == true)
        #expect(service.overlayErrorAppID == "999")
    }
}

@Suite("SKOverlayPresenter")
@MainActor
struct SKOverlayPresenterTests {
    @Test("Presenting without a foreground window scene reports failure")
    func presentWithoutSceneFails() {
        #expect(SKOverlayPresenter().present(appStoreID: "123") == false)
    }

    @Test("Dismissing without a tracked overlay is a safe no-op")
    func dismissWithoutPresentedOverlayIsSafe() {
        let presenter = SKOverlayPresenter()

        presenter.dismiss()
        presenter.dismiss()

        #expect(presenter.present(appStoreID: "123") == false)
    }
}

@Suite("PromoService events")
@MainActor
struct PromoServiceEventTests {
    private func makeService() -> (PromoService, RecordingEventDelegate) {
        let service = PromoService(config: PromoConfig(
            jsonURL: URL(string: "https://example.com/apps.json")!,
            currentAppID: "host"
        ))
        let delegate = RecordingEventDelegate()
        service.eventDelegate = delegate
        return (service, delegate)
    }

    @Test("Impressions are emitted once per app per session")
    func impressionsAreDeduplicated() {
        let (service, delegate) = makeService()
        let finebill = Fixture.app(id: "finebill")
        let pocketstash = Fixture.app(id: "pocketstash")

        service.handleAppImpression(finebill)
        service.handleAppImpression(finebill)
        service.handleAppImpression(pocketstash)

        #expect(delegate.events == [.impression(appID: "finebill"), .impression(appID: "pocketstash")])
    }

    @Test("Dismissing the overlay error resets its state")
    func dismissOverlayErrorResetsState() {
        let (service, _) = makeService()

        service.dismissOverlayError()

        #expect(service.showingOverlayError == false)
        #expect(service.overlayErrorAppID == nil)
    }
}
