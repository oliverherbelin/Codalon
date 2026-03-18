// Issue #155 — Release cockpit screen

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseCockpitView

struct ReleaseCockpitView: View {

    // MARK: - State

    @State private var viewModel: ReleaseViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ReleaseViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let release = viewModel.activeRelease ?? viewModel.selectedRelease {
                cockpitContent(release)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HelaiaEmptyState(
                    icon: "shippingbox",
                    title: "No active release",
                    description: "Create a release to see the cockpit"
                )
            }
        }
        .task { await viewModel.loadReleases() }
    }

    // MARK: - Content

    @ViewBuilder
    private func cockpitContent(_ release: CodalonRelease) -> some View {
        ScrollView {
            VStack(spacing: CodalonSpacing.zoneGap) {
                cockpitHeader(release)
                CockpitReadinessSummary(release: release)
                CockpitShipReadinessIndicator(release: release)

                HStack(alignment: .top, spacing: CodalonSpacing.zoneGap) {
                    VStack(spacing: CodalonSpacing.zoneGap) {
                        CockpitBlockersPanel(release: release, viewModel: viewModel)
                        CockpitChecklistPanel(release: release, viewModel: viewModel)
                    }
                    VStack(spacing: CodalonSpacing.zoneGap) {
                        CockpitLinkedIssuesPanel(release: release)
                        CockpitLinkedASCBuildPanel(release: release)
                    }
                }

                CockpitTimelinePanel(release: release)
                CockpitMissingItemsSummary(release: release)
                CockpitLaunchCriticalPanel(tasks: launchCriticalTasks(release))
                CockpitExportAction(release: release)
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func cockpitHeader(_ release: CodalonRelease) -> some View {
        HStack(spacing: Spacing._3) {
            ReleaseStatusBadge(status: release.status)

            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("Release Cockpit — v\(release.version)")
                    .helaiaFont(.title3)
                Text("Build \(release.buildNumber)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func launchCriticalTasks(_ release: CodalonRelease) -> [CodalonTask] {
        // Placeholder: in production, tasks would be fetched via the task service
        []
    }
}

// MARK: - Preview

#Preview("ReleaseCockpitView — Active Release") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.releases = [ReleasePreviewData.draftRelease, ReleasePreviewData.readyRelease]

    return ReleaseCockpitView(viewModel: vm)
        .frame(width: 900, height: 800)
}

#Preview("ReleaseCockpitView — No Release") {
    ReleaseCockpitView(viewModel: ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: UUID()
    ))
    .frame(width: 900, height: 600)
}
