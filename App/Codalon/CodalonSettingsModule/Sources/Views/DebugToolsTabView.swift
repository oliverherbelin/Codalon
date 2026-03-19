// Issue #222 — Debug tools: reset DB, clear keychain, force sync, replay events

import SwiftUI
import HelaiaDesign

// MARK: - DebugToolsTabView

struct DebugToolsTabView: View {

    // MARK: - State

    @State private var showResetDBConfirmation = false
    @State private var showClearKeychainConfirmation = false
    @State private var showClearAnalyticsConfirmation = false
    @State private var isSyncing = false
    @State private var isReplayingEvents = false
    @State private var lastAction: String?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader("Debug Tools", trailing: {
                    HelaiaCapsule.tag("DEBUG BUILD ONLY", icon: "ant.fill")
                })

                Text("Development and debugging utilities. Use with caution.")
                    .helaiaFont(.body)
                    .foregroundStyle(.secondary)

                if let lastAction {
                    HelaiaCapsule.tag(lastAction, icon: "checkmark.circle.fill")
                }

                dataSection
                syncSection
                eventSection
            }
            .padding(Spacing._6)
        }
        .helaiaAlert(
            "Reset Local Database?",
            message: "This will delete all local data. This action cannot be undone.",
            style: .destructive,
            isPresented: $showResetDBConfirmation,
            actions: [
                HelaiaAlertAction("Reset", role: .destructive) {
                    lastAction = "Database reset (simulated)"
                },
                HelaiaAlertAction("Cancel", role: .cancel),
            ]
        )
        .helaiaAlert(
            "Clear Keychain?",
            message: "All stored credentials will be removed. You'll need to reconnect integrations.",
            style: .destructive,
            isPresented: $showClearKeychainConfirmation,
            actions: [
                HelaiaAlertAction("Clear", role: .destructive) {
                    lastAction = "Keychain cleared (simulated)"
                },
                HelaiaAlertAction("Cancel", role: .cancel),
            ]
        )
        .helaiaAlert(
            "Clear Analytics Data?",
            message: "All local analytics events will be permanently deleted.",
            style: .destructive,
            isPresented: $showClearAnalyticsConfirmation,
            actions: [
                HelaiaAlertAction("Clear", role: .destructive) {
                    lastAction = "Analytics data cleared (simulated)"
                },
                HelaiaAlertAction("Cancel", role: .cancel),
            ]
        )
    }

    // MARK: - Data Section

    @ViewBuilder
    private var dataSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView("cylinder.split.1x2.fill", size: .md)
                    Text("Data")
                        .helaiaFont(.headline)
                }

                HelaiaSettingsRow(
                    title: "Reset Local Database",
                    subtitle: "Delete all projects, tasks, milestones, and releases",
                    icon: "trash.fill",
                    iconColor: .red,
                    variant: .button,
                    isDestructive: true
                ) {
                    showResetDBConfirmation = true
                }

                HelaiaSettingsRow(
                    title: "Clear Keychain",
                    subtitle: "Remove all stored API keys and tokens",
                    icon: "key.fill",
                    iconColor: .red,
                    variant: .button,
                    isDestructive: true
                ) {
                    showClearKeychainConfirmation = true
                }

                HelaiaSettingsRow(
                    title: "Clear Analytics Data",
                    subtitle: "Delete all local analytics events",
                    icon: "chart.bar.xaxis",
                    iconColor: .red,
                    variant: .button,
                    isDestructive: true
                ) {
                    showClearAnalyticsConfirmation = true
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Sync Section

    @ViewBuilder
    private var syncSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView("arrow.triangle.2.circlepath", size: .md)
                    Text("Sync")
                        .helaiaFont(.headline)
                }

                HelaiaSettingsRow(
                    title: "Force Full Sync",
                    subtitle: "Re-fetch all data from GitHub and ASC",
                    icon: "arrow.clockwise",
                    iconColor: .blue,
                    variant: .button,
                    disabled: isSyncing
                ) {
                    Task {
                        isSyncing = true
                        try? await Task.sleep(for: .seconds(2))
                        isSyncing = false
                        lastAction = "Full sync completed (simulated)"
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Event Section

    @ViewBuilder
    private var eventSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView("bolt.fill", size: .md)
                    Text("Events")
                        .helaiaFont(.headline)
                }

                HelaiaSettingsRow(
                    title: "Replay Last 10 Events",
                    subtitle: "Re-publish recent events through the EventBus",
                    icon: "arrow.counterclockwise",
                    iconColor: .purple,
                    variant: .button,
                    disabled: isReplayingEvents
                ) {
                    Task {
                        isReplayingEvents = true
                        try? await Task.sleep(for: .seconds(1))
                        isReplayingEvents = false
                        lastAction = "Events replayed (simulated)"
                    }
                }
            }
            .padding(Spacing._4)
        }
    }
}

// MARK: - Preview

#Preview("Debug Tools") {
    DebugToolsTabView()
        .frame(width: 500, height: 700)
}
