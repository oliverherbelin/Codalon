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

    nonisolated public init(
        projectID: UUID,
        tasks: [CodalonTask] = [],
        milestones: [CodalonMilestone] = [],
        releases: [CodalonRelease] = [],
        alerts: [CodalonAlert] = [],
        now: Date = .now
    ) {
        self.projectID = projectID
        self.tasks = tasks
        self.milestones = milestones
        self.releases = releases
        self.alerts = alerts
        self.now = now
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

    nonisolated public init(
        ruleID: String,
        type: CodalonInsightType,
        severity: CodalonSeverity,
        title: String,
        message: String,
        deduplicationKey: String
    ) {
        self.ruleID = ruleID
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.deduplicationKey = deduplicationKey
    }
}
