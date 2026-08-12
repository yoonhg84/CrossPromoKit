import CryptoKit
import Foundation

/// Manages caching of app catalog data with 24-hour expiration.
/// Uses UserDefaults for persistent storage across app launches.
///
/// Cache keys are scoped to the catalog URL the data came from, so two
/// ``PromoConfig`` values in the same app keep independent caches instead of
/// overwriting each other.
public actor CacheManager {
    // MARK: - Constants

    /// Keys written by versions that cached under a single global key, and the
    /// prefixes the scoped keys are built from.
    ///
    /// The legacy entries are removed on construction so the abandoned blob does
    /// not linger in UserDefaults forever.
    enum LegacyCacheKeys {
        static let catalog = "CrossPromoKit.cachedCatalog"
        static let timestamp = "CrossPromoKit.cacheTimestamp"
    }

    /// Cache expiration time: 24 hours in seconds
    static let expirationInterval: TimeInterval = 24 * 60 * 60

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// UserDefaults key holding the encoded catalog for this scope.
    nonisolated let catalogKey: String
    /// UserDefaults key holding the cache timestamp for this scope.
    nonisolated let timestampKey: String

    // MARK: - Initialization

    /// Creates a cache scoped to a catalog URL.
    /// - Parameters:
    ///   - scope: The catalog URL whose data this cache stores. Different URLs
    ///     get different keys; the same URL resolves to the same keys on every
    ///     launch.
    ///   - userDefaults: Backing storage. Defaults to `.standard`.
    public init(scope: URL, userDefaults: UserDefaults = .standard) {
        self.init(scopeIdentifier: Self.normalize(scope), userDefaults: userDefaults)
    }

    /// Creates a cache scoped to an arbitrary identifier.
    ///
    /// Prefer ``init(scope:userDefaults:)``. This overload exists for hosts that
    /// namespace their cache by something other than the catalog URL.
    /// - Parameters:
    ///   - scopeIdentifier: A stable string identifying the cache namespace.
    ///   - userDefaults: Backing storage. Defaults to `.standard`.
    public init(scopeIdentifier: String, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()

        let digest = Self.digest(of: scopeIdentifier)
        self.catalogKey = "\(LegacyCacheKeys.catalog).\(digest)"
        self.timestampKey = "\(LegacyCacheKeys.timestamp).\(digest)"

        Self.purgeLegacyKeys(in: userDefaults)
    }

    // MARK: - Public Methods

    /// Saves the app catalog to cache with the current timestamp.
    /// - Parameter catalog: The catalog to cache
    public func save(_ catalog: AppCatalog) {
        do {
            let data = try encoder.encode(catalog)
            userDefaults.set(data, forKey: catalogKey)
            userDefaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
        } catch {
            // Silently fail on encoding errors - cache is best-effort
        }
    }

    /// Loads the cached catalog regardless of its age.
    ///
    /// Expired data is still returned: when the network is unavailable, stale
    /// promotions are better than an empty list. Use ``isExpired()`` to decide
    /// whether a network refresh is worth attempting.
    /// - Returns: The cached catalog, or nil if no cache exists or it is corrupt
    public func load() -> AppCatalog? {
        guard let data = userDefaults.data(forKey: catalogKey) else {
            return nil
        }

        do {
            return try decoder.decode(AppCatalog.self, from: data)
        } catch {
            // Corrupt data is unusable at any age - drop it
            clearCache()
            return nil
        }
    }

    /// Loads the cached catalog only if it exists and hasn't expired.
    ///
    /// Expired data is left in place so it remains available to ``load()`` as an
    /// offline fallback.
    /// - Returns: The cached catalog, or nil if not available or expired
    public func loadIfValid() -> AppCatalog? {
        guard !isExpired() else { return nil }
        return load()
    }

    /// Checks if the cache has expired (older than 24 hours).
    /// - Returns: true if cache is expired or doesn't exist
    public func isExpired() -> Bool {
        let timestamp = userDefaults.double(forKey: timestampKey)
        guard timestamp > 0 else { return true }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let age = Date().timeIntervalSince(cacheDate)

        return age >= Self.expirationInterval
    }

    /// Returns the age of the cache in seconds.
    /// - Returns: Cache age in seconds, or nil if no cache exists
    public func cacheAge() -> TimeInterval? {
        let timestamp = userDefaults.double(forKey: timestampKey)
        guard timestamp > 0 else { return nil }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(cacheDate)
    }

    /// Clears the cached data for this scope.
    public func clearCache() {
        userDefaults.removeObject(forKey: catalogKey)
        userDefaults.removeObject(forKey: timestampKey)
    }

    /// Checks if any cached data exists (regardless of expiration).
    /// - Returns: true if cached data exists
    public func hasCachedData() -> Bool {
        userDefaults.data(forKey: catalogKey) != nil
    }

    // MARK: - Key Derivation

    /// Normalizes a URL into the string the cache key is derived from.
    ///
    /// Resolving relative components keeps equivalent URLs on the same key; the
    /// result is otherwise the URL verbatim, so a query difference is a
    /// different cache.
    static func normalize(_ url: URL) -> String {
        url.absoluteURL.standardized.absoluteString
    }

    /// SHA256 of `identifier`, hex-encoded and truncated.
    ///
    /// Deliberately not `hashValue`: Swift seeds its hasher per process, so a
    /// key built from it would change on every launch and never hit the cache.
    static func digest(of identifier: String) -> String {
        SHA256.hash(data: Data(identifier.utf8))
            .prefix(16)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// Removes the pre-scoping global cache entries.
    ///
    /// Nothing reads them any more, and nothing writes them again, so a single
    /// unconditional removal is enough to keep them from being orphaned. The
    /// cost is one stale-cache miss the first time an app runs this version.
    private static func purgeLegacyKeys(in userDefaults: UserDefaults) {
        userDefaults.removeObject(forKey: LegacyCacheKeys.catalog)
        userDefaults.removeObject(forKey: LegacyCacheKeys.timestamp)
    }
}
