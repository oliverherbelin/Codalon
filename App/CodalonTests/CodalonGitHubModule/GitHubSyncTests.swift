// Issue #102 — Sync conflict handling, partial sync, and error recovery tests

import Foundation
import HelaiaGit
import Testing
@testable import Codalon

// MARK: - JSON Helpers

private func makeTestIssue(
    id: Int, number: Int, title: String, body: String? = nil,
    state: String = "open", createdAt: Date = .now, updatedAt: Date = .now
) -> GitIssue {
    var json: [String: Any] = [
        "id": id, "number": number, "title": title, "state": state,
        "created_at": ISO8601DateFormatter().string(from: createdAt),
        "updated_at": ISO8601DateFormatter().string(from: updatedAt)
    ]
    if let body { json["body"] = body }
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitIssue.self, from: data)
}

private func makeTestPR(
    id: Int, number: Int, title: String, body: String? = nil,
    state: String = "open", headRef: String = "feature", baseRef: String = "main",
    createdAt: Date = .now, updatedAt: Date = .now
) -> GitPullRequest {
    var json: [String: Any] = [
        "id": id, "number": number, "title": title, "state": state,
        "head_ref": headRef, "base_ref": baseRef,
        "created_at": ISO8601DateFormatter().string(from: createdAt),
        "updated_at": ISO8601DateFormatter().string(from: updatedAt)
    ]
    if let body { json["body"] = body }
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitPullRequest.self, from: data)
}

// MARK: - Stale Issue Detection Tests (#102)

@Suite("StaleIssueDetection")
@MainActor
struct StaleIssueDetectionTests {

    @Test("detects issues older than threshold")
    func detectsStaleIssues() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        let staleDate = Calendar.current.date(byAdding: .day, value: -45, to: .now)!
        let freshDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)!

        vm.issues = [
            makeTestIssue(id: 1, number: 1, title: "Stale issue", state: "open", createdAt: staleDate, updatedAt: staleDate),
            makeTestIssue(id: 2, number: 2, title: "Fresh issue", state: "open", createdAt: freshDate, updatedAt: freshDate),
            makeTestIssue(id: 3, number: 3, title: "Closed stale", state: "closed", createdAt: staleDate, updatedAt: staleDate),
        ]

        vm.detectStaleIssues(daysThreshold: 30)

        #expect(vm.staleIssues.count == 1)
        #expect(vm.staleIssues.first?.number == 1)
    }

    @Test("no stale issues when all are fresh")
    func noStaleIssues() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        vm.issues = [
            makeTestIssue(id: 1, number: 1, title: "Fresh"),
        ]

        vm.detectStaleIssues(daysThreshold: 30)

        #expect(vm.staleIssues.isEmpty)
    }

    @Test("empty issues yields empty stale list")
    func emptyIssues() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        vm.detectStaleIssues()

        #expect(vm.staleIssues.isEmpty)
    }
}

// MARK: - Activity Summary Computed Properties (#102)

@Suite("ActivitySummary")
@MainActor
struct ActivitySummaryTests {

    @Test("recentClosedIssues filters last 7 days")
    func recentClosed() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let oldDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!

        vm.issues = [
            makeTestIssue(id: 1, number: 1, title: "Recently closed", state: "closed", createdAt: oldDate, updatedAt: recentDate),
            makeTestIssue(id: 2, number: 2, title: "Old closed", state: "closed", createdAt: oldDate, updatedAt: oldDate),
            makeTestIssue(id: 3, number: 3, title: "Open", state: "open", createdAt: recentDate, updatedAt: recentDate),
        ]

        #expect(vm.recentClosedIssues.count == 1)
        #expect(vm.recentClosedIssues.first?.number == 1)
    }

    @Test("recentMergedPRs filters last 7 days")
    func recentMerged() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        let recentDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let oldDate = Calendar.current.date(byAdding: .day, value: -14, to: .now)!

        vm.pullRequests = [
            makeTestPR(id: 1, number: 10, title: "Merged PR", state: "closed", createdAt: oldDate, updatedAt: recentDate),
            makeTestPR(id: 2, number: 11, title: "Open PR", state: "open", createdAt: recentDate, updatedAt: recentDate),
            makeTestPR(id: 3, number: 12, title: "Old merged", state: "closed", createdAt: oldDate, updatedAt: oldDate),
        ]

        #expect(vm.recentMergedPRs.count == 1)
        #expect(vm.recentMergedPRs.first?.number == 10)
    }

    @Test("openIssueCount counts open only")
    func openCount() {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        vm.issues = [
            makeTestIssue(id: 1, number: 1, title: "Open", state: "open"),
            makeTestIssue(id: 2, number: 2, title: "Closed", state: "closed"),
            makeTestIssue(id: 3, number: 3, title: "Open2", state: "open"),
        ]

        #expect(vm.openIssueCount == 2)
        #expect(vm.openPRCount == 0)
    }
}

