import Foundation
import Testing
@testable import CrossPromoKit

@Suite("CacheManager")
@MainActor
struct CacheManagerTests {
    /// Runs `body` against a cache backed by its own UserDefaults suite.
    private func withIsolatedCache(
        _ body: @MainActor (CacheManager, UserDefaults) async throws -> Void
    ) async rethrows {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        try await body(CacheManager(userDefaults: storage.make()), storage.make())
    }

    /// Backdates the stored timestamp so the cache looks `age` seconds old.
    private func backdate(_ defaults: UserDefaults, by age: TimeInterval) {
        defaults.set(Date().timeIntervalSince1970 - age, forKey: CacheManager.CacheKeys.timestamp)
    }

    // MARK: - Round Trip

    @Test("Saved catalog round-trips through load")
    func saveLoadRoundTrip() async {
        await withIsolatedCache { cache, _ in
            let catalog = Fixture.catalog(ids: ["finebill", "pocketstash"], promoRules: ["host": ["finebill"]])

            await cache.save(catalog)

            #expect(await cache.load() == catalog)
            #expect(await cache.hasCachedData())
        }
    }

    @Test("Load returns nil when nothing was cached")
    func loadWithoutCache() async {
        await withIsolatedCache { cache, _ in
            #expect(await cache.load() == nil)
            #expect(await cache.hasCachedData() == false)
            #expect(await cache.cacheAge() == nil)
        }
    }

    @Test("Corrupt cached data is dropped")
    func corruptDataIsDropped() async {
        await withIsolatedCache { cache, defaults in
            defaults.set(Data("not json".utf8), forKey: CacheManager.CacheKeys.catalog)
            defaults.set(Date().timeIntervalSince1970, forKey: CacheManager.CacheKeys.timestamp)

            #expect(await cache.load() == nil)
            #expect(await cache.hasCachedData() == false)
            #expect(await cache.cacheAge() == nil)
        }
    }

    // MARK: - Expiration

    @Test("Fresh cache is not expired")
    func freshCacheIsNotExpired() async {
        await withIsolatedCache { cache, _ in
            await cache.save(Fixture.catalog(ids: ["finebill"]))

            #expect(await cache.isExpired() == false)
            #expect((await cache.cacheAge() ?? .infinity) < 5)
        }
    }

    @Test("Missing cache counts as expired")
    func missingCacheIsExpired() async {
        await withIsolatedCache { cache, _ in
            #expect(await cache.isExpired())
        }
    }

    @Test("Cache expires at exactly 24 hours")
    func expiresAtBoundary() async {
        await withIsolatedCache { cache, defaults in
            await cache.save(Fixture.catalog(ids: ["finebill"]))

            backdate(defaults, by: CacheManager.expirationInterval - 60)
            #expect(await cache.isExpired() == false)

            backdate(defaults, by: CacheManager.expirationInterval + 60)
            #expect(await cache.isExpired())
        }
    }

    @Test("Expired cache is still returned by load but not by loadIfValid")
    func expiredCacheRemainsAsFallback() async {
        await withIsolatedCache { cache, defaults in
            let catalog = Fixture.catalog(ids: ["finebill"])
            await cache.save(catalog)
            backdate(defaults, by: CacheManager.expirationInterval + 60)

            #expect(await cache.loadIfValid() == nil)
            // Stale data survives loadIfValid so it stays available offline.
            #expect(await cache.load() == catalog)
            #expect(await cache.hasCachedData())
        }
    }

    @Test("loadIfValid returns a fresh cache")
    func loadIfValidReturnsFreshCache() async {
        await withIsolatedCache { cache, _ in
            let catalog = Fixture.catalog(ids: ["finebill"])
            await cache.save(catalog)

            #expect(await cache.loadIfValid() == catalog)
        }
    }

    // MARK: - Clearing

    @Test("clearCache removes both catalog and timestamp")
    func clearCacheRemovesEverything() async {
        await withIsolatedCache { cache, _ in
            await cache.save(Fixture.catalog(ids: ["finebill"]))

            await cache.clearCache()

            #expect(await cache.load() == nil)
            #expect(await cache.hasCachedData() == false)
            #expect(await cache.cacheAge() == nil)
            #expect(await cache.isExpired())
        }
    }

    @Test("Saving again overwrites the previous catalog")
    func saveOverwrites() async {
        await withIsolatedCache { cache, _ in
            await cache.save(Fixture.catalog(ids: ["finebill"]))
            let updated = Fixture.catalog(ids: ["pocketstash", "finebill"])

            await cache.save(updated)

            #expect(await cache.load() == updated)
        }
    }

    @Test("Separate suites do not share cached data")
    func suitesAreIsolated() async {
        let storageA = IsolatedDefaults()
        let storageB = IsolatedDefaults()
        defer {
            storageA.remove()
            storageB.remove()
        }
        let cacheA = CacheManager(userDefaults: storageA.make())
        let cacheB = CacheManager(userDefaults: storageB.make())

        await cacheA.save(Fixture.catalog(ids: ["finebill"]))

        #expect(await cacheB.load() == nil)
    }
}
