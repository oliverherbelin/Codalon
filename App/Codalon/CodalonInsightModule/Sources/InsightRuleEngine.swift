// Issue #176 — Insight rule engine with deduplication and persistence

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol InsightRuleEngineProtocol: Sendable {
    func runAllRules(projectID: UUID) async throws -> [CodalonInsight]
}

// MARK: - Implementation

public actor InsightRuleEngine: InsightRuleEngineProtocol {

    private let rules: [any InsightRuleProtocol]
    private let taskRepository: any TaskRepositoryProtocol
    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol
    private let alertRepository: any AlertRepositoryProtocol
    private let insightRepository: any InsightRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        rules: [any InsightRuleProtocol],
        taskRepository: any TaskRepositoryProtocol,
        milestoneRepository: any MilestoneRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol,
        alertRepository: any AlertRepositoryProtocol,
        insightRepository: any InsightRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.rules = rules
        self.taskRepository = taskRepository
        self.milestoneRepository = milestoneRepository
        self.releaseRepository = releaseRepository
        self.alertRepository = alertRepository
        self.insightRepository = insightRepository
        self.logger = logger
    }

    public func runAllRules(projectID: UUID) async throws -> [CodalonInsight] {
        logger.info("Running \(rules.count) insight rules for project \(projectID)", category: "insight")

        // Build context
        let tasks = try await taskRepository.fetchByProject(projectID)
        let milestones = try await milestoneRepository.fetchByProject(projectID)
        let releases = try await releaseRepository.fetchByProject(projectID)
        let alerts = try await alertRepository.fetchByProject(projectID)

        let context = InsightRuleContext(
            projectID: projectID,
            tasks: tasks,
            milestones: milestones,
            releases: releases,
            alerts: alerts
        )

        // Evaluate all rules
        var detectedInsights: [DetectedInsight] = []
        for rule in rules {
            let results = await rule.evaluate(context: context)
            detectedInsights.append(contentsOf: results)
        }

        logger.info("Detected \(detectedInsights.count) insights", category: "insight")

        // Deduplicate against existing insights
        let existingInsights = try await insightRepository.fetchByProject(projectID)
        let existingKeys = Set(existingInsights.compactMap { insight -> String? in
            // Use title as dedup key for existing records
            "\(insight.source.rawValue):\(insight.title)"
        })

        var newInsights: [CodalonInsight] = []
        for detected in detectedInsights {
            let key = "\(CodalonInsightSource.ruleEngine.rawValue):\(detected.title)"
            guard !existingKeys.contains(key) else {
                logger.info("Skipping duplicate insight: \(detected.title)", category: "insight")
                continue
            }

            let insight = CodalonInsight(
                projectID: projectID,
                type: detected.type,
                severity: detected.severity,
                source: .ruleEngine,
                title: detected.title,
                message: detected.message
            )

            try await insightRepository.save(insight)
            newInsights.append(insight)
        }

        logger.success("Persisted \(newInsights.count) new insights", category: "insight")
        return newInsights
    }
}
