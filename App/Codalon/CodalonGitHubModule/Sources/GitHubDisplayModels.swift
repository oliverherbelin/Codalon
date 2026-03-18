// Issues #85, #93, #95, #99, #100 — GitHub display models and DTOs

import Foundation

// MARK: - Issue #85 — GitHub Milestone DTO

public struct GitHubMilestoneDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: Int
    public let number: Int
    public let title: String
    public let description: String?
    public let state: String
    public let dueOn: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let openIssues: Int
    public let closedIssues: Int

    enum CodingKeys: String, CodingKey {
        case id, number, title, description, state
        case dueOn = "due_on"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case openIssues = "open_issues"
        case closedIssues = "closed_issues"
    }

    nonisolated public init(
        id: Int,
        number: Int,
        title: String,
        description: String?,
        state: String,
        dueOn: Date?,
        createdAt: Date,
        updatedAt: Date,
        openIssues: Int,
        closedIssues: Int
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.description = description
        self.state = state
        self.dueOn = dueOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.openIssues = openIssues
        self.closedIssues = closedIssues
    }

    public var totalIssues: Int { openIssues + closedIssues }

    public var progress: Double {
        guard totalIssues > 0 else { return 0 }
        return Double(closedIssues) / Double(totalIssues)
    }

    public var isOpen: Bool { state == "open" }
}

// MARK: - Issue #93 — Task-Issue Mapping

public struct GitHubTaskIssueMapping: Sendable, Equatable {
    public let taskID: UUID
    public let issueRef: String

    nonisolated public init(taskID: UUID, issueRef: String) {
        self.taskID = taskID
        self.issueRef = issueRef
    }

    public var issueNumber: Int? {
        guard let hashIndex = issueRef.lastIndex(of: "#"),
              let number = Int(issueRef[issueRef.index(after: hashIndex)...])
        else { return nil }
        return number
    }

    public var repoFullName: String? {
        guard let hashIndex = issueRef.lastIndex(of: "#") else { return nil }
        return String(issueRef[..<hashIndex])
    }
}

// MARK: - Issue #100 — Sync Result

public struct GitHubSyncResult: Sendable {
    public let issuesFetched: Int
    public let milestonesFetched: Int
    public let pullRequestsFetched: Int
    public let staleIssuesDetected: Int
    public let timestamp: Date

    nonisolated public init(
        issuesFetched: Int = 0,
        milestonesFetched: Int = 0,
        pullRequestsFetched: Int = 0,
        staleIssuesDetected: Int = 0,
        timestamp: Date = .now
    ) {
        self.issuesFetched = issuesFetched
        self.milestonesFetched = milestonesFetched
        self.pullRequestsFetched = pullRequestsFetched
        self.staleIssuesDetected = staleIssuesDetected
        self.timestamp = timestamp
    }
}

extension GitHubSyncResult: Equatable {
    nonisolated public static func == (lhs: GitHubSyncResult, rhs: GitHubSyncResult) -> Bool {
        lhs.issuesFetched == rhs.issuesFetched
            && lhs.milestonesFetched == rhs.milestonesFetched
            && lhs.pullRequestsFetched == rhs.pullRequestsFetched
            && lhs.staleIssuesDetected == rhs.staleIssuesDetected
            && lhs.timestamp == rhs.timestamp
    }
}
