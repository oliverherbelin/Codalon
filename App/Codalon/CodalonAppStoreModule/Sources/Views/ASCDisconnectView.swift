// Issue #193 — ASC disconnect flow

import SwiftUI
import HelaiaDesign

// MARK: - ASCDisconnectView

struct ASCDisconnectView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel
    @State private var showConfirmation = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(viewModel: ASCViewModel) {
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
                        "app.badge.checkmark",
                        size: .lg,
                        color: SemanticColor.success(for: colorScheme)
                    )

                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("App Store Connect")
                            .helaiaFont(.headline)
                        Text("Connected")
                            .helaiaFont(.footnote)
                            .foregroundStyle(SemanticColor.success(for: colorScheme))
                    }

                    Spacer()
                }

                if let app = viewModel.linkedApp {
                    Divider()

                    VStack(alignment: .leading, spacing: Spacing._2) {
                        Text("LINKED APP")
                            .helaiaFont(.tag)
                            .tracking(0.5)
                            .helaiaForeground(.textSecondary)

                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(
                                "app.fill",
                                size: .xs,
                                color: SemanticColor.textSecondary(for: colorScheme)
                            )
                            VStack(alignment: .leading, spacing: Spacing._0_5) {
                                Text(app.name)
                                    .helaiaFont(.footnote)
                                Text(app.bundleID)
                                    .helaiaFont(.caption1)
                                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
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
        HelaiaButton.destructive("Disconnect App Store Connect") {
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

                Text("This will remove your ASC API key from the keychain and unlink the app from this project.")
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

#Preview("ASCDisconnectView — With App") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.linkedApp = ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)

    return ASCDisconnectView(viewModel: vm)
        .frame(width: 500, height: 400)
}

#Preview("ASCDisconnectView — No App") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true

    return ASCDisconnectView(viewModel: vm)
        .frame(width: 500, height: 300)
}
