// Issues #178, #180 — Preview helpers for insight module

import Foundation

// MARK: - Preview Insight Repository

actor PreviewInsightRepository: InsightRepositoryProtocol {
    private let projectID: UUID

    init(projectID: UUID = UUID()) {
        self.projectID = projectID
    }

    private lazy var sampleInsights: [CodalonInsight] = [
        CodalonInsight(
            projectID: projectID,
            type: .anomaly,
            severity: .warning,
            source: .ruleEngine,
            title: "3 tasks overdue",
            message: "There are 3 tasks past their due date in the current sprint."
        ),
        CodalonInsight(
            projectID: projectID,
            type: .suggestion,
            severity: .info,
            source: .ruleEngine,
            title: "Milestone overdue: Beta",
            message: "Beta milestone was due 5 days ago and is still active."
        ),
        CodalonInsight(
            projectID: projectID,
            type: .reminder,
            severity: .critical,
            source: .ruleEngine,
            title: "5 unread critical alerts",
            message: "There are 5 unresolved critical alerts requiring attention."
        ),
        CodalonInsight(
            projectID: projectID,
            type: .trend,
            severity: .info,
            source: .analytics,
            title: "Task completion trending up",
            message: "Task completion rate has improved 15% over the last 2 weeks."
        ),
    ]

    func save(_ insight: CodalonInsight) async throws {}
    func load(id: UUID) async throws -> CodalonInsight {
        sampleInsights[0]
    }
    func loadAll() async throws -> [CodalonInsight] { sampleInsights }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight] { sampleInsights }
    func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] {
        sampleInsights.filter { $0.severity == severity }
    }
    func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] {
        sampleInsights.filter { $0.source == source }
    }
}

// MARK: - Preview Rule Engine

actor PreviewRuleEngine: InsightRuleEngineProtocol {
    func runAllRules(projectID: UUID) async throws -> [CodalonInsight] { [] }
}

// MARK: - Preview Health Score Service

actor PreviewHealthScoreService: HealthScoreServiceProtocol {
    func recalculate(projectID: UUID) async throws -> HealthScoreResult {
        HealthScoreResult(
            overallScore: 0.72,
            dimensions: [
                HealthScoreDimension(id: HealthScoreDimensionID.planning, label: "Planning", value: 0.59),
                HealthScoreDimension(id: HealthScoreDimensionID.release, label: "Release", value: 0.85),
                HealthScoreDimension(id: HealthScoreDimensionID.github, label: "GitHub", value: 0.90),
                HealthScoreDimension(id: HealthScoreDimensionID.store, label: "App Store", value: 0.55),
            ]
        )
    }
}
