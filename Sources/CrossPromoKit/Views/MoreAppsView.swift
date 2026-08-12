import SwiftUI

/// Main view for displaying the list of promotable FinePocket apps.
/// Embed this in your settings screen or anywhere you want to show cross-promotions.
public struct MoreAppsView: View {
    @State private var service: PromoService
    @Binding private var forceRefresh: Bool

    /// Creates a MoreAppsView.
    /// - Parameters:
    ///   - config: Custom configuration with JSON URL and app ID
    ///   - eventDelegate: Delegate for receiving analytics events
    ///   - forceRefresh: Binding that triggers a network refresh when set to
    ///     `true`; the view resets it to `false` once the refresh completes
    public init(
        config: PromoConfig,
        eventDelegate: PromoEventDelegate? = nil,
        forceRefresh: Binding<Bool> = .constant(false)
    ) {
        let promoService = PromoService(config: config)
        promoService.eventDelegate = eventDelegate
        _service = State(initialValue: promoService)
        _forceRefresh = forceRefresh
    }

    public var body: some View {
        Group {
            if service.isLoading && service.apps.isEmpty {
                loadingView
            } else if service.apps.isEmpty {
                emptyStateView
            } else {
                appListView
            }
        }
        .task {
            await service.loadApps()
        }
        .onDisappear {
            // The overlay belongs to the window scene, not to this view, so it
            // would linger on screen after the promo UI is gone.
            service.dismissOverlay()
        }
        .onChange(of: forceRefresh) { _, newValue in
            if newValue {
                Task {
                    await service.forceRefresh()
                    forceRefresh = false
                }
            }
        }
        .alert(L10n.overlayErrorTitle, isPresented: .init(
            get: { service.showingOverlayError },
            set: { _ in service.dismissOverlayError() }
        )) {
            Button(L10n.overlayErrorOpenInAppStore) {
                if let appStoreID = service.overlayErrorAppID {
                    service.openAppStoreDirectly(appStoreID: appStoreID)
                }
                service.dismissOverlayError()
            }
            Button(L10n.cancel, role: .cancel) {
                service.dismissOverlayError()
            }
        } message: {
            Text(L10n.overlayErrorMessage)
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Spacer()
        }
        .padding(.vertical, WarmEmbraceTokens.spacingXL)
    }

    private var emptyStateView: some View {
        EmptyStateView.noApps {
            Task {
                await service.loadApps()
            }
        }
    }

    private var appListView: some View {
        ForEach(service.apps) { app in
            PromoAppRow(app: app) {
                service.handleAppTap(app)
            }
            .onAppear {
                service.handleAppImpression(app)
            }
        }
    }
}
