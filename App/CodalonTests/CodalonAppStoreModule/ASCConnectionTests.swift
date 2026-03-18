// Issue #197 — ASC connection tests

import Foundation
import Testing
import HelaiaLogger
@testable import Codalon

// MARK: - Mock Credential Service

private actor MockASCCredentialService: ASCCredentialServiceProtocol {
    var stored: ASCCredential?
    var saveCount = 0
    var deleteCount = 0

    func save(_ credential: ASCCredential) async throws {
        stored = credential
        saveCount += 1
    }

    func load() async throws -> ASCCredential {
        guard let stored else {
            throw ASCServiceError.notAuthenticated
        }
        return stored
    }

    func delete() async throws {
        stored = nil
        deleteCount += 1
    }

    func exists() async -> Bool {
        stored != nil
    }
}

// MARK: - Mock API Client

private actor MockASCAPIClient: ASCAPIClientProtocol {
    var shouldValidate = true
    var apps: [ASCApp] = []

    func fetchApps(credential: ASCCredential) async throws -> [ASCApp] {
        guard shouldValidate else { throw ASCServiceError.credentialsExpired }
        return apps
    }

    func validateCredentials(_ credential: ASCCredential) async throws -> Bool {
        shouldValidate
    }
}

// MARK: - Mock Project Repository

private actor MockProjectRepository: ProjectRepositoryProtocol {
    var projects: [CodalonProject] = []

    func save(_ project: CodalonProject) async throws {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
    }

    func load(id: UUID) async throws -> CodalonProject {
        guard let project = projects.first(where: { $0.id == id }) else {
            throw TestError.notFound
        }
        return project
    }

    func loadAll() async throws -> [CodalonProject] { projects }

    func delete(id: UUID) async throws {
        projects.removeAll { $0.id == id }
    }

    func exists(id: UUID) async throws -> Bool {
        projects.contains { $0.id == id }
    }
}

private enum TestError: Error {
    case notFound
}

// MARK: - Tests

@Suite("ASCConnectionTests")
@MainActor
struct ASCConnectionTests {

    let projectID = UUID()

    // MARK: - #181 — Credential Storage

    @Test("stores and retrieves ASC credentials")
    func credentialStorage() async throws {
        let credService = MockASCCredentialService()
        let credential = ASCCredential(
            issuerID: "test-issuer",
            keyID: "TEST123",
            privateKey: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----"
        )

        try await credService.save(credential)
        let exists = await credService.exists()
        #expect(exists == true)

        let loaded = try await credService.load()
        #expect(loaded.issuerID == "test-issuer")
        #expect(loaded.keyID == "TEST123")
    }

    @Test("credential deletion clears stored data")
    func credentialDeletion() async throws {
        let credService = MockASCCredentialService()
        let credential = ASCCredential(
            issuerID: "test-issuer",
            keyID: "TEST123",
            privateKey: "fake-key"
        )

        try await credService.save(credential)
        try await credService.delete()

        let exists = await credService.exists()
        #expect(exists == false)
    }

    // MARK: - #183 — Authentication

    @Test("authenticate validates and stores credentials")
    func authenticateSuccess() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let credential = ASCCredential(
            issuerID: "issuer-1",
            keyID: "KEY1",
            privateKey: "key-data"
        )

        try await service.authenticate(credential: credential)

        let authenticated = await service.isAuthenticated()
        #expect(authenticated == true)

        let saveCount = await credService.saveCount
        #expect(saveCount == 1)
    }

    @Test("authenticate rejects invalid credentials")
    func authenticateFailure() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        await apiClient.setShouldValidate(false)
        let projectRepo = MockProjectRepository()

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let credential = ASCCredential(
            issuerID: "bad-issuer",
            keyID: "BADKEY",
            privateKey: "bad-data"
        )

        do {
            try await service.authenticate(credential: credential)
            Issue.record("Expected authentication to throw")
        } catch {
            #expect(error is ASCServiceError)
        }
    }

    // MARK: - #189 — Link App

    @Test("links ASC app to project")
    func linkApp() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        let project = CodalonProject(id: projectID, name: "Test Project", slug: "test")
        try await projectRepo.save(project)

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let app = ASCApp(id: "1", name: "MyApp", bundleID: "com.test.myapp", platform: .macOS)
        try await service.linkApp(app, projectID: projectID)

        let updated = try await projectRepo.load(id: projectID)
        #expect(updated.linkedASCApp == "com.test.myapp")
    }

    // MARK: - #193 — Disconnect

    @Test("disconnect removes credentials and unlinks app")
    func disconnectFlow() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        // Set up connected state
        let credential = ASCCredential(issuerID: "issuer", keyID: "KEY", privateKey: "data")
        try await credService.save(credential)

        var project = CodalonProject(id: projectID, name: "Test Project", slug: "test")
        project.linkedASCApp = "com.test.myapp"
        try await projectRepo.save(project)

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        try await service.disconnect(projectID: projectID)

        let authenticated = await service.isAuthenticated()
        #expect(authenticated == false)

        let updated = try await projectRepo.load(id: projectID)
        #expect(updated.linkedASCApp == nil)
    }

    // MARK: - #191 — Validate / Reconnect

    @Test("validates connection status when credentials expired")
    func validateExpired() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        // Store credentials but make validation fail
        let credential = ASCCredential(issuerID: "issuer", keyID: "KEY", privateKey: "data")
        try await credService.save(credential)
        await apiClient.setShouldValidate(false)

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let status = await service.validateCredentials()
        #expect(status == .credentialsExpired)
    }

    @Test("validates as not connected when no credentials")
    func validateNotConnected() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let status = await service.validateCredentials()
        #expect(status == .notConnected)
    }

    // MARK: - #195 — Diagnostics

    @Test("diagnostics returns connection state")
    func diagnosticsState() async throws {
        let credService = MockASCCredentialService()
        let apiClient = MockASCAPIClient()
        let projectRepo = MockProjectRepository()

        let project = CodalonProject(id: projectID, name: "Test", slug: "test")
        try await projectRepo.save(project)

        let service = await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                logger: HelaiaMockLogger()
            )
        }

        let diag = try await service.diagnostics(projectID: projectID)
        #expect(diag.status == .notConnected)
        #expect(diag.linkedAppName == nil)
    }
}

// MARK: - Helper Extension

private extension MockASCAPIClient {
    func setShouldValidate(_ value: Bool) {
        shouldValidate = value
    }
}
