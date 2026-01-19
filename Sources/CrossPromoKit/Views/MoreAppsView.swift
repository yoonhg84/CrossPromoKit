import SwiftUI

/// Main view for displaying the list of promotable FinePocket apps.
/// Embed this in your settings screen or anywhere you want to show cross-promotions.
public struct MoreAppsView: View {
    @State private var service: PromoService

    /// Creates a MoreAppsView with the specified current app ID.
    /// - Parameter currentAppID: Your app's identifier to exclude from the list
    public init(currentAppID: String) {
        _service = State(initialValue: PromoService(currentAppID: currentAppID))
    }

    /// Creates a MoreAppsView with a custom configuration.
    /// - Parameter config: Custom configuration with JSON URL and app ID
    public init(config: PromoConfig) {
        _service = State(initialValue: PromoService(config: config))
    }

    /// Creates a MoreAppsView with a custom configuration and event delegate.
    /// - Parameters:
    ///   - config: Custom configuration with JSON URL and app ID
    ///   - eventDelegate: Delegate for receiving analytics events
    public init(config: PromoConfig, eventDelegate: PromoEventDelegate?) {
        let promoService = PromoService(config: config)
        promoService.eventDelegate = eventDelegate
        _service = State(initialValue: promoService)
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
        .alert("App Store를 열 수 없습니다", isPresented: .init(
            get: { service.showingOverlayError },
            set: { _ in service.dismissOverlayError() }
        )) {
            Button("App Store에서 열기") {
                if let appStoreID = service.overlayErrorAppID {
                    service.openAppStoreDirectly(appStoreID: appStoreID)
                }
                service.dismissOverlayError()
            }
            Button("취소", role: .cancel) {
                service.dismissOverlayError()
            }
        } message: {
            Text("인앱 App Store를 표시할 수 없습니다. App Store 앱에서 직접 열까요?")
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
