// Issue #71 — GitHub repository reference entity

import Foundation
import HelaiaCore

public struct CodalonGitHubRepo: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var projectID: UUID
    public var owner: String
    public var name: String
    public var nodeID: String
    public var fullName: String
    public var isPrivate: Bool
    public var defaultBranch: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        owner: String,
        name: String,
        nodeID: String = "",
        fullName: String = "",
        isPrivate: Bool = false,
        defaultBranch: String = "main"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.owner = owner
        self.name = name
        self.nodeID = nodeID
        self.fullName = fullName.isEmpty ? "\(owner)/\(name)" : fullName
        self.isPrivate = isPrivate
        self.defaultBranch = defaultBranch
    }
}