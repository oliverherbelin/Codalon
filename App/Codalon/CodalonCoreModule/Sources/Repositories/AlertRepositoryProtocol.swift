// Issue #108 — AlertRepositoryProtocol

import Foundation

public protocol AlertRepositoryProtocol: Sendable {

    func save(_ alert: CodalonAlert) async throws
    func load(id: UUID) async throws -> CodalonAlert
    func loadAll() async throws -> [CodalonAlert]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert]
    func fetchUnread(projectID: UUID) async throws -> [CodalonAlert]
    func fetchByCategory(_ category: CodalonAlertCategory, projectID: UUID) async throws -> [CodalonAlert]
    func markRead(id: UUID) async throws
    func dismiss(id: UUID) async throws
}
