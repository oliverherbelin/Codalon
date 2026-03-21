// Issue #110 — Concrete AlertRepository

import Foundation
import HelaiaStorage

public actor AlertRepository: AlertRepositoryProtocol {

    private let storage: any StorageServiceProtocol

    public init(storage: any StorageServiceProtocol) {
        self.storage = storage
    }

    public func save(_ alert: CodalonAlert) async throws {
        try await storage.save(alert)
    }

    public func load(id: UUID) async throws -> CodalonAlert {
        try await storage.load(CodalonAlert.self, id: id)
    }

    public func loadAll() async throws -> [CodalonAlert] {
        try await storage.loadAll(CodalonAlert.self)
    }

    public func delete(id: UUID) async throws {
        try await storage.delete(id: id, type: CodalonAlert.self)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert] {
        // StoragePredicate field names map to SQL columns, not JSON keys.
        // helaia_records stores data as a JSON blob — filter in memory instead.
        let all = try await storage.loadAll(CodalonAlert.self)
        return all.filter { $0.projectID == projectID }
    }

    public func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.readState == .unread }
    }

    public func fetchByCategory(
        _ category: CodalonAlertCategory,
        projectID: UUID
    ) async throws -> [CodalonAlert] {
        let all = try await fetchByProject(projectID)
        return all.filter { $0.category == category }
    }

    public func markRead(id: UUID) async throws {
        var alert = try await load(id: id)
        alert.readState = .read
        alert.updatedAt = Date()
        try await storage.save(alert)
    }

    public func dismiss(id: UUID) async throws {
        var alert = try await load(id: id)
        alert.readState = .dismissed
        alert.updatedAt = Date()
        try await storage.save(alert)
    }
}
