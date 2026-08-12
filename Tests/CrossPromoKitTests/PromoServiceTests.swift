import Foundation
import Testing
@testable import CrossPromoKit

@MainActor
final class RecordingEventDelegate: PromoEventDelegate {
    private(set) var events: [PromoEvent] = []

    func promoService(_ service: PromoService, didEmit event: PromoEvent) {
        events.append(event)
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
            cacheManager: CacheManager(userDefaults: storage.make())
        )
    }

    /// A cache handle for inspecting or seeding the same storage the service uses.
    private func probeCache(_ storage: IsolatedDefaults) -> CacheManager {
        CacheManager(userDefaults: storage.make())
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
        #expect(await probeCache(storage).load() == catalog)
    }

    @Test("Network failure falls back to cached data without surfacing an error")
    func networkFailureFallsBackToCache() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        await probeCache(storage).save(Fixture.catalog(ids: ["host", "finebill"]))
        let service = makeService(jsonURL: missingURL, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
        #expect(service.isLoading == false)
    }

    @Test("An expired cache still serves as the offline fallback")
    func expiredCacheStillServesAsFallback() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        await probeCache(storage).save(Fixture.catalog(ids: ["host", "finebill"]))
        storage.make().set(
            Date().timeIntervalSince1970 - CacheManager.expirationInterval - 60,
            forKey: CacheManager.CacheKeys.timestamp
        )
        let service = makeService(jsonURL: missingURL, storage: storage)

        await service.loadApps()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(service.error == nil)
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
        await probeCache(storage).save(Fixture.catalog(ids: ["host", "stale"]))
        let fresh = Fixture.catalog(ids: ["host", "finebill"])
        let url = try makeTemporaryFile(contents: try Fixture.json(for: fresh))
        defer { removeTemporaryFile(at: url) }
        let service = makeService(jsonURL: url, storage: storage)

        await service.forceRefresh()

        #expect(service.apps.map(\.id) == ["finebill"])
        #expect(await probeCache(storage).load() == fresh)
    }

    @Test("A failed forceRefresh leaves the cache intact")
    func failedForceRefreshKeepsCache() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let cached = Fixture.catalog(ids: ["host", "finebill"])
        await probeCache(storage).save(cached)
        let service = makeService(jsonURL: missingURL, storage: storage)

        await service.forceRefresh()

        #expect(await probeCache(storage).load() == cached)
        #expect(service.apps.map(\.id) == ["finebill"])
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
