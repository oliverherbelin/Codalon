// Issue #195 — ASC diagnostics state in settings

import SwiftUI
import HelaiaDesign

// MARK: - ASCDiagnosticsView

struct ASCDiagnosticsView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            Text("App Store Connect")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            if let diag = viewModel.diagnostics {
                diagnosticsContent(diag)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadDiagnostics()
        }
    }

    // MARK: - Diagnostics Content

    @ViewBuilder
    private func diagnosticsContent(_ diag: ASCDiagnostics) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                statusRow(diag.status)

                Divider()

                if let name = diag.linkedAppName, let bundleID = diag.linkedBundleID {
                    diagnosticRow(
                        icon: "app.fill",
                        label: "Linked App",
                        value: "\(name) (\(bundleID))"
                    )
                } else {
                    diagnosticRow(
                        icon: "app.dashed",
                        label: "Linked App",
                        value: "None"
                    )
                }

                Divider()

                diagnosticRow(
                    icon: "clock.fill",
                    label: "Last Successful Fetch",
                    value: diag.lastSuccessfulFetch.map {
                        $0.formatted(date: .abbreviated, time: .shortened)
                    } ?? "Never"
                )
            }
        }
    }

    // MARK: - Status Row

    @ViewBuilder
    private func statusRow(_ status: ASCConnectionStatus) -> some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                statusIcon(status),
                size: .md,
                color: statusColor(status)
            )

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text("Connection Status")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                Text(statusLabel(status))
                    .helaiaFont(.headline)
                    .foregroundStyle(statusColor(status))
            }

            Spacer()
        }
    }

    // MARK: - Diagnostic Row

    @ViewBuilder
    private func diagnosticRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                icon,
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(label)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                Text(value)
                    .helaiaFont(.footnote)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
            }

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Status Helpers

    private func statusIcon(_ status: ASCConnectionStatus) -> String {
        switch status {
        case .connected: "checkmark.circle.fill"
        case .credentialsExpired: "exclamationmark.triangle.fill"
        case .notConnected: "xmark.circle.fill"
        case .error: "exclamationmark.octagon.fill"
        }
    }

    private func statusColor(_ status: ASCConnectionStatus) -> Color {
        switch status {
        case .connected: SemanticColor.success(for: colorScheme)
        case .credentialsExpired: SemanticColor.warning(for: colorScheme)
        case .notConnected: SemanticColor.textSecondary(for: colorScheme)
        case .error: SemanticColor.error(for: colorScheme)
        }
    }

    private func statusLabel(_ status: ASCConnectionStatus) -> String {
        switch status {
        case .connected(let name): "Connected (\(name))"
        case .credentialsExpired: "Credentials Expired"
        case .notConnected: "Not Connected"
        case .error(let msg): "Error: \(msg)"
        }
    }
}

// MARK: - Preview

#Preview("ASCDiagnosticsView — Connected") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.diagnostics = ASCDiagnostics(
        status: .connected(appName: "Codalon"),
        linkedAppName: "Codalon",
        linkedBundleID: "com.helaia.Codalon",
        lastSuccessfulFetch: Date().addingTimeInterval(-300)
    )

    return ASCDiagnosticsView(viewModel: vm)
        .frame(width: 500)
}

#Preview("ASCDiagnosticsView — Not Connected") {
    let vm = ASCViewModel(
        ascService: PreviewASCService(),
        projectID: UUID()
    )
    vm.diagnostics = ASCDiagnostics(status: .notConnected)

    return ASCDiagnosticsView(viewModel: vm)
        .frame(width: 500)
}

#Preview("ASCDiagnosticsView — Expired") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceExpired(),
        projectID: UUID()
    )
    vm.diagnostics = ASCDiagnostics(
        status: .credentialsExpired,
        linkedAppName: "Codalon",
        linkedBundleID: "com.helaia.Codalon"
    )

    return ASCDiagnosticsView(viewModel: vm)
        .frame(width: 500)
}
