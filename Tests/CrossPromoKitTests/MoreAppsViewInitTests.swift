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
        let retained = view.prepareService(existing: nil)

        #expect(retained.service.eventDelegate === delegate)
    }

    @Test("A delegate passed after the first pass is attached to the same service")
    func laterDelegateIsAttachedToTheSameService() {
        let first = InitProbeDelegate()
        let retained = MoreAppsView(config: config, eventDelegate: first).prepareService(existing: nil)

        // The parent re-evaluates with a different delegate: `init` runs again,
        // but the service in @State is the one already retained.
        let second = InitProbeDelegate()
        let reused = MoreAppsView(config: config, eventDelegate: second).prepareService(existing: retained)

        #expect(reused.service === retained.service)
        #expect(reused.service.eventDelegate === second)
    }

    @Test("Dropping the delegate detaches it from the retained service")
    func nilDelegateDetaches() {
        let delegate = InitProbeDelegate()
        let retained = MoreAppsView(config: config, eventDelegate: delegate).prepareService(existing: nil)

        let reused = MoreAppsView(config: config).prepareService(existing: retained)

        #expect(reused.service === retained.service)
        #expect(reused.service.eventDelegate == nil)
    }

    @Test("Repeated passes with the same config reuse the service")
    func serviceIsBuiltOnce() {
        let view = MoreAppsView(config: config)
        let first = view.prepareService(existing: nil)

        let again = view.prepareService(existing: first)
        // An equal config built separately still counts as the same one.
        let equalConfig = PromoConfig(
            jsonURL: URL(string: "https://example.com/apps.json")!,
            currentAppID: "host"
        )
        let third = MoreAppsView(config: equalConfig).prepareService(existing: again)

        #expect(again.service === first.service)
        #expect(third.service === first.service)
    }

    @Test("The service the view builds carries the given config")
    func serviceCarriesTheGivenConfig() {
        let view = MoreAppsView(config: config)

        let retained = view.prepareService(existing: nil)

        // No network here: filtering is the observable side of the config.
        let filtered = retained.service.filterApps(from: Fixture.catalog(ids: ["host", "finebill"]))
        #expect(filtered.map(\.id) == ["finebill"])
    }

    @Test("A config with a different app ID rebuilds the service around it")
    func changedAppIDRebuildsTheService() {
        let retained = MoreAppsView(config: config).prepareService(existing: nil)

        let other = PromoConfig(jsonURL: config.jsonURL, currentAppID: "finebill")
        let rebuilt = MoreAppsView(config: other).prepareService(existing: retained)

        #expect(rebuilt.service !== retained.service)
        // The new config decides the catalog: "finebill" is now the host to hide.
        let filtered = rebuilt.service.filterApps(from: Fixture.catalog(ids: ["host", "finebill"]))
        #expect(filtered.map(\.id) == ["host"])
    }

    @Test("A config with a different JSON URL rebuilds the service around it")
    func changedJSONURLRebuildsTheService() {
        let retained = MoreAppsView(config: config).prepareService(existing: nil)

        let other = PromoConfig(
            jsonURL: URL(string: "https://example.com/other-apps.json")!,
            currentAppID: config.currentAppID
        )
        let rebuilt = MoreAppsView(config: other).prepareService(existing: retained)

        #expect(rebuilt.service !== retained.service)
    }

    @Test("A rebuilt service still gets the current delegate")
    func rebuiltServiceKeepsTheDelegate() {
        let delegate = InitProbeDelegate()
        let retained = MoreAppsView(config: config, eventDelegate: delegate).prepareService(existing: nil)

        let other = PromoConfig(jsonURL: config.jsonURL, currentAppID: "finebill")
        let rebuilt = MoreAppsView(config: other, eventDelegate: delegate).prepareService(existing: retained)

        #expect(rebuilt.service !== retained.service)
        #expect(rebuilt.service.eventDelegate === delegate)
    }
}
