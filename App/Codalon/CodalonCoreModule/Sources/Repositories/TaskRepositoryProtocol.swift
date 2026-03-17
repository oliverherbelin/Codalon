// Issue #105 — TaskRepositoryProtocol

import Foundation

public protocol TaskRepositoryProtocol: Sendable {

    func save(_ task: CodalonTask) async throws
    func load(id: UUID) async throws -> CodalonTask
    func loadAll() async throws -> [CodalonTask]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask]
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask]
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask]
    func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask]
    func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask]
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask]
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask]
}
