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
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonTask.self)
        return all.filter { $0.projectID == projectID }
    }

    public func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] {
        let all = try await storage.loadAll(CodalonTask.self)
        return all.filter { $0.milestoneID == milestoneID }
    }

    public func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] {
        let all = try await storage.loadAll(CodalonTask.self)
        return all.filter { $0.epicID == epicID }
    }

    public func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.status == status }
    }

    public func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.priority == priority }
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
