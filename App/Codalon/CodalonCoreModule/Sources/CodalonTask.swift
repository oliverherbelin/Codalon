// Issue #15 — CodalonTask entity

import Foundation
import HelaiaCore

public struct CodalonTask: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var milestoneID: UUID?
    public var epicID: UUID?
    public var title: String
    public var summary: String
    public var status: CodalonTaskStatus
    public var priority: CodalonPriority
    public var estimate: Double?
    public var dueDate: Date?
    public var isBlocked: Bool
    public var isLaunchCritical: Bool
    public var waitingExternal: Bool
    public var githubIssueRef: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        milestoneID: UUID? = nil,
        epicID: UUID? = nil,
        title: String,
        summary: String = "",
        status: CodalonTaskStatus = .backlog,
        priority: CodalonPriority = .medium,
        estimate: Double? = nil,
        dueDate: Date? = nil,
        isBlocked: Bool = false,
        isLaunchCritical: Bool = false,
        waitingExternal: Bool = false,
        githubIssueRef: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.milestoneID = milestoneID
        self.epicID = epicID
        self.title = title
        self.summary = summary
        self.status = status
        self.priority = priority
        self.estimate = estimate
        self.dueDate = dueDate
        self.isBlocked = isBlocked
        self.isLaunchCritical = isLaunchCritical
        self.waitingExternal = waitingExternal
        self.githubIssueRef = githubIssueRef
    }
}
