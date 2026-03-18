// Issue #75 — GitHub disconnect flow

import SwiftUI
import HelaiaDesign

// MARK: - GitHubDisconnectView

struct GitHubDisconnectView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var showConfirmation = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(viewModel: GitHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: CodalonSpacing.zoneGap) {
            connectionSummary

            if showConfirmation {
                confirmationCard
            } else {
                disconnectButton
            }
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Connection Summary

    @ViewBuilder
    private var connectionSummary: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView(
                        "person.circle.fill",
                        size: .lg,
                        color: SemanticColor.success(for: colorScheme)
                    )

                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text(viewModel.username)
                            .helaiaFont(.headline)
                        Text("Connected to GitHub")
                            .helaiaFont(.footnote)
                            .foregroundStyle(SemanticColor.success(for: colorScheme))
                    }

                    Spacer()
                }

                if !viewModel.linkedRepos.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: Spacing._2) {
                        Text("LINKED REPOSITORIES")
                            .helaiaFont(.tag)
                            .tracking(0.5)
                            .helaiaForeground(.textSecondary)

                        ForEach(viewModel.linkedRepos.filter { $0.deletedAt == nil }) { repo in
                            HStack(spacing: Spacing._2) {
                                HelaiaIconView(
                                    repo.isPrivate ? "lock.fill" : "folder.fill",
                                    size: .xs,
                                    color: SemanticColor.textSecondary(for: colorScheme)
                                )
                                Text(repo.fullName)
                                    .helaiaFont(.footnote)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Disconnect Button

    @ViewBuilder
    private var disconnectButton: some View {
        HelaiaButton.destructive("Disconnect GitHub") {
            showConfirmation = true
        }
        .fixedSize()
    }

    // MARK: - Confirmation

    @ViewBuilder
    private var confirmationCard: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "exclamationmark.triangle.fill",
                        size: .sm,
                        color: SemanticColor.warning(for: colorScheme)
                    )
                    Text("Are you sure?")
                        .helaiaFont(.headline)
                }

                Text("This will remove your GitHub credentials from the keychain and unlink all repositories from this project.")
                    .helaiaFont(.footnote)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                HStack(spacing: Spacing._3) {
                    HelaiaButton.destructive("Yes, Disconnect") {
                        Task {
                            await viewModel.disconnect()
                            dismiss()
                        }
                    }
                    .fixedSize()

                    HelaiaButton.ghost("Cancel") {
                        showConfirmation = false
                    }
                    .fixedSize()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubDisconnectView") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.username = "oliverherbelin"

    return GitHubDisconnectView(viewModel: vm)
        .frame(width: 500, height: 400)
}

#Preview("GitHubDisconnectView — No Repos") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.username = "oliverherbelin"

    return GitHubDisconnectView(viewModel: vm)
        .frame(width: 500, height: 300)
}
