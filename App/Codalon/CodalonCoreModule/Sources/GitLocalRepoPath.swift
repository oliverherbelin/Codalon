// Issue #275 — Local folder path model for project-to-folder binding

import Foundation
import HelaiaCore

public struct GitLocalRepoPath: HelaiaRecord, Equatable {
    public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var schemaVersion: Int

    /// The project this folder belongs to.
    public var projectID: UUID

    /// Security-scoped bookmark data for the local folder.
    public var bookmarkData: Data

    /// Display-only path string (not used for access — use bookmark).
    public var displayPath: String

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        schemaVersion: Int = 1,
        projectID: UUID,
        bookmarkData: Data,
        displayPath: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.schemaVersion = schemaVersion
        self.projectID = projectID
        self.bookmarkData = bookmarkData
        self.displayPath = displayPath
    }
}
