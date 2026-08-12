import SwiftUI

/// The menu of verification cases.
///
/// The Debug tab has the parts; this tab has the recipes. Picking a case and
/// tapping Run Setup performs every step it needs, in order, so checking the
/// stale-cache fallback does not depend on remembering that it takes a load,
/// an expiry, a deleted file and a refresh — in that order.
struct CasesView: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        NavigationStack(path: path) {
            List {
                ForEach(DemoVerificationCase.Group.allCases) { group in
                    Section {
                        ForEach(DemoVerificationCase.cases(in: group)) { verificationCase in
                            NavigationLink(value: verificationCase) {
                                Text(verificationCase.title)
                            }
                        }
                    } header: {
                        Text(group.title)
                    }
                }
            }
            .navigationTitle("Cases")
            .navigationDestination(for: DemoVerificationCase.self) { verificationCase in
                CaseDetailView(verificationCase: verificationCase)
            }
        }
    }

    /// The pushed case, as a navigation path.
    ///
    /// Kept in ``DemoViewModel`` rather than in `@State` so `-demoCase` can open
    /// a case's detail on launch, on a machine where tapping cannot be
    /// automated.
    private var path: Binding<[DemoVerificationCase]> {
        Binding(
            get: { viewModel.selectedCase.map { [$0] } ?? [] },
            set: { viewModel.selectedCase = $0.last }
        )
    }
}

#Preview {
    CasesView()
        .environment(DemoViewModel())
}
