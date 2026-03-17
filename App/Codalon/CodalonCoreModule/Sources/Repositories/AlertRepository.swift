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
        let predicate = StoragePredicate.where(field: "projectID", .equals, value: projectID.uuidString)
        return try await storage.query(CodalonAlert.self, predicate: predicate)
    }

    public func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "readState", .equals, value: CodalonAlertReadState.unread.rawValue))
        return try await storage.query(CodalonAlert.self, predicate: predicate)
    }

    public func fetchByCategory(
        _ category: CodalonAlertCategory,
        projectID: UUID
    ) async throws -> [CodalonAlert] {
        let predicate = StoragePredicate
            .where(field: "projectID", .equals, value: projectID.uuidString)
            .and(.where(field: "category", .equals, value: category.rawValue))
        return try await storage.query(CodalonAlert.self, predicate: predicate)
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
