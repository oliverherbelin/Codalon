// Issues #183, #185, #187, #189, #191, #193, #195 — ASC view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - ASCViewModel

@Observable
final class ASCViewModel {

    // MARK: - State

    var isAuthenticated = false
    var apps: [ASCApp] = []
    var linkedApp: ASCApp?
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""
    var connectionStatus: ASCConnectionStatus = .notConnected
    var showReconnectPrompt = false
    var diagnostics: ASCDiagnostics?

    // MARK: - Dependencies

    private let ascService: any ASCServiceProtocol
    let projectID: UUID

    // MARK: - Init

    init(ascService: any ASCServiceProtocol, projectID: UUID) {
        self.ascService = ascService
        self.projectID = projectID
    }

    // MARK: - Issue #183 — Auth

    func checkAuth() async {
        isAuthenticated = await ascService.isAuthenticated()
        if isAuthenticated {
            await loadLinkedApp()
        }
    }

    func authenticate(issuerID: String, keyID: String, privateKey: String) async {
        isLoading = true
        do {
            let credential = ASCCredential(
                issuerID: issuerID,
                keyID: keyID,
                privateKey: privateKey
            )
            try await ascService.authenticate(credential: credential)
            isAuthenticated = true
            errorMessage = nil
            await loadApps()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func removeAuth() async {
        do {
            try await ascService.removeAuth()
            isAuthenticated = false
            apps = []
            linkedApp = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #185 — Fetch Apps

    func loadApps() async {
        isLoading = true
        do {
            apps = try await ascService.fetchApps()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #189 — Link App

    func linkApp(_ app: ASCApp) async {
        do {
            try await ascService.linkApp(app, projectID: projectID)
            linkedApp = app
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unlinkApp() async {
        do {
            try await ascService.unlinkApp(projectID: projectID)
            linkedApp = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadLinkedApp() async {
        do {
            linkedApp = try await ascService.linkedApp(projectID: projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered

    var filteredApps: [ASCApp] {
        guard !searchQuery.isEmpty else { return apps }
        let query = searchQuery.lowercased()
        return apps.filter {
            $0.name.lowercased().contains(query)
                || $0.bundleID.lowercased().contains(query)
        }
    }

    var isAppLinked: (ASCApp) -> Bool {
        { [linkedApp] app in
            linkedApp?.bundleID == app.bundleID
        }
    }

    // MARK: - Issue #191 — Reconnect

    func validateConnection() async {
        connectionStatus = await ascService.validateCredentials()

        switch connectionStatus {
        case .connected:
            isAuthenticated = true
            showReconnectPrompt = false
        case .credentialsExpired:
            isAuthenticated = false
            showReconnectPrompt = true
        case .notConnected:
            isAuthenticated = false
            showReconnectPrompt = false
        case .error:
            isAuthenticated = false
            showReconnectPrompt = false
        }
    }

    func reconnect(issuerID: String, keyID: String, privateKey: String) async {
        isLoading = true
        do {
            let credential = ASCCredential(
                issuerID: issuerID,
                keyID: keyID,
                privateKey: privateKey
            )
            try await ascService.authenticate(credential: credential)
            isAuthenticated = true
            showReconnectPrompt = false
            connectionStatus = .connected(appName: issuerID)
            errorMessage = nil
            await loadApps()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #193 — Disconnect

    func disconnect() async {
        isLoading = true
        do {
            try await ascService.disconnect(projectID: projectID)
            isAuthenticated = false
            apps = []
            linkedApp = nil
            connectionStatus = .notConnected
            showReconnectPrompt = false
            diagnostics = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #195 — Diagnostics

    func loadDiagnostics() async {
        do {
            diagnostics = try await ascService.diagnostics(projectID: projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
