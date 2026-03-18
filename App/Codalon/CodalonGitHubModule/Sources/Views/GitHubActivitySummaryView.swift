// Issue #98 — GitHub repo activity summary

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubActivitySummaryView

struct GitHubActivitySummaryView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: GitHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: CodalonSpacing.zoneGap) {
                    statsRow
                    recentClosedIssuesSection
                    recentMergedPRsSection
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "chart.line.uptrend.xyaxis",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("Activity — Last 7 Days")
                .helaiaFont(.title3)
            Spacer()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: Spacing._3) {
            statCard(
                title: "Open Issues",
                value: "\(viewModel.openIssueCount)",
                icon: "exclamationmark.circle",
                color: SemanticColor.warning(for: colorScheme)
            )
            statCard(
                title: "Open PRs",
                value: "\(viewModel.openPRCount)",
                icon: "arrow.triangle.pull",
                color: SemanticColor.success(for: colorScheme)
            )
            statCard(
                title: "Closed This Week",
                value: "\(viewModel.recentClosedIssues.count)",
                icon: "checkmark.circle",
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            statCard(
                title: "Merged PRs",
                value: "\(viewModel.recentMergedPRs.count)",
                icon: "arrow.triangle.merge",
                color: SemanticColor.textSecondary(for: colorScheme)
            )
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(spacing: Spacing._2) {
                HelaiaIconView(icon, size: .md, color: color)
                Text(value)
                    .helaiaFont(.title2)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                Text(title)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Recent Closed Issues

    @ViewBuilder
    private var recentClosedIssuesSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("RECENTLY CLOSED ISSUES")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(viewModel.recentClosedIssues.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                if viewModel.recentClosedIssues.isEmpty {
                    Text("No issues closed in the last 7 days")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(viewModel.recentClosedIssues.prefix(5)) { issue in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(
                                "checkmark.circle.fill",
                                size: .xs,
                                color: SemanticColor.textTertiary(for: colorScheme)
                            )
                            Text(issue.title)
                                .helaiaFont(.footnote)
                                .lineLimit(1)
                            Spacer()
                            Text("#\(issue.number)")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Merged PRs

    @ViewBuilder
    private var recentMergedPRsSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("RECENTLY MERGED PRS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(viewModel.recentMergedPRs.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                if viewModel.recentMergedPRs.isEmpty {
                    Text("No PRs merged in the last 7 days")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(viewModel.recentMergedPRs.prefix(5)) { pr in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(
                                "arrow.triangle.merge",
                                size: .xs,
                                color: SemanticColor.textTertiary(for: colorScheme)
                            )
                            Text(pr.title)
                                .helaiaFont(.footnote)
                                .lineLimit(1)
                            Spacer()
                            Text("#\(pr.number)")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubActivitySummaryView — Empty") {
    GitHubActivitySummaryView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 500)
}
