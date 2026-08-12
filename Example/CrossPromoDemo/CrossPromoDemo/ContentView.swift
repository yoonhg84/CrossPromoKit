import SwiftUI

struct ContentView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        // Selection is bound to the view model so `-demoTab` can pick a tab
        // without a tap.
        //
        // Two tabs, and the first is still called Settings. The screen gained a
        // case menu, but what it demonstrates is unchanged: this is what
        // `MoreAppsView` looks like sitting in a host app's settings screen, and
        // that framing is the reason the embedded list means anything. The case
        // panel is scaffolding below the host app's own content, and the tab bar
        // was never part of the illusion.
        TabView(selection: $viewModel.selectedTab) {
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(DemoTab.settings)

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
