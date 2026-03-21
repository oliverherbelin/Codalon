// Issues #259, #260, #261, #262, #263, #264, #265, #266, #267, #268 — Project Creation Flow

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaGit
import HelaiaKeychain

// MARK: - Creation Path

enum ProjectCreationPath: Sendable, Equatable {
    case localFolder
    case fromGitHub
    case startBlank
}

// MARK: - Folder Analysis

struct FolderAnalysis: Sendable, Equatable {
    let url: URL
    let hasGit: Bool
    let hasRemote: Bool
    let remoteName: String?
    let remoteURL: String?
}

// MARK: - ProjectCreationFlow

struct ProjectCreationFlow: View {

    let gitHubConnected: Bool
    var onBack: (() -> Void)?
    let onComplete: (CodalonProject, URL?, ProjectCreationSideEffects) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPath: ProjectCreationPath?
    @State private var projectName = ""
    @State private var folderAnalysis: FolderAnalysis?
    @State private var selectedGitHubRepo: GitHubRepo?
    @State private var cloneDestination: URL?

    // Path A state
    @State private var showGitInit = true
    @State private var showGitHubLink = false
    @State private var linkRepoSearch = ""
    @State private var linkRepos: [GitHubRepo] = []

    // Path B state
    @State private var repoSearch = ""
    @State private var searchResults: [GitHubRepo] = []
    @State private var sshKeyAvailable = false
    @State private var isCloning = false
    @State private var cloneProgress: String?
    @State private var cloneError: String?

    // Path C state
    @State private var createFolder = true
    @State private var initGit = true
    @State private var createGitHubRepo = false
    @State private var newRepoName = ""
    @State private var newRepoPrivate = true

