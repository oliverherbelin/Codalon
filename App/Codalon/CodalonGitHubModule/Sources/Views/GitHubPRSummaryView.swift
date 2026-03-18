// Issue #97 — GitHub PR summary view

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubPRSummaryView

struct GitHubPRSummaryView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var stateFilter = "open"

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
            prList
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "arrow.triangle.pull",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("Pull Requests")
                .helaiaFont(.title3)

            Spacer()

            Picker("State", selection: $stateFilter) {
                Text("Open").tag("open")
                Text("Closed").tag("closed")
                Text("All").tag("all")
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
        .onChange(of: stateFilter) { _, newState in
            guard let repo = viewModel.linkedRepos.first(where: { $0.deletedAt == nil }) else { return }
            Task {
                await viewModel.loadPullRequests(owner: repo.owner, repo: repo.name, state: newState)
            }
        }
    }

    // MARK: - PR List

    @ViewBuilder
    private var prList: some View {
        if viewModel.pullRequests.isEmpty {
            HelaiaEmptyState(
                icon: "arrow.triangle.pull",
                title: "No pull requests found",
                description: "Pull requests from your linked repository will appear here"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.pullRequests) { pr in
                        prRow(pr)
                    }
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }

    // MARK: - PR Row

    @ViewBuilder
    private func prRow(_ pr: GitPullRequest) -> some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    pr.state == "open" ? "arrow.triangle.pull" : "arrow.triangle.merge",
                    size: .sm,
                    color: pr.state == "open"
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(pr.title)
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                    HStack(spacing: Spacing._2) {
                        Text("#\(pr.number)")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))

                        Text("\(pr.headRef) → \(pr.baseRef)")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                Text(pr.state.capitalized)
                    .helaiaFont(.caption1)
                    .foregroundStyle(
                        pr.state == "open"
                            ? SemanticColor.success(for: colorScheme)
                            : SemanticColor.textTertiary(for: colorScheme)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubPRSummaryView") {
    GitHubPRSummaryView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 500)
}
