// Issues #59, #63, #65, #67, #69, #73, #75, #83, #85, #87, #89, #91, #93, #95, #99, #100 — GitHub view model

import Foundation
import SwiftUI
import HelaiaEngine
import HelaiaGit

// MARK: - GitHubViewModel

@Observable
final class GitHubViewModel {

    // MARK: - State

    var isAuthenticated = false
    var username = ""
    var avatarURL = ""
    var repositories: [GitHubRepo] = []
    var linkedRepos: [CodalonGitHubRepo] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""
    var currentPage = 1
    var connectionStatus: GitHubConnectionStatus = .notConnected
    var showReconnectPrompt = false

    // Issue #83, #85, #87 — Remote data
    var issues: [GitIssue] = []
    var milestones: [GitHubMilestoneDTO] = []
    var pullRequests: [GitPullRequest] = []

    // Issue #99 — Stale issues
    var staleIssues: [GitIssue] = []

    // Issue #100 — Sync
    var isSyncing = false
    var lastSyncResult: GitHubSyncResult?

    // Issue #89 — Create issue
    var isCreatingIssue = false

    // MARK: - Dependencies

    private let gitHubService: any GitHubServiceProtocol
    let projectID: UUID

    // MARK: - Init

    init(gitHubService: any GitHubServiceProtocol, projectID: UUID) {
        self.gitHubService = gitHubService
        self.projectID = projectID
    }

    // MARK: - Auth

