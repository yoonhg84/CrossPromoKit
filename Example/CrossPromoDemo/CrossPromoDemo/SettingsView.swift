import CrossPromoKit
import SwiftUI

/// A host app's settings screen with the promo list embedded in it, and the
/// verification cases underneath.
///
/// There is exactly one branch in the promo section — whether a catalog URL
/// exists at all. Every other outcome (list, spinner, "no apps", "offline") is
/// drawn by the package from the `PromoConfig` it was handed, so this screen
/// shows package behaviour rather than the demo's impression of it.
///
/// The case panel is below that section, never over it: almost every case is
/// settled by looking at the list, so running a setup and reading the result
/// have to be possible without the list moving.
struct SettingsView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            List {
                promoSection
                CasePanel()
            }
            .navigationTitle("Settings")
            .refreshable {
                await viewModel.forceRefreshAndWait()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CaseMenu()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.forceRefreshAndWait() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel(Text("Force Refresh"))
                }
            }
            // Most readings only become answerable once the package has
            // reported something, and now that the list is on this screen those
            // reports arrive while the panel is being looked at. Re-reading on
            // each event is what makes a pending row turn into a verdict without
            // anyone tapping anything — it re-reads, it never assumes.
            .task(id: viewModel.eventHandler.entries.count) {
                await viewModel.refreshObservations()
            }
        }
    }

    private var promoSection: some View {
        @Bindable var viewModel = viewModel

        return Section {
            if viewModel.isPreparingLaunchCase {
                // A `-demoCase` setup is still running. Building the list now
                // would load it against a half-made state.
                Text("Running the case setup…")
                    .foregroundStyle(.secondary)
            } else if let config = viewModel.config {
                MoreAppsView(
                    config: config,
                    eventDelegate: viewModel.eventHandler,
                    forceRefresh: $viewModel.forceRefreshRequested
                )
                // A verification case that needs a load from scratch bumps
                // this, which is the same thing a host app does by navigating
                // away from its settings screen and back: the view — and the
                // service it retains — is built anew.
                .id(viewModel.listGeneration)
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
}

#Preview {
    SettingsView()
        .environment(DemoViewModel())
}
