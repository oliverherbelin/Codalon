// Issue #67 — Repository selector

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - RepositorySelectorView

struct RepositorySelectorView: View {

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
            searchHeader
            Divider()
            repoList
        }
        .task {
            await viewModel.loadRepositories()
            await viewModel.loadLinkedRepos()
        }
    }

    // MARK: - Search Header

    @ViewBuilder
    private var searchHeader: some View {
        HStack(spacing: Spacing._3) {
            Text("Repositories")
                .helaiaFont(.title3)
            Spacer()
            HelaiaTextField(
                title: "",
                text: $viewModel.searchQuery,
                placeholder: "Search repositories…"
            )
            .frame(width: 240)
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Repo List

    @ViewBuilder
    private var repoList: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredRepositories.isEmpty {
            HelaiaEmptyState(
                icon: "folder",
                title: "No repositories found",
                description: "Connect your GitHub account to see repositories"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.filteredRepositories) { repo in
                        repoRow(repo)
                    }

                    if viewModel.filteredRepositories.count >= 30 {
                        HelaiaButton.ghost("Load More") {
                            Task { await viewModel.loadNextPage() }
                        }
                        .fixedSize()
                    }
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }

    // MARK: - Repo Row

    @ViewBuilder
    private func repoRow(_ repo: GitHubRepo) -> some View {
        let linked = viewModel.isRepoLinked(repo)

        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    repo.isPrivate ? "lock.fill" : "folder.fill",
                    size: .md,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(repo.fullName)
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    if let description = repo.description {
                        Text(description)
                            .helaiaFont(.footnote)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(repo.defaultBranch)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))

                if linked {
                    HelaiaIconView("checkmark.circle.fill", size: .md, color: SemanticColor.success(for: colorScheme))
                } else {
                    HelaiaButton.secondary("Link") {
                        Task { await viewModel.linkRepo(repo) }
                    }
                    .fixedSize()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("RepositorySelectorView") {
    RepositorySelectorView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
}