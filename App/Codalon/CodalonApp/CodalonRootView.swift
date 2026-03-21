// Issue #8 — Root window shell (Root Shell Spec v1.0)

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaGit
import HelaiaLogger

struct CodalonRootView: View {

    @Environment(HelaiaAppState.self) private var appState
    @Environment(CodalonShellState.self) private var shellState
    @Environment(AppearanceState.self) private var appearance
    @Environment(\.colorScheme) private var systemColorScheme

    private var hasProject: Bool {
        shellState.selectedProjectID != nil
    }

    private var effectiveColorScheme: ColorScheme {
        appearance.colorScheme ?? systemColorScheme
    }

    var body: some View {
        ZStack {
            // Layer 0 — Ambient: context-reactive background
            AmbientLayer()

            if hasProject {
                // Layer 1 — Canvas: primary working surface
                if !appState.isLaunching {
                    DashboardView()
                }

                // Layer 2 — Overlay: popovers, inspector, sheets (stub)
                Color.clear

                // Layer 3 — HUD: persistent anchor strip
                VStack {
                    Spacer()
                    CodalonHUDStrip()
                }

                // Layer 4 — Proposal: context-change proposal pill (stub)
                Color.clear
            } else if !appState.isLaunching {
                // Onboarding — inline card, no HUD, no menus
                OnboardingView { project, context, localURL, sideEffects in
                    Task {
                        await performProjectCreation(
                            project: project,
                            context: context,
                            localURL: localURL,
                            sideEffects: sideEffects
                        )
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { shellState.isProjectSwitcherVisible },
            set: { shellState.isProjectSwitcherVisible = $0 }
        )) {
            ProjectSwitcherSheet()
                .environment(shellState)
        }
        .frame(minWidth: 1200, minHeight: 760)
        .helaiaDesignTokens(
            HelaiaDesignTokens(
                theme: appearance.accentTheme,
                themeMode: appearance.themeMode,
                themeConfig: appearance.themeConfig(for: effectiveColorScheme)
            )
        )
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.colorScheme, effectiveColorScheme)
        .environment(\.projectContext, shellState.activeContext)
        .environment(\.healthState, shellState.healthState)
        .environment(\.activeMilestoneID, shellState.activeMilestoneID)
        .environment(\.activeReleaseID, shellState.activeReleaseID)
        .environment(\.activeDistributionTargets, shellState.activeDistributionTargets)
    }

    // MARK: - Project Creation (#269, #276)

    private func performProjectCreation(
        project: CodalonProject,
        context: CodalonContext,
        localURL: URL?,
        sideEffects: ProjectCreationSideEffects
    ) async {
        let container = ServiceContainer.shared
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )

        // 1. Save project
        if let projectService = await container.resolveOptional(
            (any ProjectServiceProtocol).self
        ) {
            try? await projectService.create(project)
        }
        if let selectionService = await container.resolveOptional(
            (any ProjectSelectionServiceProtocol).self
        ) {
            await selectionService.select(project.id)
        }

        // 2. Link GitHub repos
        if !project.linkedGitHubRepos.isEmpty,
           let gitHubService = await container.resolveOptional(
               (any GitHubServiceProtocol).self
           ) {
            for repoFullName in project.linkedGitHubRepos {
                let parts = repoFullName.split(separator: "/")
                guard parts.count == 2 else { continue }
                let linkedRepo = CodalonGitHubRepo(
                    projectID: project.id,
                    owner: String(parts[0]),
                    name: String(parts[1]),
                    fullName: repoFullName
                )
                do {
                    try await gitHubService.linkRepo(linkedRepo)
                    logger?.success(
                        "Linked repo \(repoFullName) to project \(project.id)",
                        category: "project-creation"
                    )
                } catch {
                    logger?.error(
                        "Failed to link repo \(repoFullName): \(error)",
                        category: "project-creation"
                    )
                }
            }
        }

        // 3. Execute side effects (#276)
        await executeSideEffects(
            sideEffects,
            project: project,
            localURL: localURL,
            logger: logger
        )

        // 4. Persist local folder bookmark (#272)
        if let url = localURL {
            await persistBookmark(for: url, projectID: project.id, logger: logger)
        }

        // 5. Reveal dashboard
        shellState.selectedProjectID = project.id
        shellState.projectName = project.name
        shellState.projectIcon = project.icon
        shellState.projectColor = project.color
        shellState.activeContext = context
    }

    private func executeSideEffects(
        _ sideEffects: ProjectCreationSideEffects,
        project: CodalonProject,
        localURL: URL?,
        logger: (any HelaiaLoggerProtocol)?
    ) async {
        let container = ServiceContainer.shared

        // Create folder
        if sideEffects.shouldCreateFolder, let url = localURL {
            do {
                try FileManager.default.createDirectory(
                    at: url, withIntermediateDirectories: true
                )
                logger?.info("Created folder at \(url.path)", category: "project-creation")
            } catch {
                logger?.error("Failed to create folder: \(error)", category: "project-creation")
            }
        }

        // Git init
        if sideEffects.shouldGitInit, let url = localURL {
            do {
                let gitService = try await container.resolve(
                    (any GitServiceProtocol).self
                )
                try await gitService.initialize(at: url)
                logger?.info("Initialized git at \(url.path)", category: "project-creation")
            } catch {
                logger?.error("Failed to git init: \(error)", category: "project-creation")
            }
        }

        // Clone
        if sideEffects.shouldClone, let remoteURL = sideEffects.cloneRemoteURL, let url = localURL {
            do {
                let gitService = try await container.resolve(
                    (any GitServiceProtocol).self
                )
                try await gitService.clone(remote: remoteURL, to: url)
                logger?.info(
                    "Cloned \(remoteURL) to \(url.path)",
                    category: "project-creation"
                )
            } catch {
                logger?.error("Failed to clone: \(error)", category: "project-creation")
            }
        }

        // Create GitHub repo — requires GitHubService.createRepository (Epic 25)
        if sideEffects.shouldCreateGitHubRepo, let repoName = sideEffects.newRepoName {
            logger?.warning(
                "GitHub repo creation requested (\(repoName)) — not yet implemented",
                category: "project-creation"
            )
        }
    }

    // MARK: - Bookmark Persistence (#272)

    private func persistBookmark(
        for url: URL,
        projectID: UUID,
        logger: (any HelaiaLoggerProtocol)?
    ) async {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let repoPath = GitLocalRepoPath(
                projectID: projectID,
                bookmarkData: bookmarkData,
                displayPath: url.path
            )

            let container = ServiceContainer.shared
            let repo = try await container.resolve(
                (any GitLocalRepoPathRepositoryProtocol).self
            )
            try await repo.save(repoPath)
            logger?.info(
                "Persisted bookmark for \(url.path)",
                category: "project-creation"
            )
        } catch {
            logger?.error(
                "Failed to persist bookmark: \(error)",
                category: "project-creation"
            )
        }
    }
}

#Preview("Root — With Project") {
    let shell = CodalonShellState()
    shell.selectedProjectID = UUID()
    shell.projectName = "My App"
    return CodalonRootView()
        .environment(HelaiaAppState())
        .environment(shell)
        .environment(AppearanceState())
        .helaiaDesignTokens(HelaiaDesignTokens(theme: .codalonDevelopment, themeMode: .system))
}

#Preview("Root — Onboarding") {
    CodalonRootView()
        .environment(HelaiaAppState())
        .environment(CodalonShellState())
        .environment(AppearanceState())
        .helaiaDesignTokens(HelaiaDesignTokens(theme: .codalonDevelopment, themeMode: .system))
}
