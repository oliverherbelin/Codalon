// Issue #110 — Concrete TaskRepository

import Foundation
import HelaiaStorage

public actor TaskRepository: TaskRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ task: CodalonTask) async throws {
        try await storage.save(task)
    }

    public func load(id: UUID) async throws -> CodalonTask {
        try await storage.load(CodalonTask.self, id: id)
    }

    public func loadAll() async throws -> [CodalonTask] {
        try await storage.loadAll(CodalonTask.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonTask.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] {
        let predicate = StoragePredicate.where(field: "projectID", .equals, value: projectID.uuidString)
        return try await storage.query(CodalonTask.self, predicate: predicate)
    }

    public func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] {
        let predicate = StoragePredicate.where(field: "milestoneID", .equals, value: milestoneID.uuidString)
        return try await storage.query(CodalonTask.self, predicate: predicate)
    }

    public func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] {
        let predicate = StoragePredicate.where(field: "epicID", .equals, value: epicID.uuidString)
        return try await storage.query(CodalonTask.self, predicate: predicate)
    }

    public func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "status", .equals, value: status.rawValue))
        return try await storage.query(CodalonTask.self, predicate: predicate)
    }

    public func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "priority", .equals, value: priority.rawValue))
        return try await storage.query(CodalonTask.self, predicate: predicate)
    }

    public func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await fetchByProject(projectID)
        return all.filter(\.isBlocked)
    }

    public func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await fetchByProject(projectID)
        return all.filter(\.isLaunchCritical)
    }
}
