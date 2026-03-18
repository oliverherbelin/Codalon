// Issues #34, #42, #56, #58, #60 — Task events

import Foundation
import HelaiaEngine

// MARK: - Task Created

public struct TaskCreatedEvent: HelaiaEvent {
    public let taskID: UUID
    public let projectID: UUID
    public let title: String
    public let timestamp: Date

    public init(taskID: UUID, projectID: UUID, title: String, timestamp: Date = .now) {
        self.taskID = taskID
        self.projectID = projectID
        self.title = title
        self.timestamp = timestamp
    }
}

// MARK: - Task Updated

public struct TaskUpdatedEvent: HelaiaEvent {
    public let taskID: UUID
    public let projectID: UUID
    public let timestamp: Date

    public init(taskID: UUID, projectID: UUID, timestamp: Date = .now) {
        self.taskID = taskID
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Task Status Changed

public struct TaskStatusChangedEvent: HelaiaEvent {
    public let taskID: UUID
    public let projectID: UUID
    public let oldStatus: CodalonTaskStatus
    public let newStatus: CodalonTaskStatus
    public let timestamp: Date

    public init(
        taskID: UUID,
        projectID: UUID,
        oldStatus: CodalonTaskStatus,
        newStatus: CodalonTaskStatus,
        timestamp: Date = .now
    ) {
        self.taskID = taskID
        self.projectID = projectID
        self.oldStatus = oldStatus
        self.newStatus = newStatus
        self.timestamp = timestamp
    }
}

// MARK: - Task Blocked

public struct TaskBlockedEvent: HelaiaEvent {
    public let taskID: UUID
    public let projectID: UUID
    public let timestamp: Date

    public init(taskID: UUID, projectID: UUID, timestamp: Date = .now) {
        self.taskID = taskID
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Task Deleted

public struct TaskDeletedEvent: HelaiaEvent {
    public let taskID: UUID
    public let projectID: UUID
    public let timestamp: Date

    public init(taskID: UUID, projectID: UUID, timestamp: Date = .now) {
        self.taskID = taskID
        self.projectID = projectID
        self.timestamp = timestamp
    }
}