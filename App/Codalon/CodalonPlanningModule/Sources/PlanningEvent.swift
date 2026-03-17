// Issue #34 — Planning events

import Foundation
import HelaiaEngine

// MARK: - Milestone Created

public struct MilestoneCreatedEvent: HelaiaEvent {
    public let milestoneID: UUID
    public let projectID: UUID
    public let title: String
    public let timestamp: Date

    public init(
        milestoneID: UUID,
        projectID: UUID,
        title: String,
        timestamp: Date = .now
    ) {
        self.milestoneID = milestoneID
        self.projectID = projectID
        self.title = title
        self.timestamp = timestamp
    }
}

// MARK: - Milestone Updated

public struct MilestoneUpdatedEvent: HelaiaEvent {
    public let milestoneID: UUID
    public let projectID: UUID
    public let timestamp: Date

    public init(milestoneID: UUID, projectID: UUID, timestamp: Date = .now) {
        self.milestoneID = milestoneID
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Milestone Completed

public struct MilestoneCompletedEvent: HelaiaEvent {
    public let milestoneID: UUID
    public let projectID: UUID
    public let timestamp: Date

    public init(milestoneID: UUID, projectID: UUID, timestamp: Date = .now) {
        self.milestoneID = milestoneID
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Milestone Overdue Detected

public struct MilestoneOverdueDetectedEvent: HelaiaEvent {
    public let milestoneID: UUID
    public let projectID: UUID
    public let dueDate: Date
    public let timestamp: Date

    public init(
        milestoneID: UUID,
        projectID: UUID,
        dueDate: Date,
        timestamp: Date = .now
    ) {
        self.milestoneID = milestoneID
        self.projectID = projectID
        self.dueDate = dueDate
        self.timestamp = timestamp
    }
}
