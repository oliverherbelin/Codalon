// Issue #104 — MilestoneRepositoryProtocol

import Foundation

public protocol MilestoneRepositoryProtocol: Sendable {

    func save(_ milestone: CodalonMilestone) async throws
    func load(id: UUID) async throws -> CodalonMilestone
    func loadAll() async throws -> [CodalonMilestone]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone]
    func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone]
    func fetchOverdue(projectID: UUID) async throws -> [CodalonMilestone]
}
