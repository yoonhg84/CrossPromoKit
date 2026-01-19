import Foundation

/// Represents a promotable app in the FinePocket portfolio.
public struct PromoApp: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for the app (e.g., "finebill")
    public let id: String
    /// Display name of the app (e.g., "FineBill")
    public let name: String
    /// Apple App Store numeric ID
    public let appStoreID: String
    /// HTTPS URL to the app icon image
    public let iconURL: URL
    /// Category label displayed in the UI (e.g., "생산성")
    public let category: String
    /// Localized tagline object
    public let tagline: LocalizedText

    public init(
        id: String,
        name: String,
        appStoreID: String,
        iconURL: URL,
        category: String,
        tagline: LocalizedText
    ) {
        self.id = id
        self.name = name
        self.appStoreID = appStoreID
        self.iconURL = iconURL
        self.category = category
        self.tagline = tagline
    }
}
