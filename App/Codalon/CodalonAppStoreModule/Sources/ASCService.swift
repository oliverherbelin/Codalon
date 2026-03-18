// Issues #179, #181, #183, #185, #189, #191, #193, #195 — ASC service

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
}

// MARK: - Implementation

public actor ASCService: ASCServiceProtocol {

    private let credentialService: any ASCCredentialServiceProtocol
    private let apiClient: any ASCAPIClientProtocol
    private let projectRepository: any ProjectRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    private var lastSuccessfulFetch: Date?
    private var cachedLinkedApps: [UUID: ASCApp] = [:]

    public init(
        credentialService: any ASCCredentialServiceProtocol,
        apiClient: any ASCAPIClientProtocol,
        projectRepository: any ProjectRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.credentialService = credentialService
        self.apiClient = apiClient
        self.projectRepository = projectRepository
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
