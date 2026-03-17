// Issue #116 — Recent projects tracking

import Foundation

// MARK: - Protocol

public protocol RecentProjectsServiceProtocol: Sendable {
    func recentProjectIDs() async -> [UUID]
    func recordAccess(_ projectID: UUID) async
    func recentProjects(from all: [CodalonProject]) async -> [CodalonProject]
}

// MARK: - Implementation

public actor RecentProjectsService: RecentProjectsServiceProtocol {

    private nonisolated static let persistenceKey = "codalon.recentProjectIDs"
    private nonisolated static let maxRecent = 3

    private var ids: [UUID]

    public init() {
        self.ids = Self.loadPersistedIDs()
    }

    public func recentProjectIDs() -> [UUID] {
        ids
    }

    public func recordAccess(_ projectID: UUID) {
        ids.removeAll { $0 == projectID }
        ids.insert(projectID, at: 0)
        if ids.count > Self.maxRecent {
            ids = Array(ids.prefix(Self.maxRecent))
        }
        persistIDs()
    }

    public func recentProjects(from all: [CodalonProject]) -> [CodalonProject] {
        ids.compactMap { id in
            all.first { $0.id == id && $0.deletedAt == nil }
        }
    }

    // MARK: - Persistence

    private func persistIDs() {
        let strings = ids.map(\.uuidString)
        UserDefaults.standard.set(strings, forKey: Self.persistenceKey)
    }

    private nonisolated static func loadPersistedIDs() -> [UUID] {
        guard let strings = UserDefaults.standard.stringArray(
            forKey: persistenceKey
        ) else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }
}
