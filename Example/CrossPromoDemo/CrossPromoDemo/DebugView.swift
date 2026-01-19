import SwiftUI

struct DebugView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                // State Testing Section
                Section {
                    Picker("Demo State", selection: $viewModel.demoState) {
                        ForEach(DemoState.allCases) { state in
                            Text(state.displayName)
                                .tag(state)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(viewModel.demoState.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("State Testing")
                } footer: {
                    Text("Change the demo state to test different UI scenarios for screenshots.")
                }

                // Cache Status Section
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.cacheStatus)
                            .foregroundStyle(.secondary)
                    }

                    Button("Force Refresh") {
                        viewModel.forceRefresh()
                    }
                } header: {
                    Text("Cache")
                } footer: {
                    Text("Force refresh clears the cache and reloads data from the JSON file.")
                }

                // Language Section
                Section {
                    HStack {
                        Text("Current Language")
                        Spacer()
                        Text(viewModel.currentLanguage.uppercased())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Localization")
                } footer: {
                    Text("To test different languages:\n1. Edit Scheme → Run → Options\n2. Set App Language to Korean or Japanese\n3. Run the app")
                }

                // App Info Section
                Section {
                    HStack {
                        Text("Current App ID")
                        Spacer()
                        Text("photomagic")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Excluded from list")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Demo Configuration")
                } footer: {
                    Text("PhotoMagic is set as the current app, so it won't appear in the promotion list.")
                }
            }
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    DebugView()
        .environment(DemoViewModel())
}
