import SwiftUI
import UIKit

/// The controls that put the package into each state worth looking at.
///
/// Nothing here renders a promo state; it only changes what the package is
/// pointed at (the scenario), what it will find there (the catalog file), and
/// what it already has (the cache).
struct DebugView: View {
    @Environment(DemoViewModel.self) private var viewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                scenarioSection
                cacheSection
                catalogFileSection
                remoteSection
                eventsSection
                localizationSection
                configurationSection
            }
            .navigationTitle("Debug")
            .task(id: viewModel.scenario) {
                await viewModel.refreshCacheStatus()
            }
        }
    }

    // MARK: - Sections

    private var scenarioSection: some View {
        @Bindable var viewModel = viewModel

        return Section {
            Picker("Scenario", selection: $viewModel.scenario) {
                ForEach(DemoScenario.allCases) { scenario in
                    Text(scenario.displayName)
                        .tag(scenario)
                }
            }
            .pickerStyle(.menu)

            Text(viewModel.scenario.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Scenario")
        } footer: {
            Text("Each scenario hands the package a different PromoConfig. The list, the spinner and both empty states are drawn by the package itself.")
        }
    }

    private var cacheSection: some View {
        Section {
            LabeledContent {
                Text(viewModel.cacheStatus)
            } label: {
                Text("Status")
            }

            Button("Force Refresh") {
                Task { await viewModel.forceRefreshAndWait() }
            }

            Button("Clear Cache", role: .destructive) {
                Task { await viewModel.clearCache() }
            }
        } header: {
            Text("Cache")
        } footer: {
            Text("A valid cache is used without any fetch. Force Refresh always fetches, keeping the old cache as a fallback if the fetch fails; Clear Cache removes that fallback.")
        }
    }

    private var catalogFileSection: some View {
        Section {
            LabeledContent {
                if viewModel.catalogStore.fileExists {
                    Text("Version \(viewModel.catalogStore.version)")
                } else {
                    Text("Missing")
                }
            } label: {
                Text("Catalog file")
            }

            Button("Bump File Version") {
                viewModel.catalogStore.bumpVersion()
            }

            if viewModel.catalogStore.fileExists {
                Button("Delete Catalog File", role: .destructive) {
                    viewModel.catalogStore.deleteFile()
                }
            } else {
                Button("Restore Catalog File") {
                    viewModel.catalogStore.restoreFile()
                }
            }
        } header: {
            Text("Catalog File")
        } footer: {
            Text("Only affects the Normal catalog scenario. Bump the version, then compare the Catalog v… row in the list: an old number means the cache answered, a new one means the file was read. Deleting the file makes fetches fail without changing the URL, so the cache can still stand in for them.")
        }
    }

    private var remoteSection: some View {
        @Bindable var viewModel = viewModel

        return Section {
            TextField("https://example.com/apps.json", text: $viewModel.remoteURLText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.system(.body, design: .monospaced))

            Button("Load Remote URL") {
                viewModel.loadRemoteURL()
            }
            .disabled(viewModel.remoteURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } header: {
            Text("Remote Catalog")
        } footer: {
            Text("Switches to the Remote URL scenario. A URL that 404s, one that returns HTML instead of JSON, and airplane mode each exercise a different failure path.")
        }
    }

    private var eventsSection: some View {
        Section {
            if viewModel.eventHandler.entries.isEmpty {
                Text("No events yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.eventHandler.entries) { entry in
                    LabeledContent {
                        Text(entry.appID)
                            .font(.system(.caption, design: .monospaced))
                    } label: {
                        Text(entry.kind.label)
                    }
                }

                Button("Clear Events") {
                    viewModel.eventHandler.clear()
                }
            }
        } header: {
            Text("Events")
        } footer: {
            Text("Impressions and taps reported through PromoEventDelegate, newest first.")
        }
    }

    private var localizationSection: some View {
        Section {
            LabeledContent {
                Text(viewModel.currentLanguage.uppercased())
            } label: {
                Text("Current Language")
            }

            Button("Open Language Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
        } header: {
            Text("Localization")
        } footer: {
            Text("Language Settings switches this app alone, without a rebuild, when iOS offers the row for it. Otherwise use Edit Scheme → Run → Options → App Language.")
        }
    }

    private var configurationSection: some View {
        Section {
            LabeledContent {
                Text(DemoViewModel.currentAppID)
                    .font(.system(.body, design: .monospaced))
            } label: {
                Text("Current App ID")
            }

            LabeledContent {
                Text(viewModel.config?.jsonURL.absoluteString ?? "—")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                    .truncationMode(.middle)
            } label: {
                Text("Catalog URL")
            }
        } header: {
            Text("Demo Configuration")
        } footer: {
            Text("PhotoMagic is set as the current app, so it won't appear in the promotion list.")
        }
    }
}

#Preview {
    DebugView()
        .environment(DemoViewModel())
}
