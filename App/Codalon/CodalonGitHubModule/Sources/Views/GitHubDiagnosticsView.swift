// Issue #77 — GitHub connection diagnostics

import SwiftUI
import HelaiaDesign

// MARK: - GitHubDiagnosticsView

struct GitHubDiagnosticsView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var isValidating = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

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
                    connectionStatusSection
                    tokenStatusSection
                    linkedReposSection
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
        .task {
            await viewModel.checkAuth()
            await viewModel.loadLinkedRepos()
            isValidating = true
            await viewModel.validateConnection()
            isValidating = false
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "stethoscope",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("GitHub Diagnostics")
                .helaiaFont(.title3)
            Spacer()

            Button {
                Task {
                    isValidating = true
                    await viewModel.validateConnection()
                    isValidating = false
                }
            } label: {
                HStack(spacing: Spacing._1) {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Refresh")
                        .helaiaFont(.caption1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isValidating)
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Connection Status

    @ViewBuilder
    private var connectionStatusSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("CONNECTION STATUS")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                HelaiaSettingsRow(
                    title: "GitHub Account",
                    subtitle: connectionSubtitle,
                    icon: "person.circle",
                    iconColor: connectionIconColor,
                    variant: .value(viewModel.username.isEmpty ? "Not connected" : viewModel.username)
                )

                HelaiaSettingsRow(
                    title: "Connection",
                    subtitle: nil,
                    icon: connectionStatusIcon,
                    iconColor: connectionIconColor,
                    variant: .value(connectionStatusLabel)
                )
            }
        }
    }

    private var connectionSubtitle: String? {
        switch viewModel.connectionStatus {
        case .tokenExpired:
            "Token expired — reconnect required"
        case .error(let msg):
            msg
        default:
            nil
        }
    }

    private var connectionStatusIcon: String {
        switch viewModel.connectionStatus {
        case .connected: "checkmark.circle.fill"
        case .tokenExpired: "exclamationmark.triangle.fill"
        case .notConnected: "xmark.circle"
        case .error: "exclamationmark.octagon"
        }
    }

    private var connectionIconColor: Color {
        switch viewModel.connectionStatus {
        case .connected: SemanticColor.success(for: colorScheme)
        case .tokenExpired: SemanticColor.warning(for: colorScheme)
        case .notConnected: SemanticColor.textTertiary(for: colorScheme)
        case .error: SemanticColor.error(for: colorScheme)
        }
    }

    private var connectionStatusLabel: String {
        switch viewModel.connectionStatus {
        case .connected: "Active"
        case .tokenExpired: "Token Expired"
        case .notConnected: "Not Connected"
        case .error: "Error"
        }
    }

    // MARK: - Token Status

    @ViewBuilder
    private var tokenStatusSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("TOKEN STATUS")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                HelaiaSettingsRow(
                    title: "Personal Access Token",
                    subtitle: tokenSubtitle,
                    icon: "key.fill",
                    iconColor: tokenColor,
                    variant: .value(tokenStatusLabel)
                )

                HelaiaSettingsRow(
                    title: "Stored in",
                    icon: "lock.shield",
                    variant: .info("HelaiaKeychain")
                )
            }
        }
    }

    private var tokenStatusLabel: String {
        switch viewModel.connectionStatus {
        case .connected: "Valid"
        case .tokenExpired: "Expired"
        case .notConnected: "Not stored"
        case .error: "Unknown"
        }
    }

    private var tokenSubtitle: String? {
        switch viewModel.connectionStatus {
        case .tokenExpired:
            "Generate a new token from GitHub Settings > Developer settings"
        default:
            nil
        }
    }

    private var tokenColor: Color {
        switch viewModel.connectionStatus {
        case .connected: SemanticColor.success(for: colorScheme)
        case .tokenExpired: SemanticColor.error(for: colorScheme)
        default: SemanticColor.textSecondary(for: colorScheme)
        }
    }

    // MARK: - Linked Repos

    @ViewBuilder
    private var linkedReposSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("LINKED REPOSITORIES")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(viewModel.linkedRepos.filter { $0.deletedAt == nil }.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                let activeRepos = viewModel.linkedRepos.filter { $0.deletedAt == nil }

                if activeRepos.isEmpty {
                    Text("No repositories linked to this project")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(activeRepos) { repo in
                        HelaiaSettingsRow(
                            title: repo.fullName,
                            subtitle: "Branch: \(repo.defaultBranch)",
                            icon: repo.isPrivate ? "lock.fill" : "folder.fill",
                            iconColor: SemanticColor.textSecondary(for: colorScheme),
                            variant: .value(repo.isPrivate ? "Private" : "Public")
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubDiagnosticsView — Connected") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.username = "oliverherbelin"
    vm.connectionStatus = .connected(username: "oliverherbelin")
    vm.linkedRepos = [
        CodalonGitHubRepo(
            projectID: UUID(),
            owner: "oliverherbelin",
            name: "Codalon",
            isPrivate: true,
            defaultBranch: "main"
        ),
        CodalonGitHubRepo(
            projectID: UUID(),
            owner: "oliverherbelin",
            name: "HelaiaFrameworks",
            isPrivate: true,
            defaultBranch: "main"
        ),
    ]

    return GitHubDiagnosticsView(viewModel: vm)
        .frame(width: 600, height: 600)
        .environment(\.projectContext, .development)
}

#Preview("GitHubDiagnosticsView — Token Expired") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubServiceExpired(),
        projectID: UUID()
    )
    vm.isAuthenticated = false
    vm.username = "oliverherbelin"
    vm.connectionStatus = .tokenExpired

    return GitHubDiagnosticsView(viewModel: vm)
        .frame(width: 600, height: 500)
        .environment(\.projectContext, .development)
}

#Preview("GitHubDiagnosticsView — Not Connected") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    )

    return GitHubDiagnosticsView(viewModel: vm)
        .frame(width: 600, height: 500)
        .environment(\.projectContext, .development)
}
