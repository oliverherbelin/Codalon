// Issue #209 — Notifications tab: alert category notification config

import SwiftUI
import HelaiaDesign

// MARK: - NotificationsTabView

struct NotificationsTabView: View {

    // MARK: - State

    @State private var notificationsEnabled = true
    @State private var buildAlerts = true
    @State private var crashAlerts = true
    @State private var reviewAlerts = true
    @State private var releaseAlerts = true
    @State private var milestoneAlerts = true
    @State private var securityAlerts = true
    @State private var generalAlerts = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Notifications",
                    subtitle: "Choose which alert categories trigger local notifications."
                )

                masterToggle
                categorySection
                quietHoursSection
            }
            .padding(Spacing._6)
        }
    }

    // MARK: - Master Toggle

    @ViewBuilder
    private var masterToggle: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaSettingsRow(
                title: "Enable Notifications",
                subtitle: "Show local notifications for alerts",
                icon: "bell.fill",
                iconColor: .blue,
                variant: .toggle($notificationsEnabled)
            )
            .padding(Spacing._4)
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private var categorySection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Alert Categories")
                    .helaiaFont(.headline)

                HelaiaSettingsRow(
                    title: "Build Alerts",
                    subtitle: "Build processing, success, failure",
                    icon: "hammer.fill",
                    iconColor: .orange,
                    variant: .toggle($buildAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "Crash Alerts",
                    subtitle: "New crash reports and spikes",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    variant: .toggle($crashAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "Review Alerts",
                    subtitle: "New App Store reviews",
                    icon: "star.fill",
                    iconColor: .yellow,
                    variant: .toggle($reviewAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "Release Alerts",
                    subtitle: "Status changes, approval, rejection",
                    icon: "shippingbox.fill",
                    iconColor: .purple,
                    variant: .toggle($releaseAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "Milestone Alerts",
                    subtitle: "Approaching deadlines, completion",
                    icon: "flag.fill",
                    iconColor: .green,
                    variant: .toggle($milestoneAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "Security Alerts",
                    subtitle: "Credential expiry, vulnerability reports",
                    icon: "lock.shield.fill",
                    iconColor: .red,
                    variant: .toggle($securityAlerts),
                    disabled: !notificationsEnabled
                )

                HelaiaSettingsRow(
                    title: "General Alerts",
                    subtitle: "System messages, announcements",
                    icon: "bell.badge.fill",
                    iconColor: .gray,
                    variant: .toggle($generalAlerts),
                    disabled: !notificationsEnabled
                )
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Quiet Hours

    @ViewBuilder
    private var quietHoursSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._2) {
                Text("Quiet Hours")
                    .helaiaFont(.headline)

                Text("Notifications are suppressed during quiet hours. Configure in System Settings > Notifications > Focus.")
                    .helaiaFont(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing._4)
        }
    }
}

// MARK: - Preview

#Preview("Notifications") {
    NotificationsTabView()
        .frame(width: 500, height: 700)
}
