// Issues #8, #256 — Root window shell with HelaiaEngine bootstrap + crash reporting

import SwiftUI
import HelaiaEngine
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

        // Debug: check CodalonGitHubRepo records in the database
        if let repoRepository = await container.resolveOptional(
            (any GitHubRepoRepositoryProtocol).self
        ) {
            do {
                let allRepos = try await repoRepository.loadAll()
                logger?.info(
                    "restoreShellState: total CodalonGitHubRepo records in DB = \(allRepos.count)",
                    category: "boot"
                )
                let projectRepos = try await repoRepository.fetchByProject(projectID)
                logger?.info(
                    "restoreShellState: linked repos for project \(projectID) = \(projectRepos.count)"
                        + (projectRepos.isEmpty ? "" : " — \(projectRepos.map(\.fullName))"),
                    category: "boot"
                )
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
}