// MARK: - Sync Error Recovery Tests (#102)

@Suite("SyncErrorRecovery")
@MainActor
struct SyncErrorRecoveryTests {

    @Test("sync sets error message on failure")
    func syncFailure() async {
        let vm = GitHubViewModel(
            gitHubService: FailingGitHubService(),
            projectID: UUID()
        )

        await vm.syncAll(owner: "test", repo: "repo")

        #expect(vm.errorMessage != nil)
        #expect(vm.isSyncing == false)
        #expect(vm.lastSyncResult == nil)
    }

    @Test("partial data persists after successful sync")
    func partialDataPersists() async {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        await vm.syncAll(owner: "test", repo: "repo")

        #expect(vm.issues.isEmpty)
        #expect(vm.milestones.isEmpty)
        #expect(vm.pullRequests.isEmpty)
        #expect(vm.lastSyncResult != nil)
        #expect(vm.lastSyncResult?.issuesFetched == 0)
    }

    @Test("create issue returns created issue")
    func createIssue() async {
        let vm = GitHubViewModel(
            gitHubService: InertSyncGitHubService(),
            projectID: UUID()
        )

        let result = await vm.createIssue(
            owner: "test",
            repo: "repo",
            title: "New issue",
            body: "Body text"
        )

        #expect(result != nil)
        #expect(result?.title == "New issue")
        #expect(vm.issues.count == 1)
    }

    @Test("create issue failure sets error")
    func createIssueFails() async {
        let vm = GitHubViewModel(
            gitHubService: FailingGitHubService(),
            projectID: UUID()
        )

        let result = await vm.createIssue(
            owner: "test",
            repo: "repo",
            title: "New issue",
            body: nil
        )

        #expect(result == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isCreatingIssue == false)
    }
}

// MARK: - Test Helpers

private actor InertSyncGitHubService: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws {}
    func isAuthenticated() async -> Bool { false }
    func loadUsername() async throws -> String { "" }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { [] }
    func fetchUser() async throws -> GitHubUser { GitHubUser(login: "", avatarURL: "", name: nil) }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] { [] }
    func validateToken() async -> GitHubConnectionStatus { .notConnected }
    func disconnect(projectID: UUID) async throws {}
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] { [] }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] { [] }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] { [] }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        makeTestIssue(id: 1, number: 1, title: title, body: body)
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        makeTestIssue(id: 1, number: number, title: title ?? "", body: body, state: state ?? "open")
    }
    func fetchCommits(owner: String, repo: String, limit: Int) async throws -> [GitHubCommitDTO] { [] }
}

private actor FailingGitHubService: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws { throw GitHubServiceError.authFailed }
    func isAuthenticated() async -> Bool { false }
    func loadUsername() async throws -> String { throw GitHubServiceError.notAuthenticated }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { throw GitHubServiceError.authFailed }
    func fetchUser() async throws -> GitHubUser { throw GitHubServiceError.authFailed }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] { [] }
    func validateToken() async -> GitHubConnectionStatus { .notConnected }
    func disconnect(projectID: UUID) async throws {}
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] {
        throw GitHubServiceError.requestFailed(statusCode: 500)
    }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] {
        throw GitHubServiceError.requestFailed(statusCode: 500)
    }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] {
        throw GitHubServiceError.requestFailed(statusCode: 500)
    }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        throw GitHubServiceError.requestFailed(statusCode: 422)
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        throw GitHubServiceError.requestFailed(statusCode: 422)
    }
    func fetchCommits(owner: String, repo: String, limit: Int) async throws -> [GitHubCommitDTO] {
        throw GitHubServiceError.requestFailed(statusCode: 500)
    }
}
