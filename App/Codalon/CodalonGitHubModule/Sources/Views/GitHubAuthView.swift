// Issue #59 — GitHub auth flow

import SwiftUI
import HelaiaDesign

// MARK: - GitHubAuthView

struct GitHubAuthView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var tokenInput = ""
    @State private var usernameInput = ""

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: GitHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: CodalonSpacing.zoneGap) {
            if viewModel.isAuthenticated {
                authenticatedView
            } else {
                authForm
            }
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.checkAuth()
        }
    }

    // MARK: - Auth Form

    @ViewBuilder
    private var authForm: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            Text("Connect GitHub")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Text("Enter a personal access token to connect your GitHub account.")
                .helaiaFont(.body)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HelaiaTextField(
                title: "Username",
                text: $usernameInput,
                placeholder: "GitHub username"
            )

            HelaiaSecureField(
                title: "Personal Access Token",
                text: $tokenInput,
                placeholder: "ghp_..."
            )

            HelaiaButton("Connect", icon: .sfSymbol("link")) {
                Task {
                    await viewModel.authenticate(
                        token: tokenInput,
                        username: usernameInput
                    )
                }
            }
            .fixedSize()
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Authenticated

    @ViewBuilder
    private var authenticatedView: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView("person.circle.fill", size: .lg, color: SemanticColor.success(for: colorScheme))

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(viewModel.username)
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    Text("Connected to GitHub")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.success(for: colorScheme))
                }

                Spacer()

                HelaiaButton.destructive("Disconnect") {
                    Task { await viewModel.removeAuth() }
                }
                .fixedSize()
            }
        }
    }
}

// MARK: - Preview

#Preview("GitHubAuthView — Not Authenticated") {
    GitHubAuthView(viewModel: GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    ))
}