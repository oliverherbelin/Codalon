// Issue #176 — Insight rule engine with deduplication and persistence

import Foundation
import HelaiaEngine
import HelaiaGit
import HelaiaLogger

// MARK: - Protocol

public protocol InsightRuleEngineProtocol: Sendable {
    func runAllRules(projectID: UUID) async throws -> [CodalonInsight]
    func runAllRules(
        projectID: UUID,
        localUnstagedCount: Int,
        localStagedCount: Int,
        localAheadCount: Int
    ) async throws -> [CodalonInsight]
}

// MARK: - Implementation

public actor InsightRuleEngine: InsightRuleEngineProtocol {

    private let rules: [any InsightRuleProtocol]
    private let taskRepository: any TaskRepositoryProtocol
    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol
    private let alertRepository: any AlertRepositoryProtocol
    private let insightRepository: any InsightRepositoryProtocol
    private let repoPathRepository: any GitLocalRepoPathRepositoryProtocol
    private let gitService: any GitServiceProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        rules: [any InsightRuleProtocol],
        taskRepository: any TaskRepositoryProtocol,
        milestoneRepository: any MilestoneRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol,
        alertRepository: any AlertRepositoryProtocol,
        insightRepository: any InsightRepositoryProtocol,
        repoPathRepository: any GitLocalRepoPathRepositoryProtocol,
        gitService: any GitServiceProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.rules = rules
        self.taskRepository = taskRepository
        self.milestoneRepository = milestoneRepository
        self.releaseRepository = releaseRepository
        self.alertRepository = alertRepository
        self.insightRepository = insightRepository
        self.repoPathRepository = repoPathRepository
        self.gitService = gitService
        self.logger = logger
    }

    public func runAllRules(projectID: UUID) async throws -> [CodalonInsight] {
        // Issue #176 — Fallback: resolve git state from bookmark
        let gitState = await resolveLocalGitState(projectID: projectID)
        return try await runAllRules(
            projectID: projectID,
            localUnstagedCount: gitState.unstaged,
            localStagedCount: gitState.staged,
            localAheadCount: gitState.ahead
        )
    }

    public func runAllRules(
        projectID: UUID,
        localUnstagedCount: Int,
        localStagedCount: Int,
        localAheadCount: Int
    ) async throws -> [CodalonInsight] {
        logger.info(
            "Rule engine started, \(rules.count) rules registered",
            category: "insight-git"
        )
        logger.info(
            "Git state: unstaged=\(localUnstagedCount) staged=\(localStagedCount) ahead=\(localAheadCount)",
            category: "insight-git"
        )

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
            alerts: alerts,
            localUnstagedCount: localUnstagedCount,
            localStagedCount: localStagedCount,
            localAheadCount: localAheadCount
        )

        // Evaluate all rules
        var detectedInsights: [DetectedInsight] = []
        for rule in rules {
            let results = await rule.evaluate(context: context)
            detectedInsights.append(contentsOf: results)
        }

        logger.info("Detected \(detectedInsights.count) insights", category: "insight-git")

        // Issue #176 — Soft-delete existing rule-engine insights before persisting new ones
        let existingInsights = try await insightRepository.fetchBySource(.ruleEngine, projectID: projectID)
        for existing in existingInsights where existing.deletedAt == nil {
            var tombstone = existing
            tombstone.deletedAt = Date()
            tombstone.updatedAt = Date()
            try await insightRepository.save(tombstone)
        }
        logger.info(
            "Soft-deleted \(existingInsights.filter { $0.deletedAt == nil }.count) stale rule-engine insights",
            category: "insight-git"
        )

        // Persist new insights
        var newInsights: [CodalonInsight] = []
        for detected in detectedInsights {
            let insight = CodalonInsight(
                projectID: projectID,
                type: detected.type,
                severity: detected.severity,
                source: .ruleEngine,
                title: detected.title,
                message: detected.message,
                actionRoute: detected.actionRoute
            )
            try await insightRepository.save(insight)
            newInsights.append(insight)
        }

        logger.success("Persisted \(newInsights.count) new insights", category: "insight-git")
        return newInsights
    }

    // MARK: - Local Git State

    private struct LocalGitState: Sendable {
        let unstaged: Int
        let staged: Int
        let ahead: Int

        static let empty = LocalGitState(unstaged: 0, staged: 0, ahead: 0)
    }

    private func resolveLocalGitState(projectID: UUID) async -> LocalGitState {
        logger.info("resolveLocalGitState: entry for project \(projectID)", category: "insight-git")
        do {
            guard let localPath = try await repoPathRepository.fetchByProject(projectID) else {
                logger.info("resolveLocalGitState: no local repo linked for project \(projectID)", category: "insight-git")
                return .empty
            }

            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: localPath.bookmarkData,
                options: [.withSecurityScope],
                bookmarkDataIsStale: &isStale
            ) else {
                logger.warning("Bookmark resolution failed for \(localPath.displayPath)", category: "insight-git")
                return .empty
            }

            let accessGranted = url.startAccessingSecurityScopedResource()
            guard accessGranted else {
                logger.warning("Security-scoped access denied for \(localPath.displayPath)", category: "insight-git")
                return .empty
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let repo = try await gitService.open(at: url)
            let status = try await gitService.status(in: repo)
            let branch = try await gitService.currentBranch(in: repo)

            let ahead: Int
            do {
                ahead = try await gitService.aheadCount(branch: branch.name, remote: "origin", in: repo)
            } catch {
                logger.warning("Could not determine ahead count: \(error.localizedDescription)", category: "insight-git")
                ahead = 0
            }

            let unstaged = status.unstagedFiles.count + status.untrackedFiles.count
            let staged = status.stagedFiles.count

            logger.info("resolveLocalGitState: exit — \(unstaged) unstaged, \(staged) staged, \(ahead) ahead", category: "insight-git")
            return LocalGitState(unstaged: unstaged, staged: staged, ahead: ahead)
        } catch {
            logger.warning("resolveLocalGitState: failed — \(error.localizedDescription)", category: "insight-git")
            return .empty
        }
    }
}
