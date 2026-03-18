// Issue #73 — GitHub reconnect flow

import SwiftUI
import HelaiaDesign

// MARK: - GitHubReconnectView

struct GitHubReconnectView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var tokenInput = ""

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: GitHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: CodalonSpacing.zoneGap) {
            warningBanner
            reconnectForm
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Warning Banner

    @ViewBuilder
    private var warningBanner: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    "exclamationmark.triangle.fill",
                    size: .lg,
                    color: SemanticColor.warning(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Token expired or revoked")
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    Text("Your GitHub personal access token is no longer valid. Enter a new token to restore your connection.")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()
            }
        }
    }

    // MARK: - Reconnect Form

    @ViewBuilder
    private var reconnectForm: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            HelaiaSecureField(
                title: "New Personal Access Token",
                text: $tokenInput,
                placeholder: "ghp_..."
            )

            if let error = viewModel.errorMessage {
                Text(error)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            HStack {
                HelaiaButton("Reconnect", icon: .sfSymbol("arrow.clockwise")) {
                    Task {
                        await viewModel.reconnect(
                            token: tokenInput,
                            username: viewModel.username
                        )
                    }
                }
                .fixedSize()

                HelaiaButton.ghost("Disconnect Instead") {
                    Task { await viewModel.disconnect() }
                }
                .fixedSize()
            }
        }
        .frame(maxWidth: 400)
    }
}

// MARK: - Preview

#Preview("GitHubReconnectView") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubServiceExpired(),
        projectID: UUID()
    )
    vm.username = "oliverherbelin"
    vm.showReconnectPrompt = true

    return GitHubReconnectView(viewModel: vm)
        .frame(width: 500, height: 300)
}
