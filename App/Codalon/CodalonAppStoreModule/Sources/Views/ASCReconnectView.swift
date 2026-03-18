// Issue #191 — ASC reconnect flow

import SwiftUI
import HelaiaDesign

// MARK: - ASCReconnectView

struct ASCReconnectView: View {

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
                    Text("ASC credentials expired or invalid")
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    Text("Your App Store Connect API key is no longer valid. Generate a new key in App Store Connect and enter the credentials below.")
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

            HStack {
                HelaiaButton("Reconnect", icon: .sfSymbol("arrow.clockwise")) {
                    Task {
                        await viewModel.reconnect(
                            issuerID: issuerIDInput,
                            keyID: keyIDInput,
                            privateKey: privateKeyInput
                        )
                    }
                }
                .fixedSize()
                .disabled(issuerIDInput.isEmpty || keyIDInput.isEmpty || privateKeyInput.isEmpty)

                HelaiaButton.ghost("Disconnect Instead") {
                    Task { await viewModel.disconnect() }
                }
                .fixedSize()
            }
        }
        .frame(maxWidth: 500)
    }
}

// MARK: - Preview

#Preview("ASCReconnectView") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceExpired(),
        projectID: UUID()
    )
    vm.showReconnectPrompt = true

    return ASCReconnectView(viewModel: vm)
        .frame(width: 600, height: 500)
}
