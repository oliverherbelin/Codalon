// Issues #179, #181, #183, #185, #189, #191, #193, #195, #199, #201, #203, #206, #208, #210, #217, #219, #221, #223 — ASC service

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol ASCServiceProtocol: Sendable {
    func authenticate(credential: ASCCredential) async throws
    func isAuthenticated() async -> Bool
    func removeAuth() async throws
    func fetchApps() async throws -> [ASCApp]
    func linkApp(_ app: ASCApp, projectID: UUID) async throws
    func unlinkApp(projectID: UUID) async throws
    func linkedApp(projectID: UUID) async throws -> ASCApp?
    func validateCredentials() async -> ASCConnectionStatus
    func disconnect(projectID: UUID) async throws
    func diagnostics(projectID: UUID) async throws -> ASCDiagnostics
    func fetchVersions(appID: String) async throws -> [ASCVersion]
    func fetchBuilds(appID: String) async throws -> [ASCBuild]
    func fetchTestFlightBuilds(appID: String) async throws -> [ASCTestFlightBuild]
    func fetchReleaseNotes(versionID: String) async throws -> [ASCReleaseNotes]
    func updateReleaseNotes(localizationID: String, whatsNew: String) async throws
    func fetchMetadataStatus(appID: String) async throws -> ASCMetadataStatus
    func fetchLocalizationStatus(versionID: String) async throws -> ASCLocalizationStatus
    func detectMissingMetadata(appID: String) async throws -> [ASCMetadataField]
    func detectMissingLocalizations(versionID: String, threshold: Double) async throws -> [ASCLocaleCompleteness]
    func mapReadinessToRelease(appID: String, versionID: String, releaseID: UUID) async throws
}

// MARK: - Implementation

