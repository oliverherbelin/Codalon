// Issue #71 — GitHubRepoRepositoryProtocol

import Foundation

public protocol GitHubRepoRepositoryProtocol: Sendable {
    func save(_ repo: CodalonGitHubRepo) async throws
    func load(id: UUID) async throws -> CodalonGitHubRepo
    func loadAll() async throws -> [CodalonGitHubRepo]
    func delete(id: UUID) async throws
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonGitHubRepo]
}