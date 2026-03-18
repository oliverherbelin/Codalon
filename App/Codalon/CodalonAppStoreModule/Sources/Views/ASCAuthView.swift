// Issue #183 — ASC connection flow

import SwiftUI
import HelaiaDesign

// MARK: - ASCAuthView

struct ASCAuthView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel
    @State private var issuerIDInput = ""
    @State private var keyIDInput = ""
    @State private var privateKeyInput = ""

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel) {
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
            Text("Connect App Store Connect")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Text("Enter your App Store Connect API key credentials. You can generate an API key in App Store Connect under Users and Access.")
                .helaiaFont(.body)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HelaiaTextField(
                title: "Issuer ID",
                text: $issuerIDInput,
                placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            )

            HelaiaTextField(
                title: "Key ID",
                text: $keyIDInput,
                placeholder: "XXXXXXXXXX"
            )

            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("Private Key (.p8)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                TextEditor(text: $privateKeyInput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColor.border(for: colorScheme), lineWidth: 1)
                    )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            HelaiaButton("Connect", icon: .sfSymbol("link")) {
                Task {
                    await viewModel.authenticate(
                        issuerID: issuerIDInput,
                        keyID: keyIDInput,
                        privateKey: privateKeyInput
                    )
                }
            }
            .fixedSize()
            .disabled(issuerIDInput.isEmpty || keyIDInput.isEmpty || privateKeyInput.isEmpty)
        }
        .frame(maxWidth: 500)
    }

    // MARK: - Authenticated

    @ViewBuilder
    private var authenticatedView: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    "app.badge.checkmark",
                    size: .lg,
                    color: SemanticColor.success(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    if let app = viewModel.linkedApp {
                        Text(app.name)
                            .helaiaFont(.headline)
                            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                        Text("Connected to App Store Connect")
                            .helaiaFont(.footnote)
                            .foregroundStyle(SemanticColor.success(for: colorScheme))
                    } else {
                        Text("App Store Connect")
                            .helaiaFont(.headline)
                            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                        Text("Connected — no app linked")
                            .helaiaFont(.footnote)
                            .foregroundStyle(SemanticColor.warning(for: colorScheme))
                    }
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

#Preview("ASCAuthView — Not Connected") {
    ASCAuthView(viewModel: ASCViewModel(
        ascService: PreviewASCService(),
        projectID: UUID()
    ))
}

#Preview("ASCAuthView — Connected") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.linkedApp = ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)

    return ASCAuthView(viewModel: vm)
        .frame(width: 500)
}
