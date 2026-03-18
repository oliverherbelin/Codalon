// Issues #93, #95, #99, #100 — GitHub sync service

import Foundation
import HelaiaGit
import HelaiaLogger

// MARK: - Protocol

public protocol GitHubSyncServiceProtocol: Sendable {
    func mapTaskToIssue(taskID: UUID, issueRef: String, taskRepository: any TaskRepositoryProtocol) async throws
    func unmapTask(taskID: UUID, taskRepository: any TaskRepositoryProtocol) async throws
    func mapMilestoneToGitHub(milestoneID: UUID, number: Int, milestoneRepository: any MilestoneRepositoryProtocol) async throws
    func unmapMilestone(milestoneID: UUID, milestoneRepository: any MilestoneRepositoryProtocol) async throws
    func syncAll(owner: String, repo: String, projectID: UUID) async throws -> GitHubSyncResult
    nonisolated func detectStaleIssues(in issues: [GitIssue], daysThreshold: Int) -> [GitIssue]
}

// MARK: - Implementation

public actor GitHubSyncService: GitHubSyncServiceProtocol {

    private let gitHubService: any GitHubServiceProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        gitHubService: any GitHubServiceProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.gitHubService = gitHubService
        self.logger = logger
    }

    // MARK: - Issue #93 — Task-Issue Mapping

    public func mapTaskToIssue(
        taskID: UUID,
        issueRef: String,
        taskRepository: any TaskRepositoryProtocol
    ) async throws {
        logger.info("Mapping task \(taskID.uuidString) to issue \(issueRef)", category: "github.sync")
        var task = try await taskRepository.load(id: taskID)
        task.githubIssueRef = issueRef
        task.updatedAt = .now
        try await taskRepository.save(task)
        logger.success("Task mapped to issue \(issueRef)", category: "github.sync")
    }

    public func unmapTask(
        taskID: UUID,
        taskRepository: any TaskRepositoryProtocol
    ) async throws {
        logger.info("Unmapping task \(taskID.uuidString) from GitHub issue", category: "github.sync")
        var task = try await taskRepository.load(id: taskID)
        task.githubIssueRef = nil
        task.updatedAt = .now
        try await taskRepository.save(task)
        logger.success("Task unmapped from GitHub issue", category: "github.sync")
    }

    // MARK: - Issue #95 — Milestone Mapping

    public func mapMilestoneToGitHub(
        milestoneID: UUID,
        number: Int,
        milestoneRepository: any MilestoneRepositoryProtocol
    ) async throws {
        logger.info("Mapping milestone \(milestoneID.uuidString) to GitHub milestone #\(number)", category: "github.sync")
        var milestone = try await milestoneRepository.load(id: milestoneID)
        milestone.githubMilestoneNumber = number
        milestone.updatedAt = .now
        try await milestoneRepository.save(milestone)
        logger.success("Milestone mapped to GitHub milestone #\(number)", category: "github.sync")
    }

    public func unmapMilestone(
        milestoneID: UUID,
        milestoneRepository: any MilestoneRepositoryProtocol
    ) async throws {
        logger.info("Unmapping milestone \(milestoneID.uuidString) from GitHub milestone", category: "github.sync")
        var milestone = try await milestoneRepository.load(id: milestoneID)
        milestone.githubMilestoneNumber = nil
        milestone.updatedAt = .now
        try await milestoneRepository.save(milestone)
        logger.success("Milestone unmapped from GitHub milestone", category: "github.sync")
    }

    // MARK: - Issue #100 — Full Sync

    public func syncAll(
        owner: String,
        repo: String,
        projectID: UUID
    ) async throws -> GitHubSyncResult {
        logger.info("Starting full GitHub sync for \(owner)/\(repo)", category: "github.sync")

        async let fetchedIssues = gitHubService.fetchIssues(owner: owner, repo: repo, state: "all")
        async let fetchedMilestones = gitHubService.fetchMilestones(owner: owner, repo: repo)
        async let fetchedPRs = gitHubService.fetchPullRequests(owner: owner, repo: repo, state: "all")

        let issues = try await fetchedIssues
        let milestones = try await fetchedMilestones
        let prs = try await fetchedPRs
        let stale = detectStaleIssues(in: issues.filter { $0.state == "open" }, daysThreshold: 30)

        let result = GitHubSyncResult(
            issuesFetched: issues.count,
            milestonesFetched: milestones.count,
            pullRequestsFetched: prs.count,
            staleIssuesDetected: stale.count,
            timestamp: .now
        )

        logger.success(
            "GitHub sync complete: \(issues.count) issues, \(milestones.count) milestones, \(prs.count) PRs, \(stale.count) stale",
            category: "github.sync"
        )

        return result
    }

    // MARK: - Issue #99 — Stale Issue Detection

    nonisolated public func detectStaleIssues(in issues: [GitIssue], daysThreshold: Int) -> [GitIssue] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysThreshold, to: .now) ?? .now
        return issues.filter { $0.updatedAt < cutoffDate }
    }
}
