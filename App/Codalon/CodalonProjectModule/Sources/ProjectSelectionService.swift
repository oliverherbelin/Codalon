// Issues #117, #118 — Project selection state + persistence

import Foundation
import HelaiaEngine

// MARK: - Protocol

public protocol ProjectSelectionServiceProtocol: Sendable {
    func selectedProjectID() async -> UUID?
    func select(_ projectID: UUID?) async
    func restoreLastSelection() async
}

// MARK: - Implementation

public actor ProjectSelectionService: ProjectSelectionServiceProtocol {

    private let repository: any ProjectRepositoryProtocol
    private var currentID: UUID?

    private nonisolated static let persistenceKey = "codalon.selectedProjectID"

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
        self.currentID = Self.loadPersistedID()
    }

    public func selectedProjectID() -> UUID? {
        currentID
    }

    public func select(_ projectID: UUID?) async {
        currentID = projectID
        Self.persist(projectID)
        await MainActor.run {
            EventBus.shared.publish(ProjectSelectedEvent(projectID: projectID))
        }
    }

    public func restoreLastSelection() async {
        guard let stored = Self.loadPersistedID() else { return }
        let exists = try? await repository.exists(id: stored)
        if exists == true {
            currentID = stored
            await MainActor.run {
                EventBus.shared.publish(ProjectSelectedEvent(projectID: stored))
            }
        } else {
            currentID = nil
            Self.persist(nil)
        }
    }

    // MARK: - Persistence

    private nonisolated static func persist(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: persistenceKey)
        } else {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }

    private nonisolated static func loadPersistedID() -> UUID? {
        guard let string = UserDefaults.standard.string(
            forKey: persistenceKey
        ) else { return nil }
        return UUID(uuidString: string)
    }
}
