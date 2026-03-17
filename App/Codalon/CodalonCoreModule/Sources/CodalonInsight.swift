// Issue #17 — CodalonInsight entity

import Foundation
import HelaiaCore

public struct CodalonInsight: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var type: CodalonInsightType
    public var severity: CodalonSeverity
    public var source: CodalonInsightSource
    public var title: String
    public var message: String
    public var actionRoute: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        type: CodalonInsightType,
        severity: CodalonSeverity = .info,
        source: CodalonInsightSource,
        title: String,
        message: String,
        actionRoute: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.type = type
        self.severity = severity
        self.source = source
        self.title = title
        self.message = message
        self.actionRoute = actionRoute
    }
}
