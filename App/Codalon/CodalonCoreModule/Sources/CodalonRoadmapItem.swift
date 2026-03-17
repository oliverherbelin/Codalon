// Issue #29 — Roadmap item structure linking milestones to timeline positions

import Foundation
import HelaiaCore

public struct CodalonRoadmapItem: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var milestoneID: UUID
    public var startDate: Date?
    public var endDate: Date?
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        milestoneID: UUID,
        startDate: Date? = nil,
        endDate: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.milestoneID = milestoneID
        self.startDate = startDate
        self.endDate = endDate
        self.sortOrder = sortOrder
    }
}
