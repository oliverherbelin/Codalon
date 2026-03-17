// Issue #103 — ProjectRepositoryProtocol

import Foundation

public protocol ProjectRepositoryProtocol: Sendable {

    func save(_ project: CodalonProject) async throws
    func load(id: UUID) async throws -> CodalonProject
    func loadAll() async throws -> [CodalonProject]
    func delete(id: UUID) async throws
    func exists(id: UUID) async throws -> Bool
}
