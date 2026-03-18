// Issue #101 — Task-issue and milestone-milestone mapping tests

import Foundation
import HelaiaGit
import Testing
@testable import Codalon

// MARK: - Task-Issue Mapping Tests (#101)

@Suite("GitHubTaskIssueMapping")
@MainActor
struct TaskIssueMappingTests {

    @Test("issueRef parsing extracts number")
    func parseIssueNumber() {
        let mapping = GitHubTaskIssueMapping(
            taskID: UUID(),
            issueRef: "oliverherbelin/Codalon#42"
        )

        #expect(mapping.issueNumber == 42)
        #expect(mapping.repoFullName == "oliverherbelin/Codalon")
    }

    @Test("issueRef parsing handles missing hash")
    func parseIssueRefNoHash() {
        let mapping = GitHubTaskIssueMapping(
            taskID: UUID(),
            issueRef: "invalid-ref"
        )

        #expect(mapping.issueNumber == nil)
        #expect(mapping.repoFullName == nil)
    }

    @Test("issueRef parsing handles number-only after hash")
    func parseIssueRefHashOnly() {
        let mapping = GitHubTaskIssueMapping(
            taskID: UUID(),
            issueRef: "#99"
        )

        #expect(mapping.issueNumber == 99)
    }

    @Test("task githubIssueRef stores and retrieves")
    func taskIssueRefField() {
        let task = CodalonTask(
            projectID: UUID(),
            title: "Test task",
            githubIssueRef: "oliverherbelin/Codalon#10"
        )

        #expect(task.githubIssueRef == "oliverherbelin/Codalon#10")
    }

    @Test("task githubIssueRef defaults to nil")
    func taskIssueRefDefault() {
        let task = CodalonTask(
            projectID: UUID(),
            title: "Test task"
        )

        #expect(task.githubIssueRef == nil)
    }

    @Test("milestone githubMilestoneNumber stores and retrieves")
    func milestoneGitHubNumber() {
        let milestone = CodalonMilestone(
            projectID: UUID(),
            title: "v1.0",
            githubMilestoneNumber: 3
        )

        #expect(milestone.githubMilestoneNumber == 3)
    }

    @Test("milestone githubMilestoneNumber defaults to nil")
    func milestoneGitHubNumberDefault() {
        let milestone = CodalonMilestone(
            projectID: UUID(),
            title: "v1.0"
        )

        #expect(milestone.githubMilestoneNumber == nil)
    }
}

// MARK: - GitHubMilestoneDTO Tests (#101)

@Suite("GitHubMilestoneDTO")
@MainActor
struct MilestoneDTOTests {

    @Test("progress computes from open/closed counts")
    func progress() {
        let dto = GitHubMilestoneDTO(
            id: 1,
            number: 1,
            title: "v1.0",
            description: nil,
            state: "open",
            dueOn: nil,
            createdAt: .now,
            updatedAt: .now,
            openIssues: 3,
            closedIssues: 7
        )

        #expect(dto.progress == 0.7)
        #expect(dto.totalIssues == 10)
        #expect(dto.isOpen == true)
    }

    @Test("progress handles zero issues")
    func progressZero() {
        let dto = GitHubMilestoneDTO(
            id: 1,
            number: 1,
            title: "Empty",
            description: nil,
            state: "open",
            dueOn: nil,
            createdAt: .now,
            updatedAt: .now,
            openIssues: 0,
            closedIssues: 0
        )

        #expect(dto.progress == 0)
        #expect(dto.totalIssues == 0)
    }

    @Test("closed state reports isOpen false")
    func closedState() {
        let dto = GitHubMilestoneDTO(
            id: 1,
            number: 1,
            title: "Done",
            description: nil,
            state: "closed",
            dueOn: nil,
            createdAt: .now,
            updatedAt: .now,
            openIssues: 0,
            closedIssues: 5
        )

        #expect(dto.isOpen == false)
        #expect(dto.progress == 1.0)
    }
}

// MARK: - GitHubSyncResult Tests (#101)

@Suite("GitHubSyncResult")
@MainActor
struct SyncResultTests {

    @Test("default values")
    func defaults() {
        let result = GitHubSyncResult()

        #expect(result.issuesFetched == 0)
        #expect(result.milestonesFetched == 0)
        #expect(result.pullRequestsFetched == 0)
        #expect(result.staleIssuesDetected == 0)
    }

    @Test("custom values")
    func customValues() {
        let result = GitHubSyncResult(
            issuesFetched: 24,
            milestonesFetched: 3,
            pullRequestsFetched: 7,
            staleIssuesDetected: 2
        )

        #expect(result.issuesFetched == 24)
        #expect(result.milestonesFetched == 3)
        #expect(result.pullRequestsFetched == 7)
        #expect(result.staleIssuesDetected == 2)
    }
}
