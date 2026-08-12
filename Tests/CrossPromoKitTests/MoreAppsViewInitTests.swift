import SwiftUI
import Testing
@testable import CrossPromoKit

/// Guards source compatibility of the single defaulted `MoreAppsView` init:
/// every call shape the previous overloads supported must still compile.
@MainActor
final class InitProbeDelegate: PromoEventDelegate {
    func promoService(_ service: PromoService, didEmit event: PromoEvent) {}
}

@Suite("MoreAppsView init")
@MainActor
struct MoreAppsViewInitTests {
    private let config = PromoConfig(
        jsonURL: URL(string: "https://example.com/apps.json")!,
        currentAppID: "host"
    )

    @Test("Every previously supported call shape still compiles")
    func allCallShapesCompile() {
        let delegate = InitProbeDelegate()
        var refreshing = false
        let binding = Binding(get: { refreshing }, set: { refreshing = $0 })

        _ = MoreAppsView(config: config)
        _ = MoreAppsView(config: config, eventDelegate: delegate)
        _ = MoreAppsView(config: config, forceRefresh: binding)
        _ = MoreAppsView(config: config, eventDelegate: delegate, forceRefresh: binding)
        _ = MoreAppsView(config: config, eventDelegate: nil)
    }
}
