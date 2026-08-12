import SwiftUI

/// Main view for displaying the list of promotable FinePocket apps.
/// Embed this in your settings screen or anywhere you want to show cross-promotions.
public struct MoreAppsView: View {
    /// The service the view keeps, paired with the config it was built for.
    ///
    /// Built on the first `task` rather than in `init`: SwiftUI re-runs `init`
    /// on every parent re-evaluation, and `@State` keeps only the first value,
    /// so building it there threw away a `PromoService` — and the `CacheManager`
    /// it creates — on every pass.
    @State private var retained: RetainedService?
    @Binding private var forceRefresh: Bool

    /// The service currently retained, if one has been built.
    private var service: PromoService? { retained?.service }

    private let config: PromoConfig
    /// Held weakly to match ``PromoService/eventDelegate``, so embedding this
    /// view cannot keep its host alive.
    private weak var eventDelegate: PromoEventDelegate?

    /// Creates a MoreAppsView.
    /// - Parameters:
    ///   - config: Custom configuration with JSON URL and app ID
    ///   - eventDelegate: Delegate for receiving analytics events. Passing a
    ///     different delegate later re-attaches it to the running service.
    ///   - forceRefresh: Binding that triggers a network refresh when set to
    ///     `true`; the view resets it to `false` once the refresh completes
    public init(
        config: PromoConfig,
        eventDelegate: PromoEventDelegate? = nil,
        forceRefresh: Binding<Bool> = .constant(false)
    ) {
        self.config = config
        self.eventDelegate = eventDelegate
        _forceRefresh = forceRefresh
    }

    public var body: some View {
        Group {
            if let service {
                content(for: service)
            } else {
                // Only until the first `task` runs, which is also when the
                // initial load starts — the same spinner it would show anyway.
                loadingView
            }
        }
        .task {
            let prepared = prepareService(existing: retained)
            retained = prepared
            await prepared.service.loadApps()
        }
        .onChange(of: serviceInputs) { _, _ in
            // `task` does not re-run for a re-evaluated parent, so inputs
            // swapped in after the first pass have to reach the service here:
            // a new delegate is re-attached, a new config rebuilds the service.
            let previous = retained?.service
            let prepared = prepareService(existing: retained)
            retained = prepared
            guard prepared.service !== previous else { return }
            Task { await prepared.service.loadApps() }
        }
        .onDisappear {
            // The overlay belongs to the window scene, not to this view, so it
            // would linger on screen after the promo UI is gone.
            service?.dismissOverlay()
        }
        .onChange(of: forceRefresh) { _, newValue in
            if newValue {
                Task {
                    // A nil service means the first load has not started yet, so
                    // the pending `task` already satisfies the refresh request.
                    await service?.forceRefresh()
                    forceRefresh = false
                }
            }
        }
        .alert(L10n.overlayErrorTitle, isPresented: .init(
            get: { service?.showingOverlayError ?? false },
            set: { _ in service?.dismissOverlayError() }
        )) {
            Button(L10n.overlayErrorOpenInAppStore) {
                if let service, let appStoreID = service.overlayErrorAppID {
                    service.openAppStoreDirectly(appStoreID: appStoreID)
                }
                service?.dismissOverlayError()
            }
            Button(L10n.cancel, role: .cancel) {
                service?.dismissOverlayError()
            }
        } message: {
            Text(L10n.overlayErrorMessage)
        }
    }

    // MARK: - Service Lifetime

    /// A service together with the configuration it was built from.
    ///
    /// The config travels alongside because ``PromoService`` keeps its own
    /// copy private, so the view could not otherwise tell whether the service
    /// it retains still matches the config it is being asked to show.
    struct RetainedService {
        let service: PromoService
        let config: PromoConfig
    }

    /// Everything the retained service is derived from.
    ///
    /// One value so a single `onChange` covers both: the delegate is compared
    /// by identity, since `PromoEventDelegate` is not `Equatable`.
    private var serviceInputs: ServiceInputs {
        ServiceInputs(config: config, delegate: eventDelegate.map { ObjectIdentifier($0) })
    }

    /// Identity of the inputs a retained service depends on.
    private struct ServiceInputs: Equatable {
        let config: PromoConfig
        let delegate: ObjectIdentifier?
    }

    /// Returns the service the view should keep, attaching the current delegate.
    ///
    /// The service is reused as long as the config it was built from still
    /// matches, so repeated `task` runs (a view that disappears and comes back)
    /// neither rebuild the service nor drop its loaded apps. A different config
    /// does force a rebuild: the catalog URL and the excluded app ID are read at
    /// construction time — including by the cache, which is scoped to
    /// `jsonURL` — so reusing the old service would keep showing the old
    /// catalog.
    /// - Parameter existing: The service already retained by this view, if any.
    /// - Returns: The service to store and load from, with its config.
    func prepareService(existing: RetainedService?) -> RetainedService {
        if let existing, existing.config == config {
            existing.service.eventDelegate = eventDelegate
            return existing
        }
        let service = PromoService(config: config)
        service.eventDelegate = eventDelegate
        return RetainedService(service: service, config: config)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func content(for service: PromoService) -> some View {
        if service.isLoading && service.apps.isEmpty {
            loadingView
        } else if service.apps.isEmpty {
            emptyStateView(for: service)
        } else {
            appListView(for: service)
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Spacer()
        }
        .padding(.vertical, WarmEmbraceTokens.spacingXL)
    }

    @ViewBuilder
    private func emptyStateView(for service: PromoService) -> some View {
        switch Self.emptyState(for: service.error) {
        case .noApps:
            EmptyStateView.noApps { reload(service) }
        case .offline:
            EmptyStateView.offline { reload(service) }
        }
    }

    private func appListView(for service: PromoService) -> some View {
        ForEach(service.apps) { app in
            PromoAppRow(app: app) {
                service.handleAppTap(app)
            }
            .onAppear {
                service.handleAppImpression(app)
            }
        }
    }

    private func reload(_ service: PromoService) {
        Task {
            await service.loadApps()
        }
    }
}

// MARK: - Empty State Selection

extension MoreAppsView {
    /// Which empty state the list shows when it has no apps to display.
    enum EmptyState {
        /// The catalog loaded, it just holds nothing to promote here.
        case noApps
        /// The catalog could not be loaded and no cache could stand in for it.
        case offline
    }

    /// Picks the empty state matching the outcome of the last load.
    ///
    /// ``PromoService/loadApps()`` only publishes an `error` on the third tier of
    /// its fallback — the network failed *and* the cache had nothing to show. A
    /// successful cache fallback deliberately leaves `error` nil, so that path
    /// keeps rendering the list rather than an empty state.
    ///
    /// The error is not inspected further: every tier-3 failure leaves the user
    /// with nothing to show and one useful action (retry), and "offline" already
    /// describes a decode or server error as usefully as a `URLError` for that
    /// audience. Matching on `URLError` codes would only shift some failures
    /// back to the "no apps yet" copy, which is the misdescription this branch
    /// exists to fix.
    /// - Parameter error: ``PromoService/error`` after the load.
    /// - Returns: The empty state to render.
    static func emptyState(for error: Error?) -> EmptyState {
        error == nil ? .noApps : .offline
    }
}
