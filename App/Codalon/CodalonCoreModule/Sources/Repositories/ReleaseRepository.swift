// Issue #110 — Concrete ReleaseRepository

import Foundation
import HelaiaStorage

public actor ReleaseRepository: ReleaseRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ release: CodalonRelease) async throws {
        try await storage.save(release)
    }

    public func load(id: UUID) async throws -> CodalonRelease {
        try await storage.load(CodalonRelease.self, id: id)
    }

    public func loadAll() async throws -> [CodalonRelease] {
        try await storage.loadAll(CodalonRelease.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonRelease.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonRelease.self)
        return all.filter { $0.projectID == projectID }
    }

    public func fetchActive(projectID: UUID) async throws -> CodalonRelease? {
        let releases = try await fetchByProject(projectID)
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]
        return releases.first { !terminalStatuses.contains($0.status) }
    }

    public func fetchByStatus(_ status: CodalonReleaseStatus, projectID: UUID) async throws -> [CodalonRelease] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.status == status }
    }
}
