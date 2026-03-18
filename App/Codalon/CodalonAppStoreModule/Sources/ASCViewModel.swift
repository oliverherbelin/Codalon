// Issues #183, #185, #187, #189, #191, #193, #195, #199, #201, #203, #206, #208, #210, #212, #214, #217 — ASC view model

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

    // Issue #199, #201, #203 — Build state
    var versions: [ASCVersion] = []
    var builds: [ASCBuild] = []
    var testFlightBuilds: [ASCTestFlightBuild] = []

    // Issue #206, #217 — Release notes
    var releaseNotes: [ASCReleaseNotes] = []
    var isUpdatingNotes = false

    // Issue #208, #210 — Metadata and localization
    var metadataStatus: ASCMetadataStatus?
    var localizationStatus: ASCLocalizationStatus?
    var missingMetadataFields: [ASCMetadataField] = []
    var incompleteLocales: [ASCLocaleCompleteness] = []

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

    // MARK: - Issue #199 — Fetch Versions

    func loadVersions() async {
        guard let app = linkedApp else { return }
        do {
            versions = try await ascService.fetchVersions(appID: app.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #201 — Fetch Builds

    func loadBuilds() async {
        guard let app = linkedApp else { return }
        isLoading = true
        do {
            builds = try await ascService.fetchBuilds(appID: app.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #203 — Fetch TestFlight Builds

    func loadTestFlightBuilds() async {
        guard let app = linkedApp else { return }
        do {
            testFlightBuilds = try await ascService.fetchTestFlightBuilds(appID: app.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #206 — Fetch Release Notes

    func loadReleaseNotes(versionID: String) async {
        do {
            releaseNotes = try await ascService.fetchReleaseNotes(versionID: versionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #217 — Update Release Notes

    func updateReleaseNotes(localizationID: String, whatsNew: String) async {
        isUpdatingNotes = true
        do {
            try await ascService.updateReleaseNotes(localizationID: localizationID, whatsNew: whatsNew)
            // Refresh after update
            if let version = versions.first {
                await loadReleaseNotes(versionID: version.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingNotes = false
    }

    // MARK: - Issue #208 — Fetch Metadata Status

    func loadMetadataStatus() async {
        guard let app = linkedApp else { return }
        do {
            metadataStatus = try await ascService.fetchMetadataStatus(appID: app.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #210 — Fetch Localization Status

    func loadLocalizationStatus(versionID: String) async {
        do {
            localizationStatus = try await ascService.fetchLocalizationStatus(versionID: versionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #219 — Detect Missing Metadata

    func detectMissingMetadata() async {
        guard let app = linkedApp else { return }
        do {
            missingMetadataFields = try await ascService.detectMissingMetadata(appID: app.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #221 — Detect Missing Localizations

    func detectMissingLocalizations(versionID: String) async {
        do {
            incompleteLocales = try await ascService.detectMissingLocalizations(versionID: versionID, threshold: 1.0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #223 — Map Readiness to Release

    func mapReadiness(versionID: String, releaseID: UUID) async {
        guard let app = linkedApp else { return }
        isLoading = true
        do {
            try await ascService.mapReadinessToRelease(appID: app.id, versionID: versionID, releaseID: releaseID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load All Build Data

    func loadAllBuildData() async {
        guard linkedApp != nil else { return }
        isLoading = true
        async let v: () = loadVersions()
        async let b: () = loadBuilds()
        async let tf: () = loadTestFlightBuilds()
        async let m: () = loadMetadataStatus()
        _ = await (v, b, tf, m)
        isLoading = false
    }
}
