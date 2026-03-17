// Issue #19 — CodalonDecisionLogEntry entity

import Foundation
import HelaiaCore

public struct CodalonDecisionLogEntry: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var relatedObjectID: UUID?
    public var category: CodalonDecisionCategory
    public var title: String
    public var note: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        relatedObjectID: UUID? = nil,
        category: CodalonDecisionCategory,
        title: String,
        note: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.relatedObjectID = relatedObjectID
        self.category = category
        self.title = title
        self.note = note
    }
}
