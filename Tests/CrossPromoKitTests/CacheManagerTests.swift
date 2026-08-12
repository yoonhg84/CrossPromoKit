import Foundation
import Testing
@testable import CrossPromoKit

@Suite("CacheManager")
@MainActor
struct CacheManagerTests {
    static let scope = URL(string: "https://example.com/apps.json")!

    /// Runs `body` against a cache backed by its own UserDefaults suite.
    private func withIsolatedCache(
        scope: URL = CacheManagerTests.scope,
        _ body: @MainActor (CacheManager, UserDefaults) async throws -> Void
    ) async rethrows {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        try await body(CacheManager(scope: scope, userDefaults: storage.make()), storage.make())
    }

    /// Backdates the stored timestamp so the cache looks `age` seconds old.
    private func backdate(_ cache: CacheManager, _ defaults: UserDefaults, by age: TimeInterval) {
        defaults.set(Date().timeIntervalSince1970 - age, forKey: cache.timestampKey)
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
            defaults.set(Data("not json".utf8), forKey: cache.catalogKey)
            defaults.set(Date().timeIntervalSince1970, forKey: cache.timestampKey)

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

            backdate(cache, defaults, by: CacheManager.expirationInterval - 60)
            #expect(await cache.isExpired() == false)

            backdate(cache, defaults, by: CacheManager.expirationInterval + 60)
            #expect(await cache.isExpired())
        }
    }

    @Test("Expired cache is still returned by load but not by loadIfValid")
    func expiredCacheRemainsAsFallback() async {
        await withIsolatedCache { cache, defaults in
            let catalog = Fixture.catalog(ids: ["finebill"])
            await cache.save(catalog)
            backdate(cache, defaults, by: CacheManager.expirationInterval + 60)

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
        let cacheA = CacheManager(scope: Self.scope, userDefaults: storageA.make())
        let cacheB = CacheManager(scope: Self.scope, userDefaults: storageB.make())

        await cacheA.save(Fixture.catalog(ids: ["finebill"]))

        #expect(await cacheB.load() == nil)
    }
}

// MARK: - Scoping

@Suite("CacheManager scoping")
@MainActor
struct CacheManagerScopeTests {
    private let catalogA = URL(string: "https://example.com/a/apps.json")!
    private let catalogB = URL(string: "https://example.com/b/apps.json")!

    @Test("Different catalog URLs do not share a cache")
    func differentURLsDoNotCollide() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let cacheA = CacheManager(scope: catalogA, userDefaults: storage.make())
        let cacheB = CacheManager(scope: catalogB, userDefaults: storage.make())
        let catalog = Fixture.catalog(ids: ["finebill"])

        await cacheA.save(catalog)

        // Same UserDefaults, different scope: B must not see A's data.
        #expect(await cacheB.load() == nil)
        #expect(await cacheB.hasCachedData() == false)
        #expect(await cacheB.isExpired())
        #expect(await cacheA.load() == catalog)
    }

    @Test("Clearing one scope leaves the other intact")
    func clearingOneScopeKeepsTheOther() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let cacheA = CacheManager(scope: catalogA, userDefaults: storage.make())
        let cacheB = CacheManager(scope: catalogB, userDefaults: storage.make())
        let catalogForB = Fixture.catalog(ids: ["pocketstash"])
        await cacheA.save(Fixture.catalog(ids: ["finebill"]))
        await cacheB.save(catalogForB)

        await cacheA.clearCache()

        #expect(await cacheA.load() == nil)
        #expect(await cacheB.load() == catalogForB)
    }

    @Test("The same URL round-trips through a freshly built cache")
    func sameURLRoundTrips() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let catalog = Fixture.catalog(ids: ["finebill", "pocketstash"])

        await CacheManager(scope: catalogA, userDefaults: storage.make()).save(catalog)

        // A separate instance stands in for the next app launch.
        let reopened = CacheManager(scope: catalogA, userDefaults: storage.make())
        #expect(await reopened.load() == catalog)
        #expect(await reopened.loadIfValid() == catalog)
    }

    @Test("Keys are derived deterministically, not from a per-process hash seed")
    func keysAreStable() {
        let first = CacheManager.digest(of: CacheManager.normalize(catalogA))
        let second = CacheManager.digest(of: CacheManager.normalize(catalogA))

        #expect(first == second)
        // SHA256 truncated to 16 bytes, hex encoded.
        #expect(first.count == 32)
        #expect(first != CacheManager.digest(of: CacheManager.normalize(catalogB)))
    }

    @Test("Equivalent URLs normalize to the same scope")
    func equivalentURLsShareAScope() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let messy = URL(string: "https://example.com/a/../a/apps.json")!
        let catalog = Fixture.catalog(ids: ["finebill"])

        await CacheManager(scope: catalogA, userDefaults: storage.make()).save(catalog)

        #expect(await CacheManager(scope: messy, userDefaults: storage.make()).load() == catalog)
    }

    @Test("Query strings distinguish scopes")
    func queryStringsAreSignificant() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let versioned = URL(string: "https://example.com/a/apps.json?v=2")!

        await CacheManager(scope: catalogA, userDefaults: storage.make())
            .save(Fixture.catalog(ids: ["finebill"]))

        #expect(await CacheManager(scope: versioned, userDefaults: storage.make()).load() == nil)
    }

    @Test("Pre-scoping global cache entries are purged")
    func legacyKeysArePurged() async {
        let storage = IsolatedDefaults()
        defer { storage.remove() }
        let seeded = storage.make()
        seeded.set(Data("{}".utf8), forKey: CacheManager.LegacyCacheKeys.catalog)
        seeded.set(Date().timeIntervalSince1970, forKey: CacheManager.LegacyCacheKeys.timestamp)

        _ = CacheManager(scope: catalogA, userDefaults: storage.make())

        let probe = storage.make()
        #expect(probe.object(forKey: CacheManager.LegacyCacheKeys.catalog) == nil)
        #expect(probe.object(forKey: CacheManager.LegacyCacheKeys.timestamp) == nil)
    }
}
