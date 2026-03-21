// Issues #270, #271 — Project Switcher Sheet (Project Switcher Sheet Spec v1.0)

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaGit
import HelaiaLogger

// MARK: - ProjectSwitcherSheet

struct ProjectSwitcherSheet: View {

    @Environment(CodalonShellState.self) private var shellState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var projects: [CodalonProject] = []
    @State private var recentIDs: [UUID] = []
    @State private var searchText = ""
    @State private var showNewProject = false
    @State private var gitHubConnected = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            if showNewProject {
                // Inline creation flow (#271)
                ProjectCreationFlow(
                    gitHubConnected: gitHubConnected,
                    onBack: {
                        withAnimation(ComponentAnimation.Card.press) {
                            showNewProject = false
                        }
                    },
                    onComplete: { project, url, sideEffects in
                        createAndSwitch(project: project, localURL: url, sideEffects: sideEffects)
                    }
                )
                .padding(Spacing._6)
                .transition(.opacity.combined(with: .offset(y: Spacing._2)))
            } else {
                // Search bar
                searchBar
                    .padding(.horizontal, Spacing._4)
                    .padding(.top, Spacing._3)

                // Project list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !recentProjects.isEmpty, searchText.isEmpty {
                            sectionHeader("Recent")
                            ForEach(recentProjects) { project in
                                projectRow(project)
                            }
                        }

                        sectionHeader(searchText.isEmpty ? "All Projects" : "Results")
                        ForEach(filteredProjects) { project in
                            projectRow(project)
                        }

