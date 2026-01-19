import Foundation
import SwiftUI

/// Observable view model for managing demo state across views.
@Observable
@MainActor
final class DemoViewModel {
    /// Current demo state for UI testing
    var demoState: DemoState = .loaded

    /// Cache status description
    var cacheStatus: String {
        // Check UserDefaults for cache timestamp
        let defaults = UserDefaults.standard
        if let timestamp = defaults.object(forKey: "CrossPromoKit.CacheTimestamp") as? Date {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let relativeTime = formatter.localizedString(for: timestamp, relativeTo: Date())
            let calendar = Calendar.current
            let hoursSince = calendar.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
            if hoursSince < 24 {
                return "Valid (cached \(relativeTime))"
            } else {
                return "Expired (cached \(relativeTime))"
            }
        }
        return "Empty (no cache)"
    }

    /// Current language code
    var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "Unknown"
    }

    /// Force refresh by clearing cache
    func forceRefresh() {
        UserDefaults.standard.removeObject(forKey: "CrossPromoKit.CacheTimestamp")
        UserDefaults.standard.removeObject(forKey: "CrossPromoKit.CachedCatalog")
        // Reset to loaded state to trigger reload
        demoState = .loaded
    }
}
