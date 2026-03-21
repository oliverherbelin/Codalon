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
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonInsight.self)
        return all.filter { $0.projectID == projectID }
    }

    public func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.severity == severity }
    }

    public func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.source == source }
    }
}
