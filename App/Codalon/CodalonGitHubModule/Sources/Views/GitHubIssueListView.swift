// Issue #83 — GitHub issue list view

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubIssueListView

struct GitHubIssueListView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var stateFilter = "open"
    @State private var selectedIssue: GitIssue?

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
            issueList
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "exclamationmark.circle",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("Issues")
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
                await viewModel.loadIssues(owner: repo.owner, repo: repo.name, state: newState)
            }
        }
    }

    // MARK: - Issue List

    @ViewBuilder
    private var issueList: some View {
        if viewModel.issues.isEmpty {
            HelaiaEmptyState(
                icon: "exclamationmark.circle",
                title: "No issues found",
                description: "Issues from your linked repository will appear here"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.issues) { issue in
                        issueRow(issue)
                            .onTapGesture { selectedIssue = issue }
                    }
                }
                .padding(CodalonSpacing.cardPadding)
            }
            .sheet(item: $selectedIssue) { issue in
                GitHubIssueDetailView(issue: issue, viewModel: viewModel)
            }
        }
    }

    // MARK: - Issue Row

    @ViewBuilder
    private func issueRow(_ issue: GitIssue) -> some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    issue.state == "open" ? "circle.fill" : "checkmark.circle.fill",
                    size: .sm,
                    color: issue.state == "open"
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(issue.title)
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    Text("#\(issue.number)")
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }

                Spacer()

                Text(issue.updatedAt, style: .relative)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubIssueListView") {
    GitHubIssueListView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 500)
}
