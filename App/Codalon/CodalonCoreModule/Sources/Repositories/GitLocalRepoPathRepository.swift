// Issue #275 — GitLocalRepoPath persistence

import Foundation
import HelaiaStorage

// MARK: - Protocol

public protocol GitLocalRepoPathRepositoryProtocol: Sendable {
    func save(_ path: GitLocalRepoPath) async throws
    func load(id: UUID) async throws -> GitLocalRepoPath
    func fetchByProject(_ projectID: UUID) async throws -> GitLocalRepoPath?
    func delete(id: UUID) async throws
}

// MARK: - Implementation

public actor GitLocalRepoPathRepository: GitLocalRepoPathRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ path: GitLocalRepoPath) async throws {
        try await storage.save(path)
    }

    public func load(id: UUID) async throws -> GitLocalRepoPath {
        try await storage.load(GitLocalRepoPath.self, id: id)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> GitLocalRepoPath? {
        let all = try await storage.loadAll(GitLocalRepoPath.self)
        return all.first { $0.projectID == projectID }
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: GitLocalRepoPath.self)
    }
}
