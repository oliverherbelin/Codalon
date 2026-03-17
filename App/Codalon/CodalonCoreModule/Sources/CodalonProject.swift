// Issue #12 — CodalonProject entity

import Foundation
import HelaiaCore

public struct CodalonProject: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    public var name: String
    public var slug: String
    public var icon: String
    public var color: String
    public var platform: CodalonPlatform
    public var projectType: CodalonProjectType
    public var activeReleaseID: UUID?
    public var linkedGitHubRepos: [String]
    public var linkedASCApp: String?
    public var healthScore: Double

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        name: String,
        slug: String,
        icon: String = "folder.fill",
        color: String = "#4A90D9",
        platform: CodalonPlatform = .macOS,
        projectType: CodalonProjectType = .app,
        activeReleaseID: UUID? = nil,
        linkedGitHubRepos: [String] = [],
        linkedASCApp: String? = nil,
        healthScore: Double = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.name = name
        self.slug = slug
        self.icon = icon
        self.color = color
        self.platform = platform
        self.projectType = projectType
        self.activeReleaseID = activeReleaseID
        self.linkedGitHubRepos = linkedGitHubRepos
        self.linkedASCApp = linkedASCApp
        self.healthScore = healthScore
    }
}
