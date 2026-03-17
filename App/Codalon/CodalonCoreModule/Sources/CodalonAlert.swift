// Issue #18 — CodalonAlert entity

import Foundation
import HelaiaCore

public struct CodalonAlert: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var severity: CodalonSeverity
    public var category: CodalonAlertCategory
    public var title: String
    public var message: String
    public var readState: CodalonAlertReadState
    public var actionRoute: String?
    public var distributionTargets: Set<CodalonDistributionTarget>

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        severity: CodalonSeverity,
        category: CodalonAlertCategory,
        title: String,
        message: String,
        readState: CodalonAlertReadState = .unread,
        actionRoute: String? = nil,
        distributionTargets: Set<CodalonDistributionTarget> = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.severity = severity
        self.category = category
        self.title = title
        self.message = message
        self.readState = readState
        self.actionRoute = actionRoute
        self.distributionTargets = distributionTargets
    }
}
