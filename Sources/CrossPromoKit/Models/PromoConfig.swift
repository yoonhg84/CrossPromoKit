import Foundation

/// Client-side configuration for CrossPromoKit.
public struct PromoConfig: Sendable, Equatable {
    /// Remote JSON endpoint URL
    public let jsonURL: URL
    /// Host app identifier to exclude from the list
    public let currentAppID: String

    public init(jsonURL: URL, currentAppID: String) {
        self.jsonURL = jsonURL
        self.currentAppID = currentAppID
    }
}
