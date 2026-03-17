// Issue #110 — Concrete ProjectRepository

import Foundation
import HelaiaStorage

public actor ProjectRepository: ProjectRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ project: CodalonProject) async throws {
        try await storage.save(project)
    }

    public func load(id: UUID) async throws -> CodalonProject {
        try await storage.load(CodalonProject.self, id: id)
    }

    public func loadAll() async throws -> [CodalonProject] {
        try await storage.loadAll(CodalonProject.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonProject.self)
    }

    public func exists(id: UUID) async throws -> Bool {
        await storage.exists(id: id, type: CodalonProject.self)
    }
}
