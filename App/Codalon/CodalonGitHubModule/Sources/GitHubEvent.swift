// Issues #59, #69 — GitHub events

import Foundation
import HelaiaEngine

// MARK: - GitHub Authenticated

public struct GitHubAuthenticatedEvent: HelaiaEvent {
    public let username: String
    public let timestamp: Date

    public init(username: String, timestamp: Date = .now) {
        self.username = username
        self.timestamp = timestamp
    }
}

// MARK: - GitHub Repo Linked

public struct GitHubRepoLinkedEvent: HelaiaEvent {
    public let projectID: UUID
    public let repoFullName: String
    public let timestamp: Date

    public init(projectID: UUID, repoFullName: String, timestamp: Date = .now) {
        self.projectID = projectID
        self.repoFullName = repoFullName
        self.timestamp = timestamp
    }
}

// MARK: - GitHub Auth Removed

public struct GitHubAuthRemovedEvent: HelaiaEvent {
    public let timestamp: Date

    public init(timestamp: Date = .now) {
        self.timestamp = timestamp
    }
}