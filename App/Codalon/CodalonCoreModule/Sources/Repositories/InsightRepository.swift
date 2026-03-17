// Issue #110 — Concrete InsightRepository

import Foundation
import HelaiaStorage

public actor InsightRepository: InsightRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ insight: CodalonInsight) async throws {
        try await storage.save(insight)
    }

    public func load(id: UUID) async throws -> CodalonInsight {
        try await storage.load(CodalonInsight.self, id: id)
    }

    public func loadAll() async throws -> [CodalonInsight] {
        try await storage.loadAll(CodalonInsight.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonInsight.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight] {
        let predicate = StoragePredicate.where(field: "projectID", .equals, value: projectID.uuidString)
        return try await storage.query(CodalonInsight.self, predicate: predicate)
    }

    public func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "severity", .equals, value: severity.rawValue))
        return try await storage.query(CodalonInsight.self, predicate: predicate)
    }

    public func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "source", .equals, value: source.rawValue))
        return try await storage.query(CodalonInsight.self, predicate: predicate)
    }
}
