// Issue #119 — Project lifecycle events

import Foundation
import HelaiaEngine

// MARK: - Project Created

public struct ProjectCreatedEvent: HelaiaEvent {
    public let projectID: UUID
    public let name: String
    public let timestamp: Date

    public init(projectID: UUID, name: String, timestamp: Date = .now) {
        self.projectID = projectID
        self.name = name
        self.timestamp = timestamp
    }
}

// MARK: - Project Updated

public struct ProjectUpdatedEvent: HelaiaEvent {
    public let projectID: UUID
    public let timestamp: Date

    public init(projectID: UUID, timestamp: Date = .now) {
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Project Archived

public struct ProjectArchivedEvent: HelaiaEvent {
    public let projectID: UUID
    public let timestamp: Date

    public init(projectID: UUID, timestamp: Date = .now) {
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Project Deleted

public struct ProjectDeletedEvent: HelaiaEvent {
    public let projectID: UUID
    public let timestamp: Date

    public init(projectID: UUID, timestamp: Date = .now) {
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Project Selected (#117)

public struct ProjectSelectedEvent: HelaiaEvent {
    public let projectID: UUID?
    public let timestamp: Date

    public init(projectID: UUID?, timestamp: Date = .now) {
        self.projectID = projectID
        self.timestamp = timestamp
    }
}