    func checkAuth() async {
        isAuthenticated = await gitHubService.isAuthenticated()
        if isAuthenticated {
            do {
                username = try await gitHubService.loadUsername()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func authenticate(token: String, username: String) async {
        isLoading = true
        do {
            try await gitHubService.authenticate(token: token, username: username)
            isAuthenticated = true
            self.username = username
            await fetchUser()
            await loadRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func removeAuth() async {
        do {
            try await gitHubService.removeAuth()
            isAuthenticated = false
            username = ""
            avatarURL = ""
            repositories = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #63 — Fetch User

    func fetchUser() async {
        do {
            let user = try await gitHubService.fetchUser()
            username = user.login
            avatarURL = user.avatarURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #65 — Fetch Repos

    func loadRepositories() async {
        isLoading = true
        do {
            repositories = try await gitHubService.fetchRepositories(page: currentPage)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadNextPage() async {
        currentPage += 1
        do {
            let nextRepos = try await gitHubService.fetchRepositories(page: currentPage)
            repositories.append(contentsOf: nextRepos)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #69 — Link Repo

    func linkRepo(_ repo: GitHubRepo) async {
        let parts = repo.fullName.split(separator: "/")
        guard parts.count == 2 else { return }

        let codalonRepo = CodalonGitHubRepo(
            projectID: projectID,
            owner: String(parts[0]),
            name: String(parts[1]),
            fullName: repo.fullName,
            isPrivate: repo.isPrivate,
            defaultBranch: repo.defaultBranch
        )

        do {
            try await gitHubService.linkRepo(codalonRepo)
            await loadLinkedRepos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unlinkRepo(id: UUID) async {
        do {
            try await gitHubService.unlinkRepo(id: id)
            await loadLinkedRepos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadLinkedRepos() async {
        do {
            linkedRepos = try await gitHubService.linkedRepos(projectID: projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered

    var filteredRepositories: [GitHubRepo] {
        guard !searchQuery.isEmpty else { return repositories }
        let query = searchQuery.lowercased()
        return repositories.filter {
            $0.name.lowercased().contains(query)
                || $0.fullName.lowercased().contains(query)
                || ($0.description?.lowercased().contains(query) ?? false)
        }
    }

    var isRepoLinked: (GitHubRepo) -> Bool {
        { [linkedRepos] repo in
            linkedRepos.contains { $0.fullName == repo.fullName && $0.deletedAt == nil }
        }
    }

    // MARK: - Issue #73 — Reconnect Flow

    func validateConnection() async {
        connectionStatus = await gitHubService.validateToken()

        switch connectionStatus {
        case .connected(let user):
            isAuthenticated = true
            username = user
            showReconnectPrompt = false
        case .tokenExpired:
            isAuthenticated = false
            showReconnectPrompt = true
        case .notConnected:
            isAuthenticated = false
            showReconnectPrompt = false
        case .error:
            isAuthenticated = false
            showReconnectPrompt = false
        }
    }

    func reconnect(token: String, username: String) async {
        isLoading = true
        do {
            try await gitHubService.authenticate(token: token, username: username)
            isAuthenticated = true
            self.username = username
            showReconnectPrompt = false
            connectionStatus = .connected(username: username)
            await fetchUser()
            await loadRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #75 — Disconnect Flow

    func disconnect() async {
        isLoading = true
        do {
            try await gitHubService.disconnect(projectID: projectID)
            isAuthenticated = false
            username = ""
            avatarURL = ""
            repositories = []
            linkedRepos = []
            issues = []
            milestones = []
            pullRequests = []
            staleIssues = []
            connectionStatus = .notConnected
            showReconnectPrompt = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #83 — Fetch Issues

    func loadIssues(owner: String, repo: String, state: String = "open") async {
        do {
            issues = try await gitHubService.fetchIssues(owner: owner, repo: repo, state: state)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #85 — Fetch Milestones

    func loadMilestones(owner: String, repo: String) async {
        do {
            milestones = try await gitHubService.fetchMilestones(owner: owner, repo: repo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #87 — Fetch Pull Requests

    func loadPullRequests(owner: String, repo: String, state: String = "open") async {
        do {
            pullRequests = try await gitHubService.fetchPullRequests(owner: owner, repo: repo, state: state)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #89 — Create Issue

    func createIssue(owner: String, repo: String, title: String, body: String?) async -> GitIssue? {
        isCreatingIssue = true
        defer { isCreatingIssue = false }
        do {
            let issue = try await gitHubService.createIssue(owner: owner, repo: repo, title: title, body: body)
            issues.insert(issue, at: 0)
            return issue
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Issue #91 — Update Issue

    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async {
        do {
            let updated = try await gitHubService.updateIssue(
                owner: owner, repo: repo, number: number,
                title: title, body: body, state: state
            )
            if let index = issues.firstIndex(where: { $0.number == number }) {
                issues[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #99 — Stale Issue Detection

    func detectStaleIssues(daysThreshold: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysThreshold, to: .now) ?? .now
        staleIssues = issues.filter { $0.state == "open" && $0.updatedAt < cutoffDate }
    }

    // MARK: - Issue #100 — Sync All

    func syncAll(owner: String, repo: String) async {
        isSyncing = true
        defer { isSyncing = false }

        async let fetchedIssues = gitHubService.fetchIssues(owner: owner, repo: repo, state: "all")
        async let fetchedMilestones = gitHubService.fetchMilestones(owner: owner, repo: repo)
        async let fetchedPRs = gitHubService.fetchPullRequests(owner: owner, repo: repo, state: "all")

        do {
            issues = try await fetchedIssues
            milestones = try await fetchedMilestones
            pullRequests = try await fetchedPRs
            detectStaleIssues()

            lastSyncResult = GitHubSyncResult(
                issuesFetched: issues.count,
                milestonesFetched: milestones.count,
                pullRequestsFetched: pullRequests.count,
                staleIssuesDetected: staleIssues.count
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed — Activity Summary (#98)

    var recentClosedIssues: [GitIssue] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return issues.filter { $0.state == "closed" && $0.updatedAt >= sevenDaysAgo }
    }

    var recentMergedPRs: [GitPullRequest] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return pullRequests.filter { $0.state == "closed" && $0.updatedAt >= sevenDaysAgo }
    }

    var openIssueCount: Int {
        issues.filter { $0.state == "open" }.count
    }

    var openPRCount: Int {
        pullRequests.filter { $0.state == "open" }.count
    }
}