// Issues #111, #113, #114, #115 — Project CRUD service

import Foundation
import HelaiaEngine

// MARK: - Protocol

public protocol ProjectServiceProtocol: Sendable {
    func create(_ project: CodalonProject) async throws
    func update(_ project: CodalonProject) async throws
    func archive(id: UUID) async throws
    func delete(id: UUID) async throws
    func load(id: UUID) async throws -> CodalonProject
    func loadAll() async throws -> [CodalonProject]
    func loadActive() async throws -> [CodalonProject]
}

// MARK: - Implementation

public actor ProjectService: ProjectServiceProtocol {

    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func create(_ project: CodalonProject) async throws {
        try await repository.save(project)
        await publish(ProjectCreatedEvent(projectID: project.id, name: project.name))
    }

    public func update(_ project: CodalonProject) async throws {
        var updated = project
        updated.updatedAt = Date()
        try await repository.save(updated)
        await publish(ProjectUpdatedEvent(projectID: updated.id))
    }

    public func archive(id: UUID) async throws {
        var project = try await repository.load(id: id)
        project.deletedAt = Date()
        project.updatedAt = Date()
        try await repository.save(project)
        await publish(ProjectArchivedEvent(projectID: id))
    }

    public func delete(id: UUID) async throws {
        var project = try await repository.load(id: id)
        project.deletedAt = Date()
        project.updatedAt = Date()
        try await repository.save(project)
        await publish(ProjectDeletedEvent(projectID: id))
    }

    public func load(id: UUID) async throws -> CodalonProject {
        try await repository.load(id: id)
    }

    public func loadAll() async throws -> [CodalonProject] {
        try await repository.loadAll()
    }

    public func loadActive() async throws -> [CodalonProject] {
        let all = try await repository.loadAll()
        return all.filter { $0.deletedAt == nil }
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}
