// Issue #109 — DecisionLogRepositoryProtocol

import Foundation

public protocol DecisionLogRepositoryProtocol: Sendable {

    func save(_ entry: CodalonDecisionLogEntry) async throws
    func load(id: UUID) async throws -> CodalonDecisionLogEntry
    func loadAll() async throws -> [CodalonDecisionLogEntry]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonDecisionLogEntry]
    func fetchByCategory(_ category: CodalonDecisionCategory, projectID: UUID) async throws -> [CodalonDecisionLogEntry]
    func fetchByRelatedObject(_ objectID: UUID) async throws -> [CodalonDecisionLogEntry]
}
