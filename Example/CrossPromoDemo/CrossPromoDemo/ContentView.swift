import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
        }
    }
}

#Preview {
    ContentView()
}
