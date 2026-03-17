// Issue #106 — ReleaseRepositoryProtocol

import Foundation

public protocol ReleaseRepositoryProtocol: Sendable {

    func save(_ release: CodalonRelease) async throws
    func load(id: UUID) async throws -> CodalonRelease
    func loadAll() async throws -> [CodalonRelease]
    func delete(id: UUID) async throws

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease]
    func fetchActive(projectID: UUID) async throws -> CodalonRelease?
    func fetchByStatus(_ status: CodalonReleaseStatus, projectID: UUID) async throws -> [CodalonRelease]
}