                        if filteredProjects.isEmpty {
                            emptyState
                        }
                    }
                    .padding(.bottom, Spacing._4)
                }

                Divider()

                // New project button
                HStack {
                    HelaiaButton(
                        "New Project",
                        icon: "plus",
                        variant: .secondary,
                        fullWidth: false
                    ) {
                        withAnimation(ComponentAnimation.Card.press) {
                            showNewProject = true
                        }
                    }

                    Spacer()
                }
                .padding(Spacing._4)
            }
        }
        .frame(minWidth: 480, maxWidth: 480, minHeight: 400, maxHeight: 600)
        .task { await loadProjects() }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack {
            Text("Switch Project")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Spacer()

            Button {
                dismiss()
            } label: {
                HelaiaIconView(
                    "xmark",
                    size: .xs,
                    weight: .semibold,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing._4)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Search

    @ViewBuilder
    private var searchBar: some View {
        HelaiaTextField(
            title: "",
            text: $searchText,
            placeholder: "Search projects"
        )
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .helaiaFont(.tag)
            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing._4)
            .padding(.top, Spacing._3)
            .padding(.bottom, Spacing._1)
    }

    // MARK: - Project Row

    @ViewBuilder
    private func projectRow(_ project: CodalonProject) -> some View {
        let isActive = project.id == shellState.selectedProjectID

        Button {
            switchTo(project)
        } label: {
            HStack(spacing: Spacing._2) {
                HelaiaIconView(
                    project.icon,
                    size: .custom(20),
                    color: Color(hex: project.color)
                        ?? SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._px) {
                    Text(project.name)
                        .helaiaFont(.bodyEmphasized)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                    if !project.linkedGitHubRepos.isEmpty {
                        Text(project.linkedGitHubRepos.first ?? "")
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isActive {
                    HelaiaCapsule.filter(
                        "Active",
                        icon: .sfSymbol("checkmark"),
                        isSelected: true
                    ) {}
                }
            }
            .padding(.horizontal, Spacing._4)
            .padding(.vertical, Spacing._2)
            .background {
                if isActive {
                    SemanticColor.surface(for: colorScheme)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(project.name)\(isActive ? ", active project" : "")"
        )
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Spacing._2) {
            HelaiaIconView(
                "magnifyingglass",
                size: .xl,
                color: SemanticColor.textTertiary(for: colorScheme)
            )
            Text("No projects found")
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing._8)
    }

    // MARK: - Data

    private var filteredProjects: [CodalonProject] {
        if searchText.isEmpty { return projects }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.slug.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentProjects: [CodalonProject] {
        recentIDs.compactMap { id in
            projects.first { $0.id == id }
        }
    }

    private func loadProjects() async {
        do {
            let container = ServiceContainer.shared
            let projectService = try await container.resolve(
                (any ProjectServiceProtocol).self
            )
            let all = try await projectService.loadActive()
            await MainActor.run {
                projects = all
            }

            if let recentService = await container.resolveOptional(
                (any RecentProjectsServiceProtocol).self
            ) {
                let ids = await recentService.recentProjectIDs()
                await MainActor.run {
                    recentIDs = ids
                }
            }

            if let gitHubService = await container.resolveOptional(
                (any GitHubServiceProtocol).self
            ) {
                let connected = await gitHubService.isAuthenticated()
                await MainActor.run {
                    gitHubConnected = connected
                }
            }
        } catch {
            // Fail silently — sheet still usable
        }
    }

    // MARK: - Actions

    private func switchTo(_ project: CodalonProject) {
        Task {
            let container = ServiceContainer.shared
            if let selectionService = await container.resolveOptional(
                (any ProjectSelectionServiceProtocol).self
            ) {
                await selectionService.select(project.id)
            }
            if let recentService = await container.resolveOptional(
                (any RecentProjectsServiceProtocol).self
            ) {
                await recentService.recordAccess(project.id)
            }

            shellState.selectedProjectID = project.id
            shellState.projectName = project.name
            shellState.projectIcon = project.icon
            shellState.projectColor = project.color

            dismiss()
        }
    }

    private func createAndSwitch(
        project: CodalonProject,
        localURL: URL?,
        sideEffects: ProjectCreationSideEffects
    ) {
        Task {
            let container = ServiceContainer.shared
            let logger = await container.resolveOptional(
                (any HelaiaLoggerProtocol).self
            )

            // Save project
            if let projectService = await container.resolveOptional(
                (any ProjectServiceProtocol).self
            ) {
                try? await projectService.create(project)
            }

            // Link repos
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
                    try? await gitHubService.linkRepo(linkedRepo)
                }
            }

            // Side effects — folder, git init, clone
            if sideEffects.shouldCreateFolder, let url = localURL {
                try? FileManager.default.createDirectory(
                    at: url, withIntermediateDirectories: true
                )
            }

            if sideEffects.shouldGitInit, let url = localURL {
                if let gitService = await container.resolveOptional(
                    (any GitServiceProtocol).self
                ) {
                    try? await gitService.initialize(at: url)
                }
            }

            if sideEffects.shouldClone,
               let remoteURL = sideEffects.cloneRemoteURL,
               let url = localURL {
                if let gitService = await container.resolveOptional(
                    (any GitServiceProtocol).self
                ) {
                    try? await gitService.clone(remote: remoteURL, to: url)
                }
            }

            // Bookmark
            if let url = localURL {
                do {
                    let bookmarkData = try url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    let repoPath = GitLocalRepoPath(
                        projectID: project.id,
                        bookmarkData: bookmarkData,
                        displayPath: url.path
                    )
                    let repo = try await container.resolve(
                        (any GitLocalRepoPathRepositoryProtocol).self
                    )
                    try await repo.save(repoPath)
                } catch {
                    logger?.error(
                        "Failed to persist bookmark: \(error)",
                        category: "project-switcher"
                    )
                }
            }

            // Select and switch
            if let selectionService = await container.resolveOptional(
                (any ProjectSelectionServiceProtocol).self
            ) {
                await selectionService.select(project.id)
            }
            if let recentService = await container.resolveOptional(
                (any RecentProjectsServiceProtocol).self
            ) {
                await recentService.recordAccess(project.id)
            }

            shellState.selectedProjectID = project.id
            shellState.projectName = project.name
            shellState.projectIcon = project.icon
            shellState.projectColor = project.color

            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("Project Switcher Sheet") {
    let shell = CodalonShellState()
    shell.selectedProjectID = UUID()
    shell.projectName = "Codalon"
    return ProjectSwitcherSheet()
        .environment(shell)
}
