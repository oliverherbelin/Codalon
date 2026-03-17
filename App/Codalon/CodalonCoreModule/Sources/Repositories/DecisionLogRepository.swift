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
        let predicate = StoragePredicate.where(field: "projectID", .equals, value: projectID.uuidString)
        return try await storage.query(CodalonDecisionLogEntry.self, predicate: predicate)
    }

    public func fetchByCategory(
        _ category: CodalonDecisionCategory,
        projectID: UUID
    ) async throws -> [CodalonDecisionLogEntry] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "category", .equals, value: category.rawValue))
        return try await storage.query(CodalonDecisionLogEntry.self, predicate: predicate)
    }

    public func fetchByRelatedObject(_ objectID: UUID) async throws -> [CodalonDecisionLogEntry] {
        let predicate = StoragePredicate.where(field: "relatedObjectID", .equals, value: objectID.uuidString)
        return try await storage.query(CodalonDecisionLogEntry.self, predicate: predicate)
    }
}
