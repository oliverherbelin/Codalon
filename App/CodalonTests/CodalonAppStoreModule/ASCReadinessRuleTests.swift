// Issue #226 — ASC readiness rule tests (missing metadata and localization detection)

import Foundation
import Testing
import HelaiaLogger
@testable import Codalon

// MARK: - Mock ASC API Client for Rule Tests

private actor MockRuleASCAPIClient: ASCAPIClientProtocol {
    var metadataFields: [ASCMetadataField] = []
    var localizations: [ASCLocaleCompleteness] = []
    var builds: [ASCBuild] = []

    func fetchApps(credential: ASCCredential) async throws -> [ASCApp] { [] }
    func validateCredentials(_ credential: ASCCredential) async throws -> Bool { true }
    func fetchVersions(appID: String, credential: ASCCredential) async throws -> [ASCVersion] { [] }

    func fetchBuilds(appID: String, credential: ASCCredential) async throws -> [ASCBuild] {
        builds
    }

    func fetchTestFlightBuilds(appID: String, credential: ASCCredential) async throws -> [ASCTestFlightBuild] { [] }
    func fetchReleaseNotes(versionID: String, credential: ASCCredential) async throws -> [ASCReleaseNotes] { [] }
    func updateReleaseNotes(localizationID: String, whatsNew: String, credential: ASCCredential) async throws {}

    func fetchAppInfo(appID: String, credential: ASCCredential) async throws -> [ASCMetadataField] {
        metadataFields
    }

    func fetchLocalizations(versionID: String, credential: ASCCredential) async throws -> [ASCLocaleCompleteness] {
        localizations
    }
}

// MARK: - Mock Credential Service for Rule Tests

private actor MockRuleCredentialService: ASCCredentialServiceProtocol {
    var credential: ASCCredential? = ASCCredential(issuerID: "test", keyID: "test", privateKey: "test")

    func save(_ credential: ASCCredential) async throws { self.credential = credential }
    func load() async throws -> ASCCredential {
        guard let credential else { throw ASCServiceError.notAuthenticated }
        return credential
    }
    func delete() async throws { credential = nil }
    func exists() async -> Bool { credential != nil }
}

// MARK: - Mock Project Repository for Rule Tests

private actor MockRuleProjectRepository: ProjectRepositoryProtocol {
    var projects: [CodalonProject] = []

    func save(_ project: CodalonProject) async throws {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
    }
    func load(id: UUID) async throws -> CodalonProject {
        guard let p = projects.first(where: { $0.id == id }) else { throw TestError.notFound }
        return p
    }
    func loadAll() async throws -> [CodalonProject] { projects }
    func delete(id: UUID) async throws { projects.removeAll { $0.id == id } }
    func exists(id: UUID) async throws -> Bool { projects.contains { $0.id == id } }
}

// MARK: - Mock Release Repository for Rule Tests

private actor MockRuleReleaseRepository: ReleaseRepositoryProtocol {
    var releases: [CodalonRelease] = []

    func save(_ release: CodalonRelease) async throws {
        if let index = releases.firstIndex(where: { $0.id == release.id }) {
            releases[index] = release
        } else {
            releases.append(release)
        }
    }
    func load(id: UUID) async throws -> CodalonRelease {
        guard let r = releases.first(where: { $0.id == id }) else { throw TestError.notFound }
        return r
    }
    func loadAll() async throws -> [CodalonRelease] { releases }
    func delete(id: UUID) async throws { releases.removeAll { $0.id == id } }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        releases.filter { $0.projectID == projectID }
    }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? {
        let terminal: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]
        return releases.first { $0.projectID == projectID && !terminal.contains($0.status) }
    }
    func fetchByStatus(_ status: CodalonReleaseStatus, projectID: UUID) async throws -> [CodalonRelease] {
        releases.filter { $0.projectID == projectID && $0.status == status }
    }
}

private enum TestError: Error { case notFound }

// MARK: - Tests

@Suite("ASCReadinessRules")
@MainActor
struct ASCReadinessRuleTests {

    let projectID = UUID()
    let releaseID = UUID()

    // MARK: - #219 — Missing Metadata Detection

    @Test("detects missing metadata fields")
    func detectsMissingMetadata() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setMetadataFields([
            ASCMetadataField(id: "name", label: "App Name", isComplete: true),
            ASCMetadataField(id: "subtitle", label: "Subtitle", isComplete: false),
            ASCMetadataField(id: "description", label: "Description", isComplete: true),
            ASCMetadataField(id: "keywords", label: "Keywords", isComplete: false),
        ])

        let service = await buildService(apiClient: apiClient)
        let missing = try await service.detectMissingMetadata(appID: "app1")

