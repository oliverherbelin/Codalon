// Issues #20, #141 — Shared enums and value types

import Foundation

// MARK: - Platform

public enum CodalonPlatform: String, Codable, Sendable, Hashable, CaseIterable {
    case iOS
    case macOS
    case visionOS
    case watchOS
    case tvOS
    case multiplatform
}

// MARK: - Project Type

public enum CodalonProjectType: String, Codable, Sendable, Hashable, CaseIterable {
    case app
    case framework
    case plugin
    case cli
    case other
}

// MARK: - Priority

public enum CodalonPriority: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical

    nonisolated public static func < (lhs: CodalonPriority, rhs: CodalonPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private nonisolated var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
}

// MARK: - Severity

public enum CodalonSeverity: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case info
    case warning
    case error
    case critical

    nonisolated public static func < (lhs: CodalonSeverity, rhs: CodalonSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private nonisolated var sortOrder: Int {
        switch self {
        case .info: return 0
        case .warning: return 1
        case .error: return 2
        case .critical: return 3
        }
    }
}

// MARK: - Task Status

public enum CodalonTaskStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case backlog
    case todo
    case inProgress
    case inReview
    case done
    case cancelled
}

// MARK: - Milestone Status

public enum CodalonMilestoneStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case planned
    case active
    case completed
    case cancelled
}

// MARK: - Epic Status

public enum CodalonEpicStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case planned
    case active
    case completed
    case cancelled
}

// MARK: - Release Status

public enum CodalonReleaseStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case drafting
    case readyForQA
    case testing
    case readyForSubmission
    case submitted
    case inReview
    case approved
    case released
    case rejected
    case cancelled
}

// MARK: - Insight Type

public enum CodalonInsightType: String, Codable, Sendable, Hashable, CaseIterable {
    case suggestion
    case anomaly
    case trend
    case reminder
}

// MARK: - Insight Source

public enum CodalonInsightSource: String, Codable, Sendable, Hashable, CaseIterable {
    case ruleEngine
    case analytics
    case appStore
    case github
    case system
}

// MARK: - Alert Category

public enum CodalonAlertCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case build
    case crash
    case review
    case release
    case milestone
    case security
    case git
    case general
}

// MARK: - Alert Read State

public enum CodalonAlertReadState: String, Codable, Sendable, Hashable, CaseIterable {
    case unread
    case read
    case dismissed
}

// MARK: - Decision Category

public enum CodalonDecisionCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case architecture
    case design
    case scope
    case process
    case tooling
    case other
}

// MARK: - Checklist Item (Value Type)

public struct CodalonChecklistItem: Codable, Sendable {
    public var id: UUID
    public var title: String
    public var isComplete: Bool

    nonisolated public init(id: UUID = UUID(), title: String, isComplete: Bool = false) {
        self.id = id
        self.title = title
        self.isComplete = isComplete
    }
}

extension CodalonChecklistItem: Equatable {
    nonisolated public static func == (lhs: CodalonChecklistItem, rhs: CodalonChecklistItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.isComplete == rhs.isComplete
    }
}

extension CodalonChecklistItem: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(isComplete)
    }
}

// MARK: - Release Blocker (Value Type) — Issue #141

public struct CodalonReleaseBlocker: Codable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var source: String
    public var severity: CodalonSeverity
    public var isResolved: Bool
    public var createdAt: Date

    nonisolated public init(
        id: UUID = UUID(),
        title: String,
        source: String = "",
        severity: CodalonSeverity = .warning,
        isResolved: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.severity = severity
        self.isResolved = isResolved
        self.createdAt = createdAt
    }
}

extension CodalonReleaseBlocker: Equatable {
    nonisolated public static func == (lhs: CodalonReleaseBlocker, rhs: CodalonReleaseBlocker) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.source == rhs.source
            && lhs.severity == rhs.severity && lhs.isResolved == rhs.isResolved
    }
}

extension CodalonReleaseBlocker: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(isResolved)
    }
}
