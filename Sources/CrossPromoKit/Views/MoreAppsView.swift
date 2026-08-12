import SwiftUI

/// Main view for displaying the list of promotable FinePocket apps.
/// Embed this in your settings screen or anywhere you want to show cross-promotions.
public struct MoreAppsView: View {
    /// The service the view keeps for its whole lifetime.
    ///
    /// Built on the first `task` rather than in `init`: SwiftUI re-runs `init`
    /// on every parent re-evaluation, and `@State` keeps only the first value,
    /// so building it there threw away a `PromoService` — and the `CacheManager`
    /// it creates — on every pass.
    @State private var service: PromoService?
    @Binding private var forceRefresh: Bool

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
            let service = prepareService(existing: service)
            self.service = service
            await service.loadApps()
        }
        .onChange(of: delegateIdentity) { _, _ in
            // `task` does not re-run for a re-evaluated parent, so a delegate
            // swapped in after the first pass has to be re-attached here.
            service?.eventDelegate = eventDelegate
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

    /// Identity of the current delegate, so `onChange` can spot a swap without
    /// requiring `PromoEventDelegate` to be `Equatable`.
    private var delegateIdentity: ObjectIdentifier? {
        eventDelegate.map { ObjectIdentifier($0) }
    }

    /// Returns the service the view should keep, attaching the current delegate.
    ///
    /// The service is created once and then reused: `existing` is returned
    /// unchanged apart from its delegate, so repeated `task` runs (a view that
    /// disappears and comes back) neither rebuild the service nor drop its
    /// loaded apps.
    /// - Parameter existing: The service already retained by this view, if any.
    /// - Returns: The service to store and load from.
    func prepareService(existing: PromoService?) -> PromoService {
        let service = existing ?? PromoService(config: config)
        service.eventDelegate = eventDelegate
        return service
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
