@testable import CrossPromoKit
import SwiftUI
import Testing

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

    @Test("The delegate reaches the service the view retains")
    func delegateReachesRetainedService() {
        let delegate = InitProbeDelegate()
        let view = MoreAppsView(config: config, eventDelegate: delegate)

        // What `task` stores in @State is exactly what this returns.
        let service = view.prepareService(existing: nil)

        #expect(service.eventDelegate === delegate)
    }

    @Test("A delegate passed after the first pass is attached to the same service")
    func laterDelegateIsAttachedToTheSameService() {
        let first = InitProbeDelegate()
        let retained = MoreAppsView(config: config, eventDelegate: first).prepareService(existing: nil)

        // The parent re-evaluates with a different delegate: `init` runs again,
        // but the service in @State is the one already retained.
        let second = InitProbeDelegate()
        let reused = MoreAppsView(config: config, eventDelegate: second).prepareService(existing: retained)

        #expect(reused === retained)
        #expect(reused.eventDelegate === second)
    }

    @Test("Dropping the delegate detaches it from the retained service")
    func nilDelegateDetaches() {
        let delegate = InitProbeDelegate()
        let retained = MoreAppsView(config: config, eventDelegate: delegate).prepareService(existing: nil)

        let reused = MoreAppsView(config: config).prepareService(existing: retained)

        #expect(reused === retained)
        #expect(reused.eventDelegate == nil)
    }

    @Test("Repeated passes reuse the service instead of rebuilding it")
    func serviceIsBuiltOnce() {
        let view = MoreAppsView(config: config)
        let first = view.prepareService(existing: nil)

        let again = view.prepareService(existing: first)
        let third = MoreAppsView(config: config).prepareService(existing: again)

        #expect(again === first)
        #expect(third === first)
    }

    @Test("The service the view builds carries the given config")
    func serviceCarriesTheGivenConfig() {
        let view = MoreAppsView(config: config)

        let service = view.prepareService(existing: nil)

        // No network here: filtering is the observable side of the config.
        let filtered = service.filterApps(from: Fixture.catalog(ids: ["host", "finebill"]))
        #expect(filtered.map(\.id) == ["finebill"])
    }
}
