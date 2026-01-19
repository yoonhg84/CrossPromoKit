import SwiftUI
import CrossPromoKit

struct SettingsView: View {
    @Environment(DemoViewModel.self) private var viewModel
    private let eventHandler = DemoEventHandler()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    moreAppsContent
                } header: {
                    Text("More Apps")
                }
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private var moreAppsContent: some View {
        switch viewModel.demoState {
        case .loaded:
            if let url = Bundle.main.url(forResource: "demo-apps", withExtension: "json") {
                let config = PromoConfig(jsonURL: url, currentAppID: "photomagic")
                MoreAppsView(config: config, eventDelegate: eventHandler)
            } else {
                Text("demo-apps.json not found")
                    .foregroundStyle(.secondary)
            }
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                Spacer()
            }
            .padding(.vertical, 24)
        case .empty:
            VStack(spacing: 12) {
                Image(systemName: "app.badge")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No apps available")
                    .font(.headline)
                Text("Check back later for more apps from the developer.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    viewModel.demoState = .loaded
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        case .error:
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Something went wrong")
                    .font(.headline)
                Text("Unable to load apps. Please try again later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    viewModel.demoState = .loaded
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    SettingsView()
        .environment(DemoViewModel())
}
