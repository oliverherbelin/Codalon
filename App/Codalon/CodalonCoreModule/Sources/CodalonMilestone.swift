// Issues #13, #95 — CodalonMilestone entity

import Foundation
import HelaiaCore

public struct CodalonMilestone: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var title: String
    public var summary: String
    public var dueDate: Date?
    public var status: CodalonMilestoneStatus
    public var priority: CodalonPriority
    public var progress: Double
    public var githubMilestoneNumber: Int?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        title: String,
        summary: String = "",
        dueDate: Date? = nil,
        status: CodalonMilestoneStatus = .planned,
        priority: CodalonPriority = .medium,
        progress: Double = 0,
        githubMilestoneNumber: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.title = title
        self.summary = summary
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.progress = progress
        self.githubMilestoneNumber = githubMilestoneNumber
    }
}
