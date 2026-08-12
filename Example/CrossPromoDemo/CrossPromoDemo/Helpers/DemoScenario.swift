import Foundation

/// A catalog the demo can point ``CrossPromoKit`` at.
///
/// Every case resolves to a real `PromoConfig`; the demo never draws a state on
/// the package's behalf. An empty list, an offline list and a spinner are all
/// reached the same way a host app would reach them — by handing the package a
/// catalog URL and letting it decide what to render. That is what makes the
/// screen evidence of package behaviour rather than of demo code.
///
/// Swapping the selection swaps the `PromoConfig`, which is also the manual
/// check for the config-change rebuild in ``MoreAppsView``.
enum DemoScenario: String, CaseIterable, Identifiable {
    /// The writable copy of `demo-apps.json`, the only catalog the demo can edit.
    case catalog
    /// A catalog whose `promoRules` allow only two of the five apps.
    case rules
    /// Icons served over HTTPS, including two that cannot load.
    case remoteIcons
    /// A catalog with an empty `apps` array.
    case empty
    /// A catalog URL that does not exist.
    case offline
    /// A catalog URL that never answers.
    case stalled
    /// An HTTPS URL typed in the Debug tab.
    case remote

    var id: String { rawValue }

    /// Localized label shown in the Debug tab scenario picker.
    ///
    /// Returns `LocalizedStringResource` so `Text(_:)` resolves the value through the
    /// String Catalog. A plain `String` would bypass localization entirely.
    var displayName: LocalizedStringResource {
        switch self {
        case .catalog: return "Normal catalog"
        case .rules: return "Promo rules"
        case .remoteIcons: return "Remote icons"
        case .empty: return "Empty catalog"
        case .offline: return "Unreachable catalog"
        case .stalled: return "Stalled request"
        case .remote: return "Remote URL"
        }
    }

    /// Localized explanation of what the package does with this catalog, shown
    /// under the picker and under the promo list.
    var explanation: LocalizedStringResource {
        switch self {
        case .catalog:
            return "Loads the editable copy of demo-apps.json. Compare the Catalog v… row with the file version below to see whether the list came from the cache or from a fresh read."
        case .rules:
            return "promoRules allows photomagic to promote only WeatherPal and BudgetWise, so the other apps are filtered out of a five-app catalog."
        case .remoteIcons:
            return "Icons over HTTPS: one loads, one 404s and one has an unresolvable host, so both failures fall back to the package placeholder."
        case .empty:
            return "The catalog parses but holds no apps, so the package renders its own EmptyStateView.noApps."
        case .offline:
            return "The catalog URL does not exist and nothing is cached for it, so the package renders its own EmptyStateView.offline."
        case .stalled:
            return "The request goes to an unroutable address and hangs, so the package keeps showing its own loading indicator until the request times out."
        case .remote:
            return "Loads the HTTPS URL entered below. Try a 404, a non-JSON page, or turn the network off to watch the fallback tiers."
        }
    }
}
