// Issue #151 — Release EventBus events

import Foundation
import HelaiaEngine

// MARK: - Release Created

public struct ReleaseCreatedEvent: HelaiaEvent {
    public let releaseID: UUID
    public let version: String
    public let projectID: UUID
    public let timestamp: Date

    nonisolated public init(releaseID: UUID, version: String, projectID: UUID, timestamp: Date = .now) {
        self.releaseID = releaseID
        self.version = version
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - Release Updated

public struct ReleaseUpdatedEvent: HelaiaEvent {
    public let releaseID: UUID
    public let version: String
    public let timestamp: Date

    nonisolated public init(releaseID: UUID, version: String, timestamp: Date = .now) {
        self.releaseID = releaseID
        self.version = version
        self.timestamp = timestamp
    }
}

// MARK: - Release Status Changed

public struct ReleaseStatusChangedEvent: HelaiaEvent {
    public let releaseID: UUID
    public let oldStatus: CodalonReleaseStatus
    public let newStatus: CodalonReleaseStatus
    public let timestamp: Date

    nonisolated public init(releaseID: UUID, oldStatus: CodalonReleaseStatus, newStatus: CodalonReleaseStatus, timestamp: Date = .now) {
        self.releaseID = releaseID
        self.oldStatus = oldStatus
        self.newStatus = newStatus
        self.timestamp = timestamp
    }
}

// MARK: - Release Readiness Changed

public struct ReleaseReadinessChangedEvent: HelaiaEvent {
    public let releaseID: UUID
    public let oldScore: Double
    public let newScore: Double
    public let timestamp: Date

    nonisolated public init(releaseID: UUID, oldScore: Double, newScore: Double, timestamp: Date = .now) {
        self.releaseID = releaseID
        self.oldScore = oldScore
        self.newScore = newScore
        self.timestamp = timestamp
    }
}
