// Issue #100 — GitHub sync action view

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubSyncActionView

struct GitHubSyncActionView: View {

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
        VStack(spacing: CodalonSpacing.zoneGap) {
            syncButton
            if let result = viewModel.lastSyncResult {
                syncResultCard(result)
            }
            staleIssuesCard
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Sync Button

    @ViewBuilder
    private var syncButton: some View {
        HelaiaCard(variant: .elevated) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    "arrow.triangle.2.circlepath",
                    size: .md,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("GitHub Sync")
                        .helaiaFont(.headline)
                    Text("Refresh issues, milestones, and pull requests from GitHub")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()

                if viewModel.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    HelaiaButton("Sync Now", icon: .sfSymbol("arrow.clockwise")) {
                        guard let repo = viewModel.linkedRepos.first(where: { $0.deletedAt == nil }) else { return }
                        Task {
                            await viewModel.syncAll(owner: repo.owner, repo: repo.name)
                        }
                    }
                    .disabled(viewModel.linkedRepos.filter { $0.deletedAt == nil }.isEmpty)
                    .fixedSize()
                }
            }
        }
    }

    // MARK: - Sync Result

    @ViewBuilder
    private func syncResultCard(_ result: GitHubSyncResult) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("LAST SYNC")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text(result.timestamp, style: .relative)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }

                HStack(spacing: CodalonSpacing.zoneGap) {
                    resultStat("Issues", value: result.issuesFetched)
                    resultStat("Milestones", value: result.milestonesFetched)
                    resultStat("PRs", value: result.pullRequestsFetched)
                    resultStat("Stale", value: result.staleIssuesDetected, isWarning: result.staleIssuesDetected > 0)
                }
            }
        }
    }

    @ViewBuilder
    private func resultStat(_ label: String, value: Int, isWarning: Bool = false) -> some View {
        VStack(spacing: Spacing._1) {
            Text("\(value)")
                .helaiaFont(.title3)
                .foregroundStyle(
                    isWarning
                        ? SemanticColor.warning(for: colorScheme)
                        : SemanticColor.textPrimary(for: colorScheme)
                )
            Text(label)
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Issue #99 — Stale Issues

    @ViewBuilder
    private var staleIssuesCard: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    HelaiaIconView(
                        "clock.badge.exclamationmark",
                        size: .sm,
                        color: SemanticColor.warning(for: colorScheme)
                    )
                    Text("STALE ISSUES (30+ days)")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(viewModel.staleIssues.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                if viewModel.staleIssues.isEmpty {
                    Text("No stale issues detected")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(viewModel.staleIssues.prefix(10)) { issue in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(
                                "exclamationmark.triangle",
                                size: .xs,
                                color: SemanticColor.warning(for: colorScheme)
                            )
                            Text(issue.title)
                                .helaiaFont(.footnote)
                                .lineLimit(1)
                            Spacer()
                            Text("#\(issue.number)")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                            Text(issue.updatedAt, style: .relative)
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.warning(for: colorScheme))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubSyncActionView — No Sync") {
    GitHubSyncActionView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 400)
}

#Preview("GitHubSyncActionView — With Result") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubServiceConnected(),
        projectID: UUID()
    )
    vm.lastSyncResult = GitHubSyncResult(
        issuesFetched: 24,
        milestonesFetched: 3,
        pullRequestsFetched: 5,
        staleIssuesDetected: 2
    )

    return GitHubSyncActionView(viewModel: vm)
        .frame(width: 600, height: 500)
}
