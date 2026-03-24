// Issues #8, #256 — Root window shell with HelaiaEngine bootstrap + crash reporting

import SwiftUI
import HelaiaEngine
import HelaiaGit
import HelaiaLogger

@main
struct CodalonApp: App {

    @State private var appState = HelaiaAppState()
    @State private var shellState = CodalonShellState()
    @State private var appearance = AppearanceState()
    var body: some Scene {
        WindowGroup {
            CodalonRootView()
                .environment(appState)
                .environment(shellState)
                .environment(appearance)
                .task { await bootstrap() }
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentMinSize)
        .commands {
            CodalonMenuCommands(shellState: shellState)
        }

        Settings {
            SettingsView()
                .environment(appearance)
        }
    }

    private func bootstrap() async {
        // Issue #256 — Wire crash reporting
        let logDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("Codalon/Logs", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: logDirectory,
            withIntermediateDirectories: true
        )

        let crashReporter = CodalonCrashReporter(logDirectory: logDirectory)

        let registry = ModuleRegistry.shared
        let container = ServiceContainer.shared

        let modules: [any HelaiaModuleProtocol] = [
            CodalonCoreModule(),
            CodalonProjectModule(),
            CodalonPlanningModule(),
            CodalonGitHubModule(),
            CodalonAppStoreModule(),
            CodalonReleaseModule(),
            CodalonInsightModule(),
            CodalonNotificationModule(),
            CodalonDashboardModule(),
            CodalonSettingsModule()
        ]

        for module in modules {
            registry.register(module)
        }

        for module in modules {
            do {
                try await module.register(in: container)
            } catch {
                await crashReporter.capture(error, context: [
                    "module": String(describing: type(of: module)),
                    "phase": "register",
                ])
            }
        }

        for module in modules {
            await module.onLaunch()
        }

        // Restore last active project into shell state
        await restoreShellState(container: container)

        await crashReporter.addBreadcrumb(
            "App bootstrap complete, \(modules.count) modules registered",
            category: "lifecycle"
        )

        EventBus.shared.publish(AppLaunchedEvent())
        appState.isLaunching = false
    }

    private func restoreShellState(container: ServiceContainer) async {
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )

        // Restore selected project ID and name
        guard let selectionService = await container.resolveOptional(
            (any ProjectSelectionServiceProtocol).self
        ) else { return }

        guard let projectID = await selectionService.selectedProjectID() else { return }
        shellState.selectedProjectID = projectID
        logger?.info("restoreShellState: restored projectID = \(projectID)", category: "boot")

        // Load the project name for the HUD strip
        guard let projectService = await container.resolveOptional(
            (any ProjectServiceProtocol).self
        ) else { return }

        do {
            let project = try await projectService.load(id: projectID)
            shellState.projectName = project.name
            shellState.projectIcon = project.icon
            shellState.projectColor = project.color
            logger?.info(
                "restoreShellState: project '\(project.name)' linkedGitHubRepos = \(project.linkedGitHubRepos)",
                category: "boot"
            )
        } catch {
            logger?.error("restoreShellState: failed to load project \(projectID): \(error)", category: "boot")
        }

        // Check linked repos — auto-link from local repo remote if needed
        if let repoRepository = await container.resolveOptional(
            (any GitHubRepoRepositoryProtocol).self
        ) {
            do {
                let projectRepos = try await repoRepository.fetchByProject(projectID)
                logger?.info(
                    "restoreShellState: linked repos for project \(projectID) = \(projectRepos.count)"
                        + (projectRepos.isEmpty ? "" : " — \(projectRepos.map(\.fullName))"),
                    category: "boot"
                )

                if projectRepos.isEmpty {
                    await autoLinkGitHubRepo(
                        projectID: projectID,
                        container: container,
                        logger: logger
                    )
                }
            } catch {
                logger?.error(
                    "restoreShellState: failed to query GitHub repos: \(error)",
                    category: "boot"
                )
            }
        } else {
            logger?.warning("restoreShellState: GitHubRepoRepositoryProtocol not registered", category: "boot")
        }
    }

    // MARK: - Auto-Link GitHub Repo

    private func autoLinkGitHubRepo(
        projectID: UUID,
        container: ServiceContainer,
        logger: (any HelaiaLoggerProtocol)?
    ) async {
        guard let pathRepo = await container.resolveOptional(
            (any GitLocalRepoPathRepositoryProtocol).self
        ) else { return }

        guard let localPath = try? await pathRepo.fetchByProject(projectID) else {
            logger?.info("autoLink: no GitLocalRepoPath for project", category: "boot")
            return
        }

        guard let gitHubService = await container.resolveOptional(
            (any GitHubServiceProtocol).self
        ), await gitHubService.isAuthenticated() else {
            logger?.info("autoLink: GitHub not connected", category: "boot")
            return
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: localPath.bookmarkData,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        ) else {
            logger?.error("autoLink: bookmark resolution failed", category: "boot")
            return
        }

        guard url.startAccessingSecurityScopedResource() else {
            logger?.error("autoLink: security scope access denied", category: "boot")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let gitService = await container.resolveOptional(
            (any GitServiceProtocol).self
        ) else { return }

        do {
            let repo = try await gitService.open(at: url)
            guard let remoteURL = repo.remoteURL else {
                logger?.info("autoLink: repo has no remote URL", category: "boot")
                return
            }

            guard let (owner, repoName) = Self.parseGitHubOwnerRepo(from: remoteURL) else {
                logger?.info("autoLink: remote is not GitHub: \(remoteURL)", category: "boot")
                return
            }

            let linked = CodalonGitHubRepo(
                projectID: projectID,
                owner: owner,
                name: repoName,
                defaultBranch: repo.defaultBranch
            )
            try await gitHubService.linkRepo(linked)
            logger?.success(
                "autoLink: linked \(owner)/\(repoName) to project \(projectID)",
                category: "boot"
            )
        } catch {
            logger?.error("autoLink: failed — \(error)", category: "boot")
        }
    }

    static func parseGitHubOwnerRepo(from url: URL) -> (owner: String, repo: String)? {
        let str = url.absoluteString

        // SSH: git@github.com:owner/repo.git
        if str.hasPrefix("git@github.com:") {
            let path = String(str.dropFirst("git@github.com:".count))
            let cleaned = path.hasSuffix(".git") ? String(path.dropLast(4)) : path
            let parts = cleaned.split(separator: "/")
            guard parts.count == 2 else { return nil }
            return (String(parts[0]), String(parts[1]))
        }

        // HTTPS: https://github.com/owner/repo.git
        if str.contains("github.com") {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard pathComponents.count >= 2 else { return nil }
            let owner = pathComponents[0]
            var repo = pathComponents[1]
            if repo.hasSuffix(".git") { repo = String(repo.dropLast(4)) }
            return (owner, repo)
        }

        return nil
    }
}