    // Conflict detection (#268)
    @State private var conflictProject: CodalonProject?
    @State private var showConflict = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing._1_5) {
                Text("Set up your project")
                    .helaiaFont(.title2)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                Text("Choose how to start, then name your project.")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing._5)

            // Project name field
            HelaiaTextField(
                title: "Project Name",
                text: $projectName,
                placeholder: "My App",
                maxCharacters: 64
            )
            .padding(.bottom, Spacing._4)

            if selectedPath == nil {
                pathSelector
            } else {
                selectedPathView
            }

            Spacer(minLength: Spacing._3)

            // Footer
            footer
        }
    }

    // MARK: - Path Selector Cards (#259)

    @ViewBuilder
    private var pathSelector: some View {
        VStack(spacing: Spacing._2) {
            pathCard(
                path: .localFolder,
                icon: "folder.fill",
                title: "From Local Folder",
                descriptor: "Open an existing folder on disk"
            )

            pathCard(
                path: .fromGitHub,
                icon: "arrow.down.circle.fill",
                title: "From GitHub",
                descriptor: "Clone a repository from GitHub"
            )
            .disabled(!gitHubConnected)
            .opacity(gitHubConnected ? 1 : 0.5)

            pathCard(
                path: .startBlank,
                icon: "plus.rectangle.fill",
                title: "Start Blank",
                descriptor: "Create a new empty project"
            )
        }
    }

    @ViewBuilder
    private func pathCard(
        path: ProjectCreationPath,
        icon: String,
        title: String,
        descriptor: String
    ) -> some View {
        Button {
            withAnimation(ComponentAnimation.Card.press) {
                selectedPath = path
            }
            if path == .localFolder {
                openFolderPanel()
            } else if path == .fromGitHub {
                checkSSHKey()
            }
        } label: {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    icon,
                    size: .xl,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text(title)
                        .helaiaFont(.button)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                    Text(descriptor)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()

                HelaiaIconView(
                    "chevron.right",
                    size: .xs,
                    color: SemanticColor.textTertiary(for: colorScheme)
                )
            }
            .padding(.horizontal, Spacing._4)
            .frame(height: 56)
            .background {
                HelaiaMaterial.regular.apply(to: Rectangle())
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(descriptor)")
    }

    // MARK: - Selected Path Content

    @ViewBuilder
    private var selectedPathView: some View {
        switch selectedPath {
        case .localFolder:
            pathAContent
        case .fromGitHub:
            pathBContent
        case .startBlank:
            pathCContent
        case .none:
            EmptyView()
        }
    }

    // MARK: - Path A: From Local Folder (#260, #261, #262)

    @ViewBuilder
    private var pathAContent: some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            // Chosen folder
            if let analysis = folderAnalysis {
                folderSummary(analysis)

                // Git init offer (#261)
                if !analysis.hasGit {
                    HelaiaToggle(
                        isOn: $showGitInit,
                        label: "Initialize Git repository"
                    )
                }

                // GitHub link offer (#262)
                if analysis.hasGit, !analysis.hasRemote, gitHubConnected {
                    gitHubLinkOffer
                }

                // Auto-detected remote
                if let remote = analysis.remoteURL {
                    HStack(spacing: Spacing._1_5) {
                        HelaiaIconView(
                            "link",
                            size: .xs,
                            color: SemanticColor.success(for: colorScheme)
                        )
                        Text("Remote: \(remote)")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    }
                }
            } else {
                // No folder selected yet — prompt
                HelaiaButton(
                    "Choose Folder",
                    icon: "folder",
                    variant: .secondary,
                    fullWidth: true
                ) {
                    openFolderPanel()
                }
            }

            // Conflict alert (#268)
            if showConflict, let conflict = conflictProject {
                conflictView(existingProject: conflict)
            }
        }
        .transition(.opacity.combined(with: .offset(y: 8)))
    }

    @ViewBuilder
    private func folderSummary(_ analysis: FolderAnalysis) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "folder.fill",
                size: .custom(20),
                color: SemanticColor.textSecondary(for: colorScheme)
            )

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(analysis.url.lastPathComponent)
                    .helaiaFont(.bodyEmphasized)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                Text(analysis.url.path)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            if analysis.hasGit {
                HelaiaCapsule.filter(
                    "Git",
                    icon: .sfSymbol("checkmark"),
                    isSelected: true
                ) {}
            }

            HelaiaButton(
                "Change",
                variant: .ghost,
                size: .small,
                fullWidth: false
            ) {
                openFolderPanel()
            }
        }
        .padding(Spacing._3)
        .background(SemanticColor.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - GitHub Link Offer (#262)

    @ViewBuilder
    private var gitHubLinkOffer: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            Text("Link to a GitHub repository (optional)")
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HelaiaTextField(
                title: "",
                text: $linkRepoSearch,
                placeholder: "Search repositories"
            )

            if !filteredLinkRepos.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredLinkRepos, id: \.id) { repo in
                            repoRow(repo, isSelected: selectedGitHubRepo?.id == repo.id) {
                                selectedGitHubRepo = repo
                                linkRepoSearch = repo.fullName
                                if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    projectName = repo.name
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
                .background(SemanticColor.surface(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            }
        }
        .task { await loadLinkRepos() }
    }

    private var filteredLinkRepos: [GitHubRepo] {
        if linkRepoSearch.isEmpty { return linkRepos }
        return linkRepos.filter {
            $0.fullName.localizedCaseInsensitiveContains(linkRepoSearch)
                || $0.name.localizedCaseInsensitiveContains(linkRepoSearch)
        }
    }

    // MARK: - Path B: From GitHub (#263, #264, #265)

    @ViewBuilder
    private var pathBContent: some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            // SSH key check (#264)
            if !sshKeyAvailable {
                sshKeyCheckBlock
            } else if isCloning {
                cloneProgressView
            } else if cloneError != nil {
                cloneErrorView
            } else {
                // Repo search
                HelaiaTextField(
                    title: "Search GitHub Repositories",
                    text: $repoSearch,
                    placeholder: "Search repositories"
                )
                .onChange(of: repoSearch) { _, _ in
                    Task { await searchGitHubRepos() }
                }

                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchResults, id: \.id) { repo in
                                repoRow(repo, isSelected: selectedGitHubRepo?.id == repo.id) {
                                    selectedGitHubRepo = repo
                                    if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        projectName = repo.name
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 140)
                    .background(SemanticColor.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }

                if selectedGitHubRepo != nil {
                    // Clone destination
                    HStack(spacing: Spacing._2) {
                        Text("Clone to:")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                        Text(cloneDestination?.path ?? "~/Developer")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                            .lineLimit(1)

                        Spacer()

                        HelaiaButton(
                            "Choose",
                            variant: .ghost,
                            size: .small,
                            fullWidth: false
                        ) {
                            chooseCloneDestination()
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .offset(y: 8)))
    }

    // MARK: - SSH Key Check Block (#264)

    @ViewBuilder
    private var sshKeyCheckBlock: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    "key.fill",
                    size: .sm,
                    color: SemanticColor.warning(for: colorScheme)
                )

                Text("SSH key required for cloning")
                    .helaiaFont(.bodyEmphasized)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
            }

            Text("No SSH key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa.")
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HStack {
                Text("ssh-keygen -t ed25519 -C \"your@email.com\"")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    .padding(Spacing._2)
                    .background(SemanticColor.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .textSelection(.enabled)

                Spacer()
            }

            HelaiaButton(
                "Re-check",
                icon: "arrow.clockwise",
                variant: .secondary,
                size: .small,
                fullWidth: false
            ) {
                checkSSHKey()
            }
        }
        .padding(Spacing._3)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColor.warning(for: colorScheme).opacity(Opacity.State.hover))
        )
    }

    // MARK: - Clone Progress (#265)

    @ViewBuilder
    private var cloneProgressView: some View {
        VStack(spacing: Spacing._2) {
            HelaiaProgressBar(value: nil)

            Text(cloneProgress ?? "Cloning…")
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HelaiaButton(
                "Cancel",
                variant: .ghost,
                size: .small,
                fullWidth: false
            ) {
                isCloning = false
                cloneProgress = nil
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing._4)
    }

    @ViewBuilder
    private var cloneErrorView: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    "exclamationmark.triangle.fill",
                    size: .sm,
                    color: SemanticColor.error(for: colorScheme)
                )

                Text(cloneError ?? "Clone failed")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            HelaiaButton(
                "Try Again",
                variant: .secondary,
                size: .small,
                fullWidth: false
            ) {
                cloneError = nil
            }
        }
    }

    // MARK: - Path C: Start Blank (#266, #267)

    @ViewBuilder
    private var pathCContent: some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            HelaiaToggle(
                isOn: $createFolder,
                label: "Create project folder"
            )

            if createFolder {
                HelaiaToggle(
                    isOn: $initGit,
                    label: "Initialize Git repository"
                )
            }

            if gitHubConnected {
                gitHubRepoCreationOffer
            }
        }
        .transition(.opacity.combined(with: .offset(y: 8)))
    }

    // MARK: - GitHub Repo Creation Offer (#267)

    @ViewBuilder
    private var gitHubRepoCreationOffer: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HelaiaToggle(
                isOn: $createGitHubRepo,
                label: "Create GitHub repository"
            )

            if createGitHubRepo {
                HelaiaTextField(
                    title: "Repository Name",
                    text: $newRepoName,
                    placeholder: projectName.isEmpty ? "my-app" : projectName.lowercased()
                        .replacingOccurrences(of: " ", with: "-")
                )

                HStack(spacing: Spacing._2) {
                    HelaiaCapsule.filter(
                        "Private",
                        icon: .sfSymbol("lock.fill"),
                        isSelected: newRepoPrivate
                    ) {
                        newRepoPrivate = true
                    }

                    HelaiaCapsule.filter(
                        "Public",
                        icon: .sfSymbol("globe"),
                        isSelected: !newRepoPrivate
                    ) {
                        newRepoPrivate = false
                    }
                }
            }
        }
    }

    // MARK: - Conflict View (#268)

    @ViewBuilder
    private func conflictView(existingProject: CodalonProject) -> some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    "exclamationmark.triangle.fill",
                    size: .sm,
                    color: SemanticColor.warning(for: colorScheme)
                )

                Text("This folder is already linked to \"\(existingProject.name)\"")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
            }

            HStack(spacing: Spacing._2) {
                HelaiaButton(
                    "Use Anyway",
                    variant: .secondary,
                    size: .small,
                    fullWidth: false
                ) {
                    showConflict = false
                    conflictProject = nil
                }

                HelaiaButton(
                    "Choose Different",
                    variant: .ghost,
                    size: .small,
                    fullWidth: false
                ) {
                    showConflict = false
                    conflictProject = nil
                    folderAnalysis = nil
                    openFolderPanel()
                }
            }
        }
        .padding(Spacing._3)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColor.warning(for: colorScheme).opacity(Opacity.State.hover))
        )
    }

    // MARK: - Shared Repo Row

    @ViewBuilder
    private func repoRow(
        _ repo: GitHubRepo,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing._px) {
                    Text(repo.fullName)
                        .helaiaFont(.bodyEmphasized)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    if let desc = repo.description {
                        Text(desc)
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isSelected {
                    HelaiaIconView(
                        "checkmark",
                        size: .xs,
                        weight: .semibold,
                        color: SemanticColor.success(for: colorScheme)
                    )
                }
            }
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1_5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        HStack {
            if selectedPath != nil {
                HelaiaButton.ghost("Back", icon: "chevron.left") {
                    withAnimation(ComponentAnimation.Card.press) {
                        selectedPath = nil
                        folderAnalysis = nil
                        selectedGitHubRepo = nil
                        cloneError = nil
                        showConflict = false
                    }
                }
            } else if let onBack {
                HelaiaButton.ghost("Back", icon: "chevron.left") {
                    onBack()
                }
            }

            Spacer()

            HelaiaButton(
                "Create Project",
                icon: "arrow.right",
                fullWidth: false
            ) {
                createProject()
            }
            .disabled(!isFormValid)
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let nameValid = !projectName.trimmingCharacters(in: .whitespaces).isEmpty
        guard nameValid else { return false }

        switch selectedPath {
        case .localFolder:
            return folderAnalysis != nil && !showConflict
        case .fromGitHub:
            return selectedGitHubRepo != nil && !isCloning
        case .startBlank:
            return true
        case .none:
            return false
        }
    }

    // MARK: - Actions

    private func openFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            let analysis = await analyzeFolder(url)
            await MainActor.run {
                folderAnalysis = analysis
                if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                    projectName = url.lastPathComponent
                }
            }
            await checkFolderConflict(url)
        }
    }

    private func analyzeFolder(_ url: URL) async -> FolderAnalysis {
        do {
            let container = ServiceContainer.shared
            let gitService = try await container.resolve(
                (any GitServiceProtocol).self
            )
            let repo = try await gitService.open(at: url)
            return FolderAnalysis(
                url: url,
                hasGit: true,
                hasRemote: repo.remoteURL != nil,
                remoteName: "origin",
                remoteURL: repo.remoteURL?.absoluteString
            )
        } catch {
            return FolderAnalysis(
                url: url,
                hasGit: false,
                hasRemote: false,
                remoteName: nil,
                remoteURL: nil
            )
        }
    }

    private func checkFolderConflict(_ url: URL) async {
        do {
            let container = ServiceContainer.shared
            let repoPathRepo = try await container.resolve(
                (any GitLocalRepoPathRepositoryProtocol).self
            )
            let projectService = try await container.resolve(
                (any ProjectServiceProtocol).self
            )
            let allPaths = try await repoPathRepo.fetchByProject(UUID()) // load all approach
            // Actually, loadAll not on protocol — check all projects
            let allProjects = try await projectService.loadActive()
            for project in allProjects {
                if let existing = try await repoPathRepo.fetchByProject(project.id) {
                    if existing.displayPath == url.path {
                        await MainActor.run {
                            conflictProject = project
                            showConflict = true
                        }
                        return
                    }
                }
            }
        } catch {
            // No conflict check possible — proceed
        }
    }

    private func checkSSHKey() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let ed25519 = home.appendingPathComponent(".ssh/id_ed25519")
        let rsa = home.appendingPathComponent(".ssh/id_rsa")
        sshKeyAvailable = FileManager.default.fileExists(atPath: ed25519.path)
            || FileManager.default.fileExists(atPath: rsa.path)
    }

    private func chooseCloneDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to clone the repository"
        if panel.runModal() == .OK {
            cloneDestination = panel.url
        }
    }

    private func loadLinkRepos() async {
        do {
            let container = ServiceContainer.shared
            let gitHubService = try await container.resolve(
                (any GitHubServiceProtocol).self
            )
            let fetched = try await gitHubService.fetchRepositories(page: 1)
            await MainActor.run {
                linkRepos = fetched
            }
        } catch {
            // Silently fail — linking is optional
        }
    }

    private func searchGitHubRepos() async {
        guard !repoSearch.trimmingCharacters(in: .whitespaces).isEmpty else {
            await MainActor.run { searchResults = [] }
            return
        }
        do {
            let container = ServiceContainer.shared
            let gitHubService = try await container.resolve(
                (any GitHubServiceProtocol).self
            )
            let fetched = try await gitHubService.fetchRepositories(page: 1)
            let filtered = fetched.filter {
                $0.fullName.localizedCaseInsensitiveContains(repoSearch)
                    || $0.name.localizedCaseInsensitiveContains(repoSearch)
            }
            await MainActor.run {
                searchResults = filtered
            }
        } catch {
            // Silently fail
        }
    }

    private func createProject() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        let slug = name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        var linkedRepos: [String] = []
        if let repo = selectedGitHubRepo {
            linkedRepos = [repo.fullName]
        }

        let project = CodalonProject(
            name: name,
            slug: slug,
            linkedGitHubRepos: linkedRepos
        )

        var localURL: URL?
        var sideEffects = ProjectCreationSideEffects()

        switch selectedPath {
        case .localFolder:
            localURL = folderAnalysis?.url
            if let analysis = folderAnalysis, !analysis.hasGit, showGitInit {
                sideEffects.shouldGitInit = true
            }

        case .fromGitHub:
            if let repo = selectedGitHubRepo {
                let dest = cloneDestination ?? FileManager.default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent("Developer")
                localURL = dest.appendingPathComponent(repo.name)
                sideEffects.shouldClone = true
                sideEffects.cloneRemoteURL = URL(
                    string: "https://github.com/\(repo.fullName).git"
                )
            }

        case .startBlank:
            if createFolder {
                let docs = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Developer")
                localURL = docs.appendingPathComponent(slug)
                sideEffects.shouldCreateFolder = true
                if initGit {
                    sideEffects.shouldGitInit = true
                }
            }
            if createGitHubRepo {
                sideEffects.shouldCreateGitHubRepo = true
                sideEffects.newRepoName = newRepoName.isEmpty ? slug : newRepoName
                sideEffects.newRepoIsPrivate = newRepoPrivate
            }

        case .none:
            break
        }

        onComplete(project, localURL, sideEffects)
    }
}

// MARK: - Side Effects (#276)

struct ProjectCreationSideEffects: Sendable {
    var shouldGitInit = false
    var shouldClone = false
    var cloneRemoteURL: URL?
    var shouldCreateFolder = false
    var shouldCreateGitHubRepo = false
    var newRepoName: String?
    var newRepoIsPrivate = true
}

// MARK: - Preview

#Preview("Project Creation Flow") {
    ProjectCreationFlow(
        gitHubConnected: true
    ) { _, _, _ in }
    .padding(Spacing._8)
    .frame(width: 560, height: 500)
    .background {
        HelaiaMaterial.thick.apply(to: Rectangle())
    }
}

#Preview("Project Creation Flow — No GitHub") {
    ProjectCreationFlow(
        gitHubConnected: false
    ) { _, _, _ in }
    .padding(Spacing._8)
    .frame(width: 560, height: 500)
    .background {
        HelaiaMaterial.thick.apply(to: Rectangle())
    }
}
