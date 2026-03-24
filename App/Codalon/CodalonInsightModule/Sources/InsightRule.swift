// Issues #163, #165, #167, #170, #172, #174 — Insight detection rules

import Foundation

// MARK: - InsightRuleProtocol

public protocol InsightRuleProtocol: Sendable {
    var ruleID: String { get }
    func evaluate(context: InsightRuleContext) async -> [DetectedInsight]
}

// MARK: - Rule Context

public struct InsightRuleContext: Sendable {
    public let projectID: UUID
    public let tasks: [CodalonTask]
    public let milestones: [CodalonMilestone]
    public let releases: [CodalonRelease]
    public let alerts: [CodalonAlert]
    public let now: Date

    // Local Git state (populated when a local repo is linked)
    public let localUnstagedCount: Int
    public let localStagedCount: Int
    public let localAheadCount: Int

    nonisolated public init(
        projectID: UUID,
        tasks: [CodalonTask] = [],
        milestones: [CodalonMilestone] = [],
        releases: [CodalonRelease] = [],
        alerts: [CodalonAlert] = [],
        now: Date = .now,
        localUnstagedCount: Int = 0,
        localStagedCount: Int = 0,
        localAheadCount: Int = 0
    ) {
        self.projectID = projectID
        self.tasks = tasks
        self.milestones = milestones
        self.releases = releases
        self.alerts = alerts
        self.now = now
        self.localUnstagedCount = localUnstagedCount
        self.localStagedCount = localStagedCount
        self.localAheadCount = localAheadCount
    }
}

// MARK: - Detected Insight (pre-persistence DTO)

public struct DetectedInsight: Sendable, Equatable {
    public let ruleID: String
    public let type: CodalonInsightType
    public let severity: CodalonSeverity
    public let title: String
    public let message: String
    public let deduplicationKey: String
    public let actionRoute: String?

    nonisolated public init(
        ruleID: String,
        type: CodalonInsightType,
        severity: CodalonSeverity,
        title: String,
        message: String,
        deduplicationKey: String,
        actionRoute: String? = nil
    ) {
        self.ruleID = ruleID
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.deduplicationKey = deduplicationKey
        self.actionRoute = actionRoute
    }
}
