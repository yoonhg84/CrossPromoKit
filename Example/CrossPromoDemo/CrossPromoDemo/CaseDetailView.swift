import SwiftUI

/// One verification case: what it is for, what its setup does, what the demo
/// can see afterwards, and what only a person can decide.
///
/// The split between the last two sections is the point of the screen. A mark
/// appears only where the demo genuinely knows the answer — from its own cache,
/// the catalog file, or the events the package sent it. Everything else is
/// listed as something to look at, with no mark at all, because a checkmark
/// that only meant "the setup ran" would be worse than no checkmark.
struct CaseDetailView: View {
    let verificationCase: DemoVerificationCase

    @Environment(DemoViewModel.self) private var viewModel

    /// The last run, if it was this case.
    private var run: DemoCaseRun? {
        guard let run = viewModel.caseRun, run.verificationCase == verificationCase else { return nil }
        return run
    }

    var body: some View {
        List {
            aboutSection
            setupSection
            if let run {
                observationsSection(run)
            }
            if !verificationCase.eyeChecks.isEmpty {
                eyeChecksSection
            }
            destinationSection
        }
        .navigationTitle(Text(verificationCase.title))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: verificationCase) {
            await viewModel.refreshObservations()
        }
    }

    // MARK: - Sections

    private var aboutSection: some View {
        Section {
            if let purpose = verificationCase.purpose {
                Text(purpose)
            }
            // The scenario already describes its own catalog; repeating that
            // description here is how one of the two copies goes stale.
            Text(verificationCase.scenario.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("What this checks")
        }
    }

    private var setupSection: some View {
        Section {
            ForEach(Array(verificationCase.actions.enumerated()), id: \.offset) { index, action in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: "\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(action.label)
                        .font(.callout)
                }
            }

            let runTitle: LocalizedStringResource = run == nil ? "Run Setup" : "Run Setup Again"
            Button {
                Task { await viewModel.run(verificationCase) }
            } label: {
                Text(runTitle)
            }

            if let run {
                LabeledContent {
                    Text(run.ranAt, style: .time)
                } label: {
                    Text("Setup ran at")
                }
            }
        } header: {
            Text("Setup")
        } footer: {
            Text("Running the setup only puts the app into the state below. It is not a verdict on anything.")
        }
    }

    private func observationsSection(_ run: DemoCaseRun) -> some View {
        Section {
            ForEach(run.observations) { result in
                observationRow(result)
            }

            // The readings refresh whenever this screen appears; the button is
            // for re-reading without leaving it.
            Button("Refresh Readings") {
                Task { await viewModel.refreshObservations() }
            }
        } header: {
            Text("What the demo can see")
        } footer: {
            Text("Read from the demo's own cache, its catalog file and the events the package reported. The package's PromoService is not visible from here, so nothing below is a claim about what is on screen.")
        }
    }

    private var eyeChecksSection: some View {
        Section {
            ForEach(Array(verificationCase.eyeChecks.enumerated()), id: \.offset) { _, check in
                Label {
                    Text(check)
                } icon: {
                    Image(systemName: "eye")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Check by eye")
        } footer: {
            Text("The demo cannot judge these. Nothing here is ever marked passed.")
        }
    }

    private var destinationSection: some View {
        Section {
            Button("Go to the list") {
                viewModel.selectedTab = verificationCase.destination
            }
        }
    }

    // MARK: - Rows

    private func observationRow(_ result: DemoObservationResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                if result.observation.isJudged {
                    verdictIcon(result.verdict)
                }
                Text(result.observation.label)
                Spacer(minLength: 8)
                if let value = result.value {
                    Text(verbatim: value)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if let detail = result.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func verdictIcon(_ verdict: DemoVerdict) -> some View {
        switch verdict {
        case .pass:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel(Text("Passed"))
        case .fail:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .accessibilityLabel(Text("Failed"))
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("Nothing to judge yet"))
        case .reported:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        CaseDetailView(verificationCase: .staleFallback)
            .environment(DemoViewModel())
    }
}
