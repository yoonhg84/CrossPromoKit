import Foundation

/// Root entity representing the complete JSON response from the remote endpoint.
public struct AppCatalog: Codable, Sendable, Equatable {
    /// Array of promotable apps
    public let apps: [PromoApp]
    /// Maps host app ID to array of allowed promo app IDs (optional)
    public let promoRules: [String: [String]]?

    public init(apps: [PromoApp], promoRules: [String: [String]]? = nil) {
        self.apps = apps
        self.promoRules = promoRules
    }
}
