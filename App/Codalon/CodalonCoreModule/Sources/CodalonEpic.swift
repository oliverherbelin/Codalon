// Issue #14 — CodalonEpic entity

import Foundation
import HelaiaCore

public struct CodalonEpic: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var milestoneID: UUID?
    public var title: String
    public var summary: String
    public var status: CodalonEpicStatus
    public var priority: CodalonPriority

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        milestoneID: UUID? = nil,
        title: String,
        summary: String = "",
        status: CodalonEpicStatus = .planned,
        priority: CodalonPriority = .medium
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.milestoneID = milestoneID
        self.title = title
        self.summary = summary
        self.status = status
        self.priority = priority
    }
}
