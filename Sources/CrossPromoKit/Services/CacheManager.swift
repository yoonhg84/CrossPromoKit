import Foundation

/// Manages caching of app catalog data with 24-hour expiration.
/// Uses UserDefaults for persistent storage across app launches.
public actor CacheManager: Sendable {
    // MARK: - Constants

    private enum CacheKeys {
        static let catalog = "CrossPromoKit.cachedCatalog"
        static let timestamp = "CrossPromoKit.cacheTimestamp"
    }

    /// Cache expiration time: 24 hours in seconds
    private static let expirationInterval: TimeInterval = 24 * 60 * 60

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Public Methods

    /// Saves the app catalog to cache with the current timestamp.
    /// - Parameter catalog: The catalog to cache
    public func save(_ catalog: AppCatalog) {
        do {
            let data = try encoder.encode(catalog)
            userDefaults.set(data, forKey: CacheKeys.catalog)
            userDefaults.set(Date().timeIntervalSince1970, forKey: CacheKeys.timestamp)
        } catch {
            // Silently fail on encoding errors - cache is best-effort
        }
    }

    /// Loads the cached catalog if it exists and hasn't expired.
    /// - Returns: The cached catalog, or nil if not available or expired
    public func loadIfValid() -> AppCatalog? {
        guard let data = userDefaults.data(forKey: CacheKeys.catalog) else {
            return nil
        }

        guard !isExpired() else {
            clearCache()
            return nil
        }

        do {
            return try decoder.decode(AppCatalog.self, from: data)
        } catch {
            clearCache()
            return nil
        }
    }

    /// Checks if the cache has expired (older than 24 hours).
    /// - Returns: true if cache is expired or doesn't exist
    public func isExpired() -> Bool {
        let timestamp = userDefaults.double(forKey: CacheKeys.timestamp)
        guard timestamp > 0 else { return true }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let age = Date().timeIntervalSince(cacheDate)

        return age >= Self.expirationInterval
    }

    /// Returns the age of the cache in seconds.
    /// - Returns: Cache age in seconds, or nil if no cache exists
    public func cacheAge() -> TimeInterval? {
        let timestamp = userDefaults.double(forKey: CacheKeys.timestamp)
        guard timestamp > 0 else { return nil }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(cacheDate)
    }

    /// Clears all cached data.
    public func clearCache() {
        userDefaults.removeObject(forKey: CacheKeys.catalog)
        userDefaults.removeObject(forKey: CacheKeys.timestamp)
    }

    /// Checks if any cached data exists (regardless of expiration).
    /// - Returns: true if cached data exists
    public func hasCachedData() -> Bool {
        userDefaults.data(forKey: CacheKeys.catalog) != nil
    }
}
