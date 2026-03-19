// Issue #216 — Diagnostics tab: storage, sync state, error log, API times

import SwiftUI
import HelaiaDesign

// MARK: - DiagnosticItem

struct DiagnosticItem: Identifiable, Sendable {
    let id: String
    let label: String
    let value: String
    let iconName: String
    let iconColor: Color
}

// MARK: - DiagnosticsTabView

struct DiagnosticsTabView: View {

    // MARK: - State

    @State private var storageExpanded = true
    @State private var syncExpanded = true
    @State private var apiExpanded = true
    @State private var errorsExpanded = true
    @State private var errorLogEntries: [String] = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Diagnostics",
                    subtitle: "App health, storage, sync state, and recent errors."
                )

                storageSection
                syncSection
                apiSection
                errorLogSection
            }
            .padding(Spacing._6)
        }
    }

    // MARK: - Storage Section

    @ViewBuilder
    private var storageSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaExpandableSection(
                title: "Storage",
                isExpanded: $storageExpanded,
                icon: "internaldrive.fill"
            ) {
                VStack(alignment: .leading, spacing: Spacing._1) {
                    ForEach(DiagnosticsTabView.defaultStorageItems) { item in
                        HelaiaSettingsRow(
                            title: item.label,
                            icon: item.iconName,
                            iconColor: item.iconColor,
                            variant: .info(item.value)
                        )
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Sync Section

    @ViewBuilder
    private var syncSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaExpandableSection(
                title: "Sync State",
                isExpanded: $syncExpanded,
                icon: "arrow.triangle.2.circlepath"
            ) {
                VStack(alignment: .leading, spacing: Spacing._1) {
                    ForEach(DiagnosticsTabView.defaultSyncItems) { item in
                        HelaiaSettingsRow(
                            title: item.label,
                            icon: item.iconName,
                            iconColor: item.iconColor,
                            variant: .info(item.value)
                        )
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - API Section

    @ViewBuilder
    private var apiSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaExpandableSection(
                title: "Last API Fetch Times",
                isExpanded: $apiExpanded,
                icon: "network"
            ) {
                VStack(alignment: .leading, spacing: Spacing._1) {
                    ForEach(DiagnosticsTabView.defaultAPIItems) { item in
                        HelaiaSettingsRow(
                            title: item.label,
                            icon: item.iconName,
                            iconColor: item.iconColor,
                            variant: .info(item.value)
                        )
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Error Log Section

    @ViewBuilder
    private var errorLogSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaExpandableSection(
                title: "Recent Errors",
                isExpanded: $errorsExpanded,
                icon: "exclamationmark.bubble.fill",
                badge: errorLogEntries.isEmpty ? nil : "\(errorLogEntries.count)"
            ) {
                VStack(alignment: .leading, spacing: Spacing._2) {
                    if errorLogEntries.isEmpty {
                        HelaiaEmptyState(
                            icon: "checkmark.circle",
                            title: "No Recent Errors",
                            description: "Everything is running smoothly."
                        )
                    } else {
                        ForEach(errorLogEntries, id: \.self) { entry in
                            Text(entry)
                                .helaiaFont(.caption1)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        HelaiaButton.destructive("Clear Errors", icon: "trash") {
                            errorLogEntries.removeAll()
                        }
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Default Data

    private static let defaultStorageItems: [DiagnosticItem] = [
        DiagnosticItem(id: "db_size", label: "Database Size", value: "—", iconName: "cylinder.fill", iconColor: .blue),
        DiagnosticItem(id: "cache_size", label: "Cache Size", value: "—", iconName: "memorychip.fill", iconColor: .orange),
        DiagnosticItem(id: "keychain", label: "Keychain Items", value: "—", iconName: "key.fill", iconColor: .purple),
    ]

    private static let defaultSyncItems: [DiagnosticItem] = [
        DiagnosticItem(id: "github_sync", label: "GitHub Sync", value: "Idle", iconName: "arrow.triangle.branch", iconColor: .green),
        DiagnosticItem(id: "asc_sync", label: "ASC Sync", value: "Idle", iconName: "app.badge.fill", iconColor: .green),
        DiagnosticItem(id: "last_full_sync", label: "Last Full Sync", value: "Never", iconName: "clock.fill", iconColor: .gray),
    ]

    private static let defaultAPIItems: [DiagnosticItem] = [
        DiagnosticItem(id: "github_api", label: "GitHub API", value: "Never", iconName: "arrow.triangle.branch", iconColor: .gray),
        DiagnosticItem(id: "asc_api", label: "ASC API", value: "Never", iconName: "app.badge.fill", iconColor: .gray),
        DiagnosticItem(id: "ai_api", label: "AI Provider", value: "Never", iconName: "brain", iconColor: .gray),
    ]
}

// MARK: - Preview

#Preview("Diagnostics") {
    DiagnosticsTabView()
        .frame(width: 500, height: 700)
}
