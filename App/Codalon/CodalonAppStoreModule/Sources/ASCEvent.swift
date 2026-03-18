// Issues #179, #189, #193 — ASC events

import Foundation
import HelaiaEngine

// MARK: - ASC Authenticated

public struct ASCAuthenticatedEvent: HelaiaEvent {
    public let issuerID: String
    public let timestamp: Date

    public init(issuerID: String, timestamp: Date = .now) {
        self.issuerID = issuerID
        self.timestamp = timestamp
    }
}

// MARK: - ASC App Linked

public struct ASCAppLinkedEvent: HelaiaEvent {
    public let projectID: UUID
    public let appName: String
    public let bundleID: String
    public let timestamp: Date

    public init(projectID: UUID, appName: String, bundleID: String, timestamp: Date = .now) {
        self.projectID = projectID
        self.appName = appName
        self.bundleID = bundleID
        self.timestamp = timestamp
    }
}

// MARK: - ASC App Unlinked

public struct ASCAppUnlinkedEvent: HelaiaEvent {
    public let projectID: UUID
    public let timestamp: Date

    public init(projectID: UUID, timestamp: Date = .now) {
        self.projectID = projectID
        self.timestamp = timestamp
    }
}

// MARK: - ASC Auth Removed

public struct ASCAuthRemovedEvent: HelaiaEvent {
    public let timestamp: Date

    public init(timestamp: Date = .now) {
        self.timestamp = timestamp
    }
}
