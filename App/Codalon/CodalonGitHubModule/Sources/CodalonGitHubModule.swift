// Issues #59, #61, #63, #65, #67, #69, #71 — CodalonGitHubModule

import HelaiaEngine
import HelaiaGit
import HelaiaKeychain
import HelaiaLogger

final class CodalonGitHubModule: HelaiaModuleProtocol {
    let moduleID = "codalon.github"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let keychain = try await container.resolve(
            (any KeychainServiceProtocol).self
        )
        let logger = try await container.resolve(
            (any HelaiaLoggerProtocol).self
        )
        let repoRepository = try await container.resolve(
            (any GitHubRepoRepositoryProtocol).self
        )

        let credentialManager = await MainActor.run {
            GitCredentialManager(keychain: keychain, logger: logger)
        }

        let service = await MainActor.run {
            GitHubService(
                credentialManager: credentialManager,
                repoRepository: repoRepository,
                logger: logger
            )
        }

        await container.register(
            (any GitHubServiceProtocol).self,
            scope: .singleton
        ) { service }
    }
}
