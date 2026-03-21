// Issues #205, #218 — Integrations tab with live status indicators

import SwiftUI
import HelaiaDesign
import HelaiaEngine

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
    @State private var gitHubErrorDetail: String = ""
    @State private var ascTeamName: String = ""
    @State private var lastGitHubSync: Date?
    @State private var lastASCSync: Date?

    // GitHub connect form
    @State private var isConnectingGitHub = false
    @State private var gitHubTokenInput: String = ""
    @State private var gitHubUsernameInput: String = ""
    @State private var isSavingGitHub = false
    @State private var gitHubConnectError: String = ""

    // ASC connect form
    @State private var isConnectingASC = false
    @State private var ascIssuerID: String = ""
    @State private var ascKeyID: String = ""
    @State private var ascPrivateKey: String = ""
    @State private var isSavingASC = false
    @State private var ascConnectError: String = ""

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
        .task {
            await checkGitHubStatus()
            await checkASCStatus()
        }
    }

    // MARK: - Status Checks

    private func checkGitHubStatus() async {
        let container = ServiceContainer.shared
        guard let gitHubService = await container.resolveOptional(
            (any GitHubServiceProtocol).self
        ) else { return }

        let connectionStatus = await gitHubService.validateToken()
        switch connectionStatus {
        case .connected(let username):
            gitHubStatus = .connected
            gitHubUsername = username
            gitHubErrorDetail = ""
        case .tokenExpired:
            gitHubStatus = .error
            gitHubErrorDetail = "Your GitHub token has expired or been revoked. Please reconnect."
        case .notConnected:
            gitHubStatus = .disconnected
            gitHubUsername = ""
            gitHubErrorDetail = ""
        case .error(let message):
            gitHubStatus = .error
            gitHubErrorDetail = message
        }
    }

    private func checkASCStatus() async {
        let container = ServiceContainer.shared
        guard let credentialService = await container.resolveOptional(
            (any ASCCredentialServiceProtocol).self
        ) else { return }

        let exists = await credentialService.exists()
        if exists {
            ascStatus = .connected
            // Try to load the key ID as a display name
            if let credential = try? await credentialService.load() {
                ascTeamName = "Key: \(credential.keyID)"
            }
        } else {
            ascStatus = .disconnected
        }
    }

    // MARK: - GitHub Actions

    private func saveGitHubCredentials() async {
        guard !gitHubTokenInput.isEmpty, !gitHubUsernameInput.isEmpty else { return }

        isSavingGitHub = true
        gitHubConnectError = ""
        defer { isSavingGitHub = false }

        let container = ServiceContainer.shared
        guard let gitHubService = await container.resolveOptional(
            (any GitHubServiceProtocol).self
        ) else {
            gitHubConnectError = "GitHub service not available."
            return
        }

        do {
            try await gitHubService.authenticate(
                token: gitHubTokenInput,
                username: gitHubUsernameInput
            )
            isConnectingGitHub = false
            gitHubTokenInput = ""
            gitHubUsernameInput = ""
            await checkGitHubStatus()
        } catch {
            gitHubConnectError = error.localizedDescription
        }
    }

    private func disconnectGitHub() async {
        let container = ServiceContainer.shared
        if let gitHubService = await container.resolveOptional(
            (any GitHubServiceProtocol).self
        ) {
            try? await gitHubService.removeAuth()
        }
        gitHubStatus = .disconnected
        gitHubUsername = ""
        gitHubErrorDetail = ""
        lastGitHubSync = nil
    }

    // MARK: - ASC Actions

    private func saveASCCredentials() async {
        guard !ascIssuerID.isEmpty, !ascKeyID.isEmpty, !ascPrivateKey.isEmpty else { return }

        isSavingASC = true
        ascConnectError = ""
        defer { isSavingASC = false }

        let container = ServiceContainer.shared
        guard let credentialService = await container.resolveOptional(
            (any ASCCredentialServiceProtocol).self
        ) else {
            ascConnectError = "App Store Connect service not available."
            return
        }

        let credential = ASCCredential(
            issuerID: ascIssuerID,
            keyID: ascKeyID,
            privateKey: ascPrivateKey
        )

        do {
            try await credentialService.save(credential)
            isConnectingASC = false
            ascIssuerID = ""
            ascKeyID = ""
            ascPrivateKey = ""
            await checkASCStatus()
        } catch {
            ascConnectError = error.localizedDescription
        }
    }

    private func disconnectASC() async {
        let container = ServiceContainer.shared
        if let credentialService = await container.resolveOptional(
            (any ASCCredentialServiceProtocol).self
        ) {
            try? await credentialService.delete()
        }
        ascStatus = .disconnected
        ascTeamName = ""
        lastASCSync = nil
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

                if gitHubStatus == .error, !gitHubErrorDetail.isEmpty {
                    HStack(spacing: Spacing._2) {
                        HelaiaIconView("exclamationmark.triangle.fill", size: .sm, color: .orange)
                        Text(gitHubErrorDetail)
                            .helaiaFont(.caption1)
                            .foregroundStyle(.secondary)
                    }
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
                        Task { await disconnectGitHub() }
                    }
                } else if isConnectingGitHub {
                    gitHubConnectForm
                } else {
                    HelaiaSettingsRow(
                        title: "Connect GitHub",
                        subtitle: "Link your repositories and issues",
                        icon: "link",
                        iconColor: .blue,
                        variant: .navigation
                    ) {
                        isConnectingGitHub = true
                        gitHubConnectError = ""
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    @ViewBuilder
    private var gitHubConnectForm: some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            HelaiaTextField(
                title: "GitHub Username",
                text: $gitHubUsernameInput,
                placeholder: "your-username"
            )

            HelaiaSecureField(
                title: "Personal Access Token",
                text: $gitHubTokenInput,
                placeholder: "ghp_..."
            )

            if !gitHubConnectError.isEmpty {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView("exclamationmark.triangle.fill", size: .sm, color: .red)
                    Text(gitHubConnectError)
                        .helaiaFont(.caption1)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: Spacing._2) {
                HelaiaButton("Connect", icon: "link", variant: .primary, size: .small, isLoading: isSavingGitHub, fullWidth: false) {
                    Task { await saveGitHubCredentials() }
                }
                .disabled(gitHubTokenInput.isEmpty || gitHubUsernameInput.isEmpty || isSavingGitHub)

                HelaiaButton.ghost("Cancel", icon: "xmark") {
                    isConnectingGitHub = false
                    gitHubTokenInput = ""
                    gitHubUsernameInput = ""
                    gitHubConnectError = ""
                }
            }
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
                        Task { await disconnectASC() }
                    }
                } else if isConnectingASC {
                    ascConnectForm
                } else {
                    HelaiaSettingsRow(
                        title: "Connect App Store Connect",
                        subtitle: "Link builds, metadata, and reviews",
                        icon: "link",
                        iconColor: .blue,
                        variant: .navigation
                    ) {
                        isConnectingASC = true
                        ascConnectError = ""
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    @ViewBuilder
    private var ascConnectForm: some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            HelaiaTextField(
                title: "Issuer ID",
                text: $ascIssuerID,
                placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            )

            HelaiaTextField(
                title: "Key ID",
                text: $ascKeyID,
                placeholder: "XXXXXXXXXX"
            )

            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("Private Key (.p8)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(.secondary)

                TextEditor(text: $ascPrivateKey)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.secondary.opacity(Opacity.faint), lineWidth: BorderWidth.thin)
                    )
            }

            if !ascConnectError.isEmpty {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView("exclamationmark.triangle.fill", size: .sm, color: .red)
                    Text(ascConnectError)
                        .helaiaFont(.caption1)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: Spacing._2) {
                HelaiaButton("Connect", icon: "link", variant: .primary, size: .small, isLoading: isSavingASC, fullWidth: false) {
                    Task { await saveASCCredentials() }
                }
                .disabled(ascIssuerID.isEmpty || ascKeyID.isEmpty || ascPrivateKey.isEmpty || isSavingASC)

                HelaiaButton.ghost("Cancel", icon: "xmark") {
                    isConnectingASC = false
                    ascIssuerID = ""
                    ascKeyID = ""
                    ascPrivateKey = ""
                    ascConnectError = ""
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Integrations — Disconnected") {
    IntegrationsTabView()
        .frame(width: 500, height: 500)
}