        #expect(missing.count == 2)
        #expect(missing.contains { $0.id == "subtitle" })
        #expect(missing.contains { $0.id == "keywords" })
    }

    @Test("returns empty when all metadata complete")
    func allMetadataComplete() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setMetadataFields([
            ASCMetadataField(id: "name", label: "App Name", isComplete: true),
            ASCMetadataField(id: "description", label: "Description", isComplete: true),
        ])

        let service = await buildService(apiClient: apiClient)
        let missing = try await service.detectMissingMetadata(appID: "app1")

        #expect(missing.isEmpty)
    }

    // MARK: - #221 — Missing Localization Detection

    @Test("detects incomplete localizations below threshold")
    func detectsIncompleteLocalizations() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setLocalizations([
            ASCLocaleCompleteness(locale: "en-US", completeness: 1.0),
            ASCLocaleCompleteness(locale: "de-DE", completeness: 0.6, missingFields: ["keywords", "whatsNew"]),
            ASCLocaleCompleteness(locale: "fr-FR", completeness: 0.4, missingFields: ["description", "keywords", "whatsNew"]),
        ])

        let service = await buildService(apiClient: apiClient)
        let incomplete = try await service.detectMissingLocalizations(versionID: "v1", threshold: 1.0)

        #expect(incomplete.count == 2)
        #expect(incomplete.contains { $0.locale == "de-DE" })
        #expect(incomplete.contains { $0.locale == "fr-FR" })
    }

    @Test("returns empty when all locales complete")
    func allLocalesComplete() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setLocalizations([
            ASCLocaleCompleteness(locale: "en-US", completeness: 1.0),
            ASCLocaleCompleteness(locale: "de-DE", completeness: 1.0),
        ])

        let service = await buildService(apiClient: apiClient)
        let incomplete = try await service.detectMissingLocalizations(versionID: "v1", threshold: 1.0)

        #expect(incomplete.isEmpty)
    }

    // MARK: - #223 — Map Readiness to Release

    @Test("maps ASC status into release readiness score")
    func mapsReadinessToRelease() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setBuilds([
            ASCBuild(id: "b1", version: "1.0", buildNumber: "42", uploadedDate: Date(), processingState: .valid),
        ])
        await apiClient.setMetadataFields([
            ASCMetadataField(id: "name", label: "Name", isComplete: true),
            ASCMetadataField(id: "desc", label: "Desc", isComplete: true),
        ])
        await apiClient.setLocalizations([
            ASCLocaleCompleteness(locale: "en-US", completeness: 1.0),
        ])

        let releaseRepo = MockRuleReleaseRepository()
        let release = CodalonRelease(
            id: releaseID,
            projectID: projectID,
            version: "1.0",
            status: .drafting,
            readinessScore: 50
        )
        try await releaseRepo.save(release)

        let service = await buildService(apiClient: apiClient, releaseRepo: releaseRepo)
        try await service.mapReadinessToRelease(appID: "app1", versionID: "v1", releaseID: releaseID)

        let updated = try await releaseRepo.load(id: releaseID)
        // ASC contributes up to 30: 10 (build) + 10 (metadata 100%) + 10 (l10n 100%) = 30
        // Non-ASC: 50 * 0.7 = 35
        // Total: 35 + 30 = 65
        #expect(updated.readinessScore > 60 && updated.readinessScore <= 70)
        #expect(updated.linkedASCBuildRef != nil)
    }

    @Test("adds blockers for missing metadata")
    func addsBlockersForMissingMetadata() async throws {
        let apiClient = MockRuleASCAPIClient()
        await apiClient.setBuilds([
            ASCBuild(id: "b1", version: "1.0", buildNumber: "42", uploadedDate: Date(), processingState: .valid),
        ])
        await apiClient.setMetadataFields([
            ASCMetadataField(id: "name", label: "Name", isComplete: true),
            ASCMetadataField(id: "desc", label: "Desc", isComplete: false),
            ASCMetadataField(id: "url", label: "URL", isComplete: false),
        ])
        await apiClient.setLocalizations([
            ASCLocaleCompleteness(locale: "en-US", completeness: 0.5, missingFields: ["keywords"]),
        ])

        let releaseRepo = MockRuleReleaseRepository()
        let release = CodalonRelease(
            id: releaseID, projectID: projectID,
            version: "1.0", status: .drafting, readinessScore: 40
        )
        try await releaseRepo.save(release)

        let service = await buildService(apiClient: apiClient, releaseRepo: releaseRepo)
        try await service.mapReadinessToRelease(appID: "app1", versionID: "v1", releaseID: releaseID)

        let updated = try await releaseRepo.load(id: releaseID)
        #expect(updated.blockers.count >= 2)
        #expect(updated.blockers.contains { $0.title.contains("metadata") })
        #expect(updated.blockers.contains { $0.title.contains("localization") })
    }

    // MARK: - Helper

    private func buildService(
        apiClient: MockRuleASCAPIClient,
        releaseRepo: MockRuleReleaseRepository? = nil
    ) async -> ASCService {
        let credService = MockRuleCredentialService()
        let projectRepo = MockRuleProjectRepository()
        let project = CodalonProject(id: projectID, name: "Test", slug: "test")
        try? await projectRepo.save(project)

        let rRepo = releaseRepo ?? MockRuleReleaseRepository()

        return await MainActor.run {
            ASCService(
                credentialService: credService,
                apiClient: apiClient,
                projectRepository: projectRepo,
                releaseRepository: rRepo,
                logger: HelaiaMockLogger()
            )
        }
    }
}

// MARK: - Mock Setters

private extension MockRuleASCAPIClient {
    func setMetadataFields(_ fields: [ASCMetadataField]) { metadataFields = fields }
    func setLocalizations(_ locales: [ASCLocaleCompleteness]) { localizations = locales }
    func setBuilds(_ b: [ASCBuild]) { builds = b }
}
