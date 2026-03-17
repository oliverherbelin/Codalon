// Issue #110 — Concrete MilestoneRepository

import Foundation
import HelaiaStorage

public actor MilestoneRepository: MilestoneRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ milestone: CodalonMilestone) async throws {
        try await storage.save(milestone)
    }

    public func load(id: UUID) async throws -> CodalonMilestone {
        try await storage.load(CodalonMilestone.self, id: id)
    }

    public func loadAll() async throws -> [CodalonMilestone] {
        try await storage.loadAll(CodalonMilestone.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonMilestone.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        let predicate = StoragePredicate.where(field: "projectID", .equals, value: projectID.uuidString)
        return try await storage.query(CodalonMilestone.self, predicate: predicate)
    }

    public func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "status", .equals, value: status.rawValue))
        return try await storage.query(CodalonMilestone.self, predicate: predicate)
    }

    public func fetchOverdue(projectID: UUID) async throws -> [CodalonMilestone] {
        let all = try await fetchByProject(projectID)
        let now = Date()
        return all.filter { milestone in
            guard let dueDate = milestone.dueDate else { return false }
            return dueDate < now
                && milestone.status != .completed
                && milestone.status != .cancelled
        }
    }
}
