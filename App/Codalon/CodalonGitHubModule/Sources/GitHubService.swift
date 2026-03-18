// Issues #59, #61, #63, #65, #69, #71, #73, #75, #79 — GitHub service

import Foundation
import HelaiaEngine
import HelaiaGit
import HelaiaKeychain
import HelaiaLogger

// MARK: - Protocol

public protocol GitHubServiceProtocol: Sendable {
    func authenticate(token: String, username: String) async throws
    func isAuthenticated() async -> Bool
    func loadUsername() async throws -> String
    func removeAuth() async throws
    func fetchRepositories(page: Int) async throws -> [GitHubRepo]
    func fetchUser() async throws -> GitHubUser
    func linkRepo(_ repo: CodalonGitHubRepo) async throws
    func unlinkRepo(id: UUID) async throws
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo]
    func validateToken() async -> GitHubConnectionStatus
    func disconnect(projectID: UUID) async throws
}

// MARK: - GitHubConnectionStatus

public enum GitHubConnectionStatus: Sendable, Equatable {
    case connected(username: String)
    case tokenExpired
    case notConnected
    case error(String)
}

// MARK: - GitHubUser

nonisolated public struct GitHubUser: Codable, Sendable, Equatable {
    public let login: String
    public let avatarURL: String
    public let name: String?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case name
    }
}

// MARK: - Implementation

public actor GitHubService: GitHubServiceProtocol {

    private let credentialManager: GitCredentialManager
    private let repoRepository: any GitHubRepoRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        credentialManager: GitCredentialManager,
        repoRepository: any GitHubRepoRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.credentialManager = credentialManager
        self.repoRepository = repoRepository
        self.logger = logger
    }

    // MARK: - Issue #59 — Auth Flow

    public func authenticate(token: String, username: String) async throws {
        logger.info("Authenticating GitHub user: \(username)", category: "github")
        do {
            try await credentialManager.saveCredential(
                token: token,
                for: .github,
                username: username
            )
            await publish(GitHubAuthenticatedEvent(username: username))
            logger.success("GitHub authentication succeeded for \(username)", category: "github")
        } catch {
            logger.error("GitHub authentication failed: \(error.localizedDescription)", category: "github")
            throw error
        }
    }

    // MARK: - Issue #61 — Credential Check

    public func isAuthenticated() async -> Bool {
        await credentialManager.hasCredential(for: .github)
    }

    public func loadUsername() async throws -> String {
        try await credentialManager.loadUsername(for: .github)
    }

    public func removeAuth() async throws {
        logger.info("Removing GitHub authentication", category: "github")
        do {
            try await credentialManager.removeCredential(for: .github)
            await publish(GitHubAuthRemovedEvent())
            logger.success("GitHub credentials removed", category: "github")
        } catch {
            logger.error("Failed to remove GitHub credentials: \(error.localizedDescription)", category: "github")
            throw error
        }
    }

    // MARK: - Issue #63 — Fetch User

    public func fetchUser() async throws -> GitHubUser {
        let token = try await credentialManager.loadCredential(for: .github)
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("GitHub fetchUser failed with status \(statusCode)", category: "github")
            throw GitHubServiceError.authFailed
        }

        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    // MARK: - Issue #65 — Fetch Repos

    public func fetchRepositories(page: Int) async throws -> [GitHubRepo] {
        logger.info("Fetching GitHub repositories (page \(page))", category: "github")
        do {
            let token = try await credentialManager.loadCredential(for: .github)
            let provider = GitHubProvider(token: token, logger: logger)
            let repos = try await provider.repositories(page: page)
            logger.info("Fetched \(repos.count) repositories", category: "github")
            return repos
        } catch {
            logger.error("Failed to fetch repositories: \(error.localizedDescription)", category: "github")
            throw error
        }
    }

    // MARK: - Issue #69 — Link Repo

    public func linkRepo(_ repo: CodalonGitHubRepo) async throws {
        logger.info("Linking repository: \(repo.fullName)", category: "github")
        do {
            try await repoRepository.save(repo)
            await publish(GitHubRepoLinkedEvent(
                projectID: repo.projectID,
                repoFullName: repo.fullName
            ))
            logger.success("Repository linked: \(repo.fullName)", category: "github")
        } catch {
            logger.error("Failed to link repository \(repo.fullName): \(error.localizedDescription)", category: "github")
            throw error
        }
    }

    public func unlinkRepo(id: UUID) async throws {
        logger.info("Unlinking repository \(id.uuidString)", category: "github")
        do {
            try await repoRepository.delete(id: id)
            logger.success("Repository unlinked: \(id.uuidString)", category: "github")
        } catch {
            logger.error("Failed to unlink repository: \(error.localizedDescription)", category: "github")
            throw error
        }
    }

    public func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] {
        try await repoRepository.fetchByProject(projectID)
    }

    // MARK: - Issue #73 — Validate Token (Reconnect)

    public func validateToken() async -> GitHubConnectionStatus {
        logger.info("Validating GitHub token", category: "github")

        guard await credentialManager.hasCredential(for: .github) else {
            logger.info("No GitHub credential found", category: "github")
            return .notConnected
        }

        do {
            let user = try await fetchUser()
            logger.success("GitHub token valid for user: \(user.login)", category: "github")
            return .connected(username: user.login)
        } catch let error as GitHubServiceError where error == .authFailed {
            logger.warning("GitHub token expired or revoked", category: "github")
            return .tokenExpired
        } catch {
            logger.error("GitHub token validation failed: \(error.localizedDescription)", category: "github")
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Issue #75 — Disconnect

    public func disconnect(projectID: UUID) async throws {
        logger.info("Disconnecting GitHub for project \(projectID.uuidString)", category: "github")

        // Unlink all repos for this project
        let repos = try await repoRepository.fetchByProject(projectID)
        for repo in repos where repo.deletedAt == nil {
            try await repoRepository.delete(id: repo.id)
        }
        logger.info("Unlinked \(repos.count) repositories", category: "github")

        // Remove credentials
        try await removeAuth()
        logger.success("GitHub fully disconnected for project \(projectID.uuidString)", category: "github")
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}

// MARK: - Error

public enum GitHubServiceError: Error, Sendable, Equatable {
    case authFailed
    case notAuthenticated
}