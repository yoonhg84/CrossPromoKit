import SwiftUI

@main
struct CrossPromoDemoApp: App {
    @State private var viewModel = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                // Runs the case named by `-demoCase`, if the app was launched
                // with one. Placed at the root so the setup finishes before the
                // screen it lands on is built.
                .task {
                    await viewModel.runLaunchArgumentCase()
                }
        }
    }
}
