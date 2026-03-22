// Issue #279 — Local repo resolution for active project

import Foundation
import HelaiaEngine
import HelaiaGit
import HelaiaLogger

/// Result of resolving a local repo — includes the security-scoped URL
/// so the caller can manage the access lifetime.
struct ResolvedRepo: Sendable {
    let repository: GitRepository
    let scopedURL: URL
}

actor LocalRepoResolver {

    private let container: ServiceContainer

    init(container: ServiceContainer = .shared) {
        self.container = container
    }

    func resolve(projectID: UUID) async -> ResolvedRepo? {
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )

        do {
            let repoPathRepo = try await container.resolve(
                (any GitLocalRepoPathRepositoryProtocol).self
            )
            guard let localPath = try await repoPathRepo.fetchByProject(projectID) else {
                logger?.warning("No GitLocalRepoPath for project \(projectID)", category: "local-git")
                return nil
            }
            logger?.info("Found GitLocalRepoPath: displayPath=\(localPath.displayPath)", category: "local-git")

            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: localPath.bookmarkData,
                options: [.withSecurityScope],
                bookmarkDataIsStale: &isStale
            ) else {
                logger?.error("Bookmark resolution failed for \(localPath.displayPath)", category: "local-git")
                return nil
            }
            logger?.info("Bookmark resolved: \(url.path), isStale=\(isStale)", category: "local-git")

            let accessGranted = url.startAccessingSecurityScopedResource()
            logger?.info("startAccessingSecurityScopedResource = \(accessGranted)", category: "local-git")
            guard accessGranted else { return nil }

            let gitService = try await container.resolve(
                (any GitServiceProtocol).self
            )

            do {
                let repository = try await gitService.open(at: url)
                logger?.info("gitService.open() succeeded: \(url.path)", category: "local-git")
                return ResolvedRepo(repository: repository, scopedURL: url)
            } catch {
                logger?.error("gitService.open() failed: \(error.localizedDescription)", category: "local-git")
                url.stopAccessingSecurityScopedResource()
                return nil
            }
        } catch {
            logger?.error("resolve() error: \(error.localizedDescription)", category: "local-git")
            return nil
        }
    }
}
