import CrossPromoKit
import SwiftUI

/// A host app's settings screen with the promo list embedded in it.
///
/// There is exactly one branch here — whether a catalog URL exists at all. Every
/// other outcome (list, spinner, "no apps", "offline") is drawn by the package
/// from the `PromoConfig` it was handed, so this screen shows package behaviour
/// rather than the demo's impression of it.
struct SettingsView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section {
                    if let config = viewModel.config {
                        MoreAppsView(
                            config: config,
                            eventDelegate: viewModel.eventHandler,
                            forceRefresh: $viewModel.forceRefreshRequested
                        )
                    } else {
                        Text("No catalog URL yet. Enter one in the Debug tab.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("More Apps")
                } footer: {
                    Text(viewModel.scenario.explanation)
                }
            }
            .navigationTitle("Settings")
            .refreshable {
                await viewModel.forceRefreshAndWait()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.forceRefreshAndWait() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel(Text("Force Refresh"))
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(DemoViewModel())
}
