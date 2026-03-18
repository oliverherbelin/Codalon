// Issue #121 — Release service layer

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol ReleaseServiceProtocol: Sendable {
    func save(_ release: CodalonRelease) async throws
    func load(id: UUID) async throws -> CodalonRelease
    func delete(id: UUID) async throws
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease]
    func fetchActive(projectID: UUID) async throws -> CodalonRelease?
}

// MARK: - Implementation

public actor ReleaseService: ReleaseServiceProtocol {

    private let repository: any ReleaseRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        repository: any ReleaseRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.repository = repository
        self.logger = logger
    }

    public func save(_ release: CodalonRelease) async throws {
        logger.info("Saving release \(release.version) (build \(release.buildNumber))", category: "release")
        do {
            try await repository.save(release)
            logger.success("Release \(release.version) saved", category: "release")
        } catch {
            logger.error("Failed to save release: \(error.localizedDescription)", category: "release")
            throw error
        }
    }

    public func load(id: UUID) async throws -> CodalonRelease {
        try await repository.load(id: id)
    }

    public func delete(id: UUID) async throws {
        logger.info("Deleting release \(id.uuidString)", category: "release")
        try await repository.delete(id: id)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        try await repository.fetchByProject(projectID)
    }

    public func fetchActive(projectID: UUID) async throws -> CodalonRelease? {
        try await repository.fetchActive(projectID: projectID)
    }
}
