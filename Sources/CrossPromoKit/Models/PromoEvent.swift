import Foundation

/// Analytics event types delegated to host app.
public enum PromoEvent: Sendable, Equatable {
    /// App row appeared in viewport
    case impression(appID: String)
    /// User tapped on app row
    case tap(appID: String)
}
