// Issues #59, #63, #65, #67, #69, #73, #75 — GitHub view model

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

    // MARK: - Dependencies

    private let gitHubService: any GitHubServiceProtocol
    private let projectID: UUID

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
            connectionStatus = .notConnected
            showReconnectPrompt = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}