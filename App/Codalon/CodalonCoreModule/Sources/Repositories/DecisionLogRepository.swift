// Issue #110 — Concrete DecisionLogRepository

import Foundation
import HelaiaStorage

public actor DecisionLogRepository: DecisionLogRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ entry: CodalonDecisionLogEntry) async throws {
        try await storage.save(entry)
    }

    public func load(id: UUID) async throws -> CodalonDecisionLogEntry {
        try await storage.load(CodalonDecisionLogEntry.self, id: id)
    }

    public func loadAll() async throws -> [CodalonDecisionLogEntry] {
        try await storage.loadAll(CodalonDecisionLogEntry.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonDecisionLogEntry.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonDecisionLogEntry] {
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonDecisionLogEntry.self)
        return all.filter { $0.projectID == projectID }
    }

    public func fetchByCategory(
        _ category: CodalonDecisionCategory,
        projectID: UUID
    ) async throws -> [CodalonDecisionLogEntry] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.category == category }
    }

    public func fetchByRelatedObject(_ objectID: UUID) async throws -> [CodalonDecisionLogEntry] {
        let all = try await storage.loadAll(CodalonDecisionLogEntry.self)
        return all.filter { $0.relatedObjectID == objectID }
    }
}
