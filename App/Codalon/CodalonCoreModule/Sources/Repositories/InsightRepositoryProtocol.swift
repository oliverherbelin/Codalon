// Issue #107 — InsightRepositoryProtocol

import Foundation

public protocol InsightRepositoryProtocol: Sendable {

    func save(_ insight: CodalonInsight) async throws
    func load(id: UUID) async throws -> CodalonInsight
    func loadAll() async throws -> [CodalonInsight]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight]
    func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight]
    func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight]
}
