// Issues #16, #133, #136, #141 — CodalonRelease entity

import Foundation
import HelaiaCore

public struct CodalonRelease: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var version: String
    public var buildNumber: String
    public var targetDate: Date?
    public var status: CodalonReleaseStatus
    public var readinessScore: Double
    public var checklistItems: [CodalonChecklistItem]
    public var blockerCount: Int
    public var linkedMilestoneID: UUID?
    public var linkedASCBuildRef: String?
    public var linkedTaskIDs: [UUID]
    public var linkedGitHubIssueRefs: [String]
    public var blockers: [CodalonReleaseBlocker]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        version: String,
        buildNumber: String = "1",
        targetDate: Date? = nil,
        status: CodalonReleaseStatus = .drafting,
        readinessScore: Double = 0,
        checklistItems: [CodalonChecklistItem] = [],
        blockerCount: Int = 0,
        linkedMilestoneID: UUID? = nil,
        linkedASCBuildRef: String? = nil,
        linkedTaskIDs: [UUID] = [],
        linkedGitHubIssueRefs: [String] = [],
        blockers: [CodalonReleaseBlocker] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.version = version
        self.buildNumber = buildNumber
        self.targetDate = targetDate
        self.status = status
        self.readinessScore = readinessScore
        self.checklistItems = checklistItems
        self.blockerCount = blockerCount
        self.linkedMilestoneID = linkedMilestoneID
        self.linkedASCBuildRef = linkedASCBuildRef
        self.linkedTaskIDs = linkedTaskIDs
        self.linkedGitHubIssueRefs = linkedGitHubIssueRefs
        self.blockers = blockers
    }
}