public actor ASCService: ASCServiceProtocol {

    private let credentialService: any ASCCredentialServiceProtocol
    private let apiClient: any ASCAPIClientProtocol
    private let projectRepository: any ProjectRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    private var lastSuccessfulFetch: Date?
    private var cachedLinkedApps: [UUID: ASCApp] = [:]

    public init(
        credentialService: any ASCCredentialServiceProtocol,
        apiClient: any ASCAPIClientProtocol,
        projectRepository: any ProjectRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.credentialService = credentialService
        self.apiClient = apiClient
        self.projectRepository = projectRepository
        self.releaseRepository = releaseRepository
        self.logger = logger
    }

    // MARK: - Issue #183 — Authenticate

    public func authenticate(credential: ASCCredential) async throws {
        logger.info("Authenticating ASC (issuerID: \(credential.issuerID))", category: "asc")

        let valid = try await apiClient.validateCredentials(credential)
        guard valid else {
            logger.error("ASC credential validation failed", category: "asc")
            throw ASCServiceError.invalidCredentials
        }

        try await credentialService.save(credential)
        await publish(ASCAuthenticatedEvent(issuerID: credential.issuerID))
        logger.success("ASC authentication succeeded", category: "asc")
    }

    // MARK: - Issue #181 — Auth Check

    public func isAuthenticated() async -> Bool {
        await credentialService.exists()
    }

    public func removeAuth() async throws {
        logger.info("Removing ASC authentication", category: "asc")
        do {
            try await credentialService.delete()
            await publish(ASCAuthRemovedEvent())
            logger.success("ASC credentials removed", category: "asc")
        } catch {
            logger.error("Failed to remove ASC credentials: \(error.localizedDescription)", category: "asc")
            throw error
        }
    }

    // MARK: - Issue #185 — Fetch Apps

    public func fetchApps() async throws -> [ASCApp] {
        let credential = try await loadCredentialOrThrow()
        let apps = try await apiClient.fetchApps(credential: credential)
        lastSuccessfulFetch = Date()
        return apps
    }

    // MARK: - Issue #189 — Link App

    public func linkApp(_ app: ASCApp, projectID: UUID) async throws {
        logger.info("Linking ASC app '\(app.name)' (\(app.bundleID)) to project \(projectID.uuidString)", category: "asc")

        var project = try await projectRepository.load(id: projectID)
        project.linkedASCApp = app.bundleID
        project.updatedAt = Date()
        try await projectRepository.save(project)

        cachedLinkedApps[projectID] = app

        await publish(ASCAppLinkedEvent(
            projectID: projectID,
            appName: app.name,
            bundleID: app.bundleID
        ))
        logger.success("ASC app linked: \(app.name)", category: "asc")
    }

    // MARK: - Issue #193 — Unlink App

    public func unlinkApp(projectID: UUID) async throws {
        logger.info("Unlinking ASC app from project \(projectID.uuidString)", category: "asc")

        var project = try await projectRepository.load(id: projectID)
        project.linkedASCApp = nil
        project.updatedAt = Date()
        try await projectRepository.save(project)

        cachedLinkedApps.removeValue(forKey: projectID)

        await publish(ASCAppUnlinkedEvent(projectID: projectID))
        logger.success("ASC app unlinked from project \(projectID.uuidString)", category: "asc")
    }

    public func linkedApp(projectID: UUID) async throws -> ASCApp? {
        if let cached = cachedLinkedApps[projectID] {
            return cached
        }

        let project = try await projectRepository.load(id: projectID)
        guard let bundleID = project.linkedASCApp else { return nil }

        // Try to fetch app details from ASC
        do {
            let apps = try await fetchApps()
            if let app = apps.first(where: { $0.bundleID == bundleID }) {
                cachedLinkedApps[projectID] = app
                return app
            }
        } catch {
            logger.warning("Could not fetch ASC app details for \(bundleID): \(error.localizedDescription)", category: "asc")
        }

        // Return minimal info from stored bundleID
        let fallback = ASCApp(id: "", name: bundleID, bundleID: bundleID, platform: .macOS)
        return fallback
    }

    // MARK: - Issue #191 — Validate / Reconnect

    public func validateCredentials() async -> ASCConnectionStatus {
        logger.info("Validating ASC credentials", category: "asc")

        guard await credentialService.exists() else {
            logger.info("No ASC credentials found", category: "asc")
            return .notConnected
        }

        do {
            let credential = try await credentialService.load()
            let valid = try await apiClient.validateCredentials(credential)
            if valid {
                logger.success("ASC credentials valid", category: "asc")
                return .connected(appName: credential.issuerID)
            } else {
                logger.warning("ASC credentials expired or invalid", category: "asc")
                return .credentialsExpired
            }
        } catch {
            logger.error("ASC credential validation failed: \(error.localizedDescription)", category: "asc")
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Issue #193 — Disconnect

    public func disconnect(projectID: UUID) async throws {
        logger.info("Disconnecting ASC for project \(projectID.uuidString)", category: "asc")

        // Unlink app from project
        do {
            try await unlinkApp(projectID: projectID)
        } catch {
            logger.warning("No ASC app to unlink: \(error.localizedDescription)", category: "asc")
        }

        // Remove credentials
        try await removeAuth()
        lastSuccessfulFetch = nil
        logger.success("ASC fully disconnected for project \(projectID.uuidString)", category: "asc")
    }

    // MARK: - Issue #195 — Diagnostics

    public func diagnostics(projectID: UUID) async throws -> ASCDiagnostics {
        let status = await validateCredentials()
        let linked = try await linkedApp(projectID: projectID)

        return ASCDiagnostics(
            status: status,
            linkedAppName: linked?.name,
            linkedBundleID: linked?.bundleID,
            lastSuccessfulFetch: lastSuccessfulFetch
        )
    }

    // MARK: - Issue #199 — Fetch Versions

    public func fetchVersions(appID: String) async throws -> [ASCVersion] {
        let credential = try await loadCredentialOrThrow()
        let versions = try await apiClient.fetchVersions(appID: appID, credential: credential)
        lastSuccessfulFetch = Date()
        return versions
    }

    // MARK: - Issue #201 — Fetch Builds

    public func fetchBuilds(appID: String) async throws -> [ASCBuild] {
        let credential = try await loadCredentialOrThrow()
        let builds = try await apiClient.fetchBuilds(appID: appID, credential: credential)
        lastSuccessfulFetch = Date()
        return builds
    }

    // MARK: - Issue #203 — Fetch TestFlight Builds

    public func fetchTestFlightBuilds(appID: String) async throws -> [ASCTestFlightBuild] {
        let credential = try await loadCredentialOrThrow()
        let builds = try await apiClient.fetchTestFlightBuilds(appID: appID, credential: credential)
        lastSuccessfulFetch = Date()
        return builds
    }

    // MARK: - Issue #206 — Fetch Release Notes

    public func fetchReleaseNotes(versionID: String) async throws -> [ASCReleaseNotes] {
        let credential = try await loadCredentialOrThrow()
        return try await apiClient.fetchReleaseNotes(versionID: versionID, credential: credential)
    }

    // MARK: - Issue #217 — Update Release Notes

    public func updateReleaseNotes(localizationID: String, whatsNew: String) async throws {
        let credential = try await loadCredentialOrThrow()
        try await apiClient.updateReleaseNotes(localizationID: localizationID, whatsNew: whatsNew, credential: credential)
    }

    // MARK: - Issue #208 — Fetch Metadata Status

    public func fetchMetadataStatus(appID: String) async throws -> ASCMetadataStatus {
        let credential = try await loadCredentialOrThrow()
        let fields = try await apiClient.fetchAppInfo(appID: appID, credential: credential)
        lastSuccessfulFetch = Date()
        return ASCMetadataStatus(fields: fields)
    }

    // MARK: - Issue #210 — Fetch Localization Status

    public func fetchLocalizationStatus(versionID: String) async throws -> ASCLocalizationStatus {
        let credential = try await loadCredentialOrThrow()
        let locales = try await apiClient.fetchLocalizations(versionID: versionID, credential: credential)
        return ASCLocalizationStatus(locales: locales)
    }

    // MARK: - Issue #219 — Detect Missing Metadata

    public func detectMissingMetadata(appID: String) async throws -> [ASCMetadataField] {
        logger.info("Detecting missing ASC metadata for app \(appID)", category: "asc")
        let status = try await fetchMetadataStatus(appID: appID)
        let missing = status.fields.filter { !$0.isComplete }
        if !missing.isEmpty {
            logger.warning("Found \(missing.count) missing metadata fields", category: "asc")
        }
        return missing
    }

    // MARK: - Issue #221 — Detect Missing Localizations

    public func detectMissingLocalizations(versionID: String, threshold: Double = 1.0) async throws -> [ASCLocaleCompleteness] {
        logger.info("Detecting missing ASC localizations for version \(versionID)", category: "asc")
        let status = try await fetchLocalizationStatus(versionID: versionID)
        let incomplete = status.locales.filter { $0.completeness < threshold }
        if !incomplete.isEmpty {
            logger.warning("Found \(incomplete.count) locales below \(Int(threshold * 100))% completeness", category: "asc")
        }
        return incomplete
    }

    // MARK: - Issue #223 — Map ASC Status into Release Cockpit

    public func mapReadinessToRelease(appID: String, versionID: String, releaseID: UUID) async throws {
        logger.info("Mapping ASC readiness to release \(releaseID.uuidString)", category: "asc")

        let metadata = try await fetchMetadataStatus(appID: appID)
        let localization = try await fetchLocalizationStatus(versionID: versionID)
        let builds = try await fetchBuilds(appID: appID)

        let latestBuild = builds.first
        let hasBuild = latestBuild?.processingState == .valid
        let metadataComplete = metadata.completeness >= 1.0
        let localizationComplete = localization.overallCompleteness >= 1.0

        // Calculate ASC contribution to readiness (0–30 points of total 100)
        var ascReadiness: Double = 0
        if hasBuild { ascReadiness += 10 }
        ascReadiness += metadata.completeness * 10
        ascReadiness += localization.overallCompleteness * 10

        var release = try await releaseRepository.load(id: releaseID)
        // Update linked build ref
        if let build = latestBuild {
            release.linkedASCBuildRef = "\(appID)/\(build.version)/\(build.buildNumber)"
        }

        // Adjust readiness score — ASC contributes up to 30% of total
        let nonASCScore = release.readinessScore * 0.7
        release.readinessScore = min(100, nonASCScore + ascReadiness)
        release.updatedAt = Date()

        // Add blockers for missing metadata/localizations
        if !metadataComplete {
            let missingCount = metadata.fields.filter { !$0.isComplete }.count
            let blockerTitle = "Missing \(missingCount) ASC metadata field\(missingCount == 1 ? "" : "s")"
            if !release.blockers.contains(where: { $0.title == blockerTitle }) {
                release.blockers.append(CodalonReleaseBlocker(title: blockerTitle, severity: .warning))
                release.blockerCount = release.blockers.count
            }
        }

        if !localizationComplete {
            let incompleteCount = localization.locales.filter { $0.completeness < 1.0 }.count
            let blockerTitle = "\(incompleteCount) locale\(incompleteCount == 1 ? "" : "s") with incomplete localization"
            if !release.blockers.contains(where: { $0.title == blockerTitle }) {
                release.blockers.append(CodalonReleaseBlocker(title: blockerTitle, severity: .info))
                release.blockerCount = release.blockers.count
            }
        }

        try await releaseRepository.save(release)
        logger.success("ASC readiness mapped: build=\(hasBuild), metadata=\(Int(metadata.completeness * 100))%, l10n=\(Int(localization.overallCompleteness * 100))%", category: "asc")
    }

    // MARK: - Private

    private func loadCredentialOrThrow() async throws -> ASCCredential {
        guard await credentialService.exists() else {
            throw ASCServiceError.notAuthenticated
        }
        return try await credentialService.load()
    }

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}
