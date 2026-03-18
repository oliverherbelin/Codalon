// Issue #212 — Build status summary view

import SwiftUI
import HelaiaDesign

// MARK: - ASCBuildStatusView

struct ASCBuildStatusView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            Text("Builds")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if viewModel.builds.isEmpty {
                HelaiaEmptyState(
                    icon: "hammer",
                    title: "No builds",
                    description: "Upload a build to App Store Connect to see it here"
                )
            } else {
                buildList

                if !viewModel.testFlightBuilds.isEmpty {
                    testFlightSection
                }
            }
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadAllBuildData()
        }
    }

    // MARK: - Build List

    @ViewBuilder
    private var buildList: some View {
        VStack(spacing: Spacing._2) {
            ForEach(viewModel.builds.prefix(10)) { build in
                buildRow(build)
            }
        }
    }

    @ViewBuilder
    private func buildRow(_ build: ASCBuild) -> some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    processingIcon(build.processingState),
                    size: .md,
                    color: processingColor(build.processingState)
                )

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text("Build \(build.buildNumber)")
                        .helaiaFont(.headline)
                    Text("v\(build.version)")
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing._0_5) {
                    Text(build.processingState.displayName)
                        .helaiaFont(.caption1)
                        .foregroundStyle(processingColor(build.processingState))
                    if let date = build.uploadedDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .helaiaFont(.tag)
                            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    }
                }
            }
        }
    }

    // MARK: - TestFlight Section

    @ViewBuilder
    private var testFlightSection: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._2) {
                HelaiaIconView("airplane", size: .sm, color: SemanticColor.textSecondary(for: colorScheme))
                Text("TESTFLIGHT")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)
            }

            ForEach(viewModel.testFlightBuilds.prefix(5)) { build in
                HelaiaCard(variant: .outlined) {
                    HStack(spacing: Spacing._3) {
                        VStack(alignment: .leading, spacing: Spacing._0_5) {
                            Text("Build \(build.buildNumber)")
                                .helaiaFont(.headline)
                            Text(build.betaState.displayName)
                                .helaiaFont(.caption1)
                                .foregroundStyle(betaColor(build.betaState))
                        }

                        Spacer()

                        if let expiry = build.expirationDate {
                            Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                                .helaiaFont(.tag)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }

                        if !build.testerGroups.isEmpty {
                            Text("\(build.testerGroups.count) group\(build.testerGroups.count == 1 ? "" : "s")")
                                .helaiaFont(.tag)
                                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func processingIcon(_ state: ASCBuildProcessingState) -> String {
        switch state {
        case .processing: "arrow.triangle.2.circlepath"
        case .valid: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .invalid: "exclamationmark.triangle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private func processingColor(_ state: ASCBuildProcessingState) -> Color {
        switch state {
        case .processing: SemanticColor.warning(for: colorScheme)
        case .valid: SemanticColor.success(for: colorScheme)
        case .failed, .invalid: SemanticColor.error(for: colorScheme)
        case .unknown: SemanticColor.textSecondary(for: colorScheme)
        }
    }

    private func betaColor(_ state: ASCBetaState) -> Color {
        switch state {
        case .readyForBetaTesting, .inBetaTesting, .betaApproved: SemanticColor.success(for: colorScheme)
        case .expired, .betaRejected: SemanticColor.error(for: colorScheme)
        case .waitingForBetaReview, .inBetaReview, .inExportComplianceReview: SemanticColor.warning(for: colorScheme)
        case .unknown: SemanticColor.textSecondary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("ASCBuildStatusView") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.linkedApp = ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)
    vm.builds = [
        ASCBuild(id: "b1", version: "1.0", buildNumber: "42", uploadedDate: Date(), processingState: .valid),
        ASCBuild(id: "b2", version: "1.0", buildNumber: "41", uploadedDate: Date().addingTimeInterval(-86400), processingState: .processing),
        ASCBuild(id: "b3", version: "0.9", buildNumber: "38", uploadedDate: Date().addingTimeInterval(-259200), processingState: .failed),
    ]
    vm.testFlightBuilds = [
        ASCTestFlightBuild(id: "tf1", buildNumber: "42", version: "1.0", betaState: .inBetaTesting, expirationDate: Date().addingTimeInterval(7776000), testerGroups: ["Internal", "Beta"]),
    ]

    return ASCBuildStatusView(viewModel: vm)
        .frame(width: 500)
}

#Preview("ASCBuildStatusView — Empty") {
    ASCBuildStatusView(viewModel: ASCViewModel(
        ascService: PreviewASCService(),
        projectID: UUID()
    ))
    .frame(width: 500)
}
