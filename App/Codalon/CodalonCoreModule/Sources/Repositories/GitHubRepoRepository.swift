// Issue #71 — Concrete GitHubRepoRepository

import Foundation
import HelaiaStorage

public actor GitHubRepoRepository: GitHubRepoRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ repo: CodalonGitHubRepo) async throws {
        try await storage.save(repo)
    }

    public func load(id: UUID) async throws -> CodalonGitHubRepo {
        try await storage.load(CodalonGitHubRepo.self, id: id)
    }

    public func loadAll() async throws -> [CodalonGitHubRepo] {
        try await storage.loadAll(CodalonGitHubRepo.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonGitHubRepo.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonGitHubRepo] {
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonGitHubRepo.self)
        return all.filter { $0.projectID == projectID }
    }
}