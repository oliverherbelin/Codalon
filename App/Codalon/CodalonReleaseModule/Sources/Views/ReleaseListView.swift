// Issue #122 — Release list view

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseListView

struct ReleaseListView: View {

    // MARK: - State

    @State private var viewModel: ReleaseViewModel
    @State private var showCreateForm = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ReleaseViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            releaseList
        }
        .task { await viewModel.loadReleases() }
        .sheet(isPresented: $showCreateForm) {
            ReleaseFormView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "shippingbox.fill",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("Releases")
                .helaiaFont(.title3)

            Spacer()

            HelaiaButton("New Release", icon: .sfSymbol("plus")) {
                showCreateForm = true
            }
            .fixedSize()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Release List

    @ViewBuilder
    private var releaseList: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.releases.isEmpty {
            HelaiaEmptyState(
                icon: "shippingbox",
                title: "No releases",
                description: "Create your first release to start tracking readiness"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.releases) { release in
                        releaseRow(release)
                    }
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }

    // MARK: - Release Row

    @ViewBuilder
    private func releaseRow(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                ReleaseStatusBadge(status: release.status)

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("v\(release.version)")
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                    HStack(spacing: Spacing._2) {
                        Text("Build \(release.buildNumber)")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))

                        if let date = release.targetDate {
                            Text(date, style: .date)
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }
                    }
                }

                Spacer()

                readinessIndicator(release.readinessScore)

                if release.blockerCount > 0 {
                    HStack(spacing: Spacing._1) {
                        HelaiaIconView(
                            "exclamationmark.triangle.fill",
                            size: .xs,
                            color: SemanticColor.error(for: colorScheme)
                        )
                        Text("\(release.blockerCount)")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.error(for: colorScheme))
                    }
                }
            }
        }
        .onTapGesture {
            viewModel.selectedRelease = release
        }
    }

    @ViewBuilder
    private func readinessIndicator(_ score: Double) -> some View {
        HStack(spacing: Spacing._1) {
            HelaiaProgressRing(
                value: score / 100,
                size: 24,
                lineWidth: 3
            )
            .tint(readinessColor(score))
            Text("\(Int(score))%")
                .helaiaFont(.caption1)
                .foregroundStyle(readinessColor(score))
        }
    }

    private func readinessColor(_ score: Double) -> Color {
        switch score {
        case 80...: SemanticColor.success(for: colorScheme)
        case 50..<80: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.error(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("ReleaseListView") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.releases = [ReleasePreviewData.draftRelease, ReleasePreviewData.readyRelease, ReleasePreviewData.releasedRelease]

    return ReleaseListView(viewModel: vm)
        .frame(width: 600, height: 500)
}

#Preview("ReleaseListView — Empty") {
    ReleaseListView(viewModel: ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 400)
}
