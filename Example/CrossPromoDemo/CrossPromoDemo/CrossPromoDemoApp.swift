import SwiftUI

@main
struct CrossPromoDemoApp: App {
    @State private var viewModel = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
