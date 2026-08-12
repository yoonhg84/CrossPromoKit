import SwiftUI

/// The current verification case, as sections sitting under the promo list.
///
/// The same content the Cases tab used to hold — what the case is for, what its
/// setup did, what the demo can see afterwards, and what only a person can
/// decide — but on the screen the list is on, because fourteen of the fifteen
/// cases are settled by looking at that list.
///
/// The split between the last two sections is the point of the panel. A mark
/// appears only where the demo genuinely knows the answer — from its own cache,
/// the catalog file, or the events the package sent it. Everything else is
/// listed as something to look at, with no mark at all, because a checkmark that
/// only meant "the setup ran" would be worse than no checkmark. Nothing here
/// sums the case up in a single line for the same reason: there is no one line
/// the demo could honestly write.
struct CasePanel: View {
    @Environment(DemoViewModel.self) private var viewModel

    /// The last run, if it was the selected case.
    private var run: DemoCaseRun? {
        guard let run = viewModel.caseRun, run.verificationCase == viewModel.selectedCase else { return nil }
        return run
    }

    var body: some View {
        if let verificationCase = viewModel.selectedCase {
            aboutSection(verificationCase)

            if let run {
                observationsSection(run)
            }

            if !verificationCase.eyeChecks.isEmpty {
                eyeChecksSection(verificationCase)
            }
        } else {
            idleSection
        }
    }

    // MARK: - Sections

    private var idleSection: some View {
        Section {
            Text("No case is running.")
                .foregroundStyle(.secondary)
        } header: {
            Text("Verification case")
        } footer: {
            Text("Pick one from the checklist button in the toolbar. Its setup runs here and its readings appear here, so the list above never leaves the screen.")
        }
    }

    private func aboutSection(_ verificationCase: DemoVerificationCase) -> some View {
        Section {
            Text(verificationCase.title)
                .font(.headline)

            // Prose collapses; verdicts never do. Five promo rows already stand
            // between the top of the screen and this panel, and every paragraph
            // left open here pushes the readings further from the list they are
            // about.
            DisclosureGroup {
                if let purpose = verificationCase.purpose {
                    Text(purpose)
                        .font(.callout)
                }

                // The scenario already describes its own catalog; repeating that
                // description here is how one of the two copies goes stale.
                Text(verificationCase.scenario.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } label: {
                Text("What this checks")
            }

            DisclosureGroup {
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
            } label: {
                Text("Setup")
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
            Text("Verification case")
        } footer: {
            Text("Running the setup only puts the app into the state below. It is not a verdict on anything.")
        }
    }

    private func observationsSection(_ run: DemoCaseRun) -> some View {
        Section {
            ForEach(run.observations) { result in
                observationRow(result)
            }

            // The readings re-read themselves whenever an event arrives; the
            // button is for the ones no event announces.
            Button("Refresh Readings") {
                Task { await viewModel.refreshObservations() }
            }
        } header: {
            Text("What the demo can see")
        } footer: {
            Text("Read from the demo's own cache, its catalog file and the events the package reported. The package's PromoService is not visible from here, so nothing below is a claim about what is on screen.")
        }
    }

    private func eyeChecksSection(_ verificationCase: DemoVerificationCase) -> some View {
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

/// The case menu, in the list screen's toolbar.
///
/// Picking a case runs its setup straight away. There is nowhere to go
/// afterwards — the list is already on screen behind the menu, and the panel
/// under it fills in — so a separate "run" step would only have added a tap.
struct CaseMenu: View {
    @Environment(DemoViewModel.self) private var viewModel

    var body: some View {
        Menu {
            ForEach(DemoVerificationCase.Group.allCases) { group in
                Section {
                    ForEach(DemoVerificationCase.cases(in: group)) { verificationCase in
                        Button {
                            Task { await viewModel.select(verificationCase) }
                        } label: {
                            if verificationCase == viewModel.selectedCase {
                                Label {
                                    Text(verificationCase.title)
                                } icon: {
                                    Image(systemName: "checkmark")
                                }
                            } else {
                                Text(verificationCase.title)
                            }
                        }
                    }
                } header: {
                    Text(group.title)
                }
            }

            if viewModel.selectedCase != nil {
                Section {
                    Button(role: .destructive) {
                        viewModel.clearCase()
                    } label: {
                        Text("Close case")
                    }
                }
            }
        } label: {
            Image(systemName: "checklist")
        }
        .accessibilityLabel(Text("Run a case"))
    }
}

#Preview {
    List {
        CasePanel()
    }
    .environment(DemoViewModel())
}
