// Issues #205, #218 — Integrations tab with live status indicators

import SwiftUI
import HelaiaDesign

// MARK: - IntegrationStatus

enum IntegrationStatus: String, Sendable {
    case connected
    case disconnected
    case error

    var label: String {
        switch self {
        case .connected: "Connected"
        case .disconnected: "Not Connected"
        case .error: "Error"
        }
    }

    var iconName: String {
        switch self {
        case .connected: "checkmark.circle.fill"
        case .disconnected: "xmark.circle"
        case .error: "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - IntegrationsTabView

struct IntegrationsTabView: View {

    // MARK: - State

    @State private var gitHubStatus: IntegrationStatus = .disconnected
    @State private var ascStatus: IntegrationStatus = .disconnected
    @State private var gitHubUsername: String = ""
    @State private var ascTeamName: String = ""
    @State private var lastGitHubSync: Date?
    @State private var lastASCSync: Date?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Integrations",
                    subtitle: "Manage connections to external services."
                )

                gitHubSection
                ascSection
            }
            .padding(Spacing._6)
        }
    }

    // MARK: - GitHub Section

    @ViewBuilder
    private var gitHubSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._4) {
                HStack {
                    HelaiaIconView("arrow.triangle.branch", size: .md)
                    Text("GitHub")
                        .helaiaFont(.headline)

                    Spacer()

                    HelaiaCapsule.tag(
                        gitHubStatus.label,
                        icon: gitHubStatus.iconName
                    )
                }

                if gitHubStatus == .connected {
                    HelaiaSettingsRow(
                        title: "Account",
                        icon: "person.fill",
                        iconColor: .purple,
                        variant: .info(gitHubUsername.isEmpty ? "—" : gitHubUsername)
                    )

                    if let lastSync = lastGitHubSync {
                        HelaiaSettingsRow(
                            title: "Last Sync",
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .blue,
                            variant: .info(lastSync.formatted(date: .abbreviated, time: .shortened))
                        )
                    }

                    HelaiaSettingsRow(
                        title: "Disconnect GitHub",
                        icon: "xmark.circle",
                        iconColor: .red,
                        variant: .button,
                        isDestructive: true
                    ) {
                        gitHubStatus = .disconnected
                        gitHubUsername = ""
                        lastGitHubSync = nil
                    }
                } else {
                    HelaiaSettingsRow(
                        title: "Connect GitHub",
                        subtitle: "Link your repositories and issues",
                        icon: "link",
                        iconColor: .blue,
                        variant: .navigation
                    ) {
                        // Opens connection flow in GitHub module
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - App Store Connect Section

    @ViewBuilder
    private var ascSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._4) {
                HStack {
                    HelaiaIconView("app.badge.fill", size: .md)
                    Text("App Store Connect")
                        .helaiaFont(.headline)

                    Spacer()

                    HelaiaCapsule.tag(
                        ascStatus.label,
                        icon: ascStatus.iconName
                    )
                }

                if ascStatus == .connected {
                    HelaiaSettingsRow(
                        title: "Team",
                        icon: "person.2.fill",
                        iconColor: .indigo,
                        variant: .info(ascTeamName.isEmpty ? "—" : ascTeamName)
                    )

                    if let lastSync = lastASCSync {
                        HelaiaSettingsRow(
                            title: "Last Sync",
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .blue,
                            variant: .info(lastSync.formatted(date: .abbreviated, time: .shortened))
                        )
                    }

                    HelaiaSettingsRow(
                        title: "Disconnect App Store Connect",
                        icon: "xmark.circle",
                        iconColor: .red,
                        variant: .button,
                        isDestructive: true
                    ) {
                        ascStatus = .disconnected
                        ascTeamName = ""
                        lastASCSync = nil
                    }
                } else {
                    HelaiaSettingsRow(
                        title: "Connect App Store Connect",
                        subtitle: "Link builds, metadata, and reviews",
                        icon: "link",
                        iconColor: .blue,
                        variant: .navigation
                    ) {
                        // Opens connection flow in ASC module
                    }
                }
            }
            .padding(Spacing._4)
        }
    }
}

// MARK: - Preview

#Preview("Integrations — Disconnected") {
    IntegrationsTabView()
        .frame(width: 500, height: 500)
}
