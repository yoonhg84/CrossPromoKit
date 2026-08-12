import SwiftUI

struct ContentView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        // Selection is bound to the view model so a case can send the person to
        // the screen its check happens on, and so `-demoCase` can land there
        // without a tap.
        TabView(selection: $viewModel.selectedTab) {
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(DemoTab.settings)

            CasesView()
                .tabItem {
                    Label("Cases", systemImage: "checklist")
                }
                .tag(DemoTab.cases)

            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
                .tag(DemoTab.debug)
        }
    }
}

#Preview {
    ContentView()
        .environment(DemoViewModel())
}
