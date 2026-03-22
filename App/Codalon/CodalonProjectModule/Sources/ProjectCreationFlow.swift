// Issues #259, #260, #261, #262, #263, #264, #265, #266, #267, #268 — Project Creation Flow

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaGit
import HelaiaKeychain
import HelaiaLogger

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
    @State private var cloneDestConflict = false
    @State private var cloneDestConflictProject: CodalonProject?

    // Path C state
    @State private var createFolder = true
    @State private var initGit = true
    @State private var createGitHubRepo = false
    @State private var newRepoName = ""
    @State private var newRepoPrivate = true
    @State private var blankFolderDestination: URL?

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
            // Issue #268 — Path A is first and recommended for existing repos
            pathCard(
                path: .localFolder,
                icon: "folder.fill",
                title: "From Local Folder",
                descriptor: "Open an existing folder on disk",
                recommended: true
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
        descriptor: String,
        recommended: Bool = false
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
                    HStack(spacing: Spacing._1_5) {
                        Text(title)
                            .helaiaFont(.button)
                            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                        if recommended {
                            Text("Recommended")
                                .helaiaFont(.caption2)
                                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                        }
                    }

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
                HelaiaMaterial.regular.apply(to: Color.clear)
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
                .task { await searchGitHubRepos() }
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
                    // Clone destination — must be chosen via NSOpenPanel
                    HStack(spacing: Spacing._2) {
                        Text("Clone to:")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                        if let dest = cloneDestination {
                            Text(dest.path)
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                                .lineLimit(1)
                        } else {
                            Text("Choose a folder…")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }

                        Spacer()

                        HelaiaButton(
                            cloneDestination == nil ? "Choose Folder" : "Change",
                            variant: cloneDestination == nil ? .secondary : .ghost,
                            size: .small,
                            fullWidth: false
                        ) {
                            chooseCloneDestination()
                        }
                    }
                    .onChange(of: selectedGitHubRepo?.id) { _, _ in
                        checkCloneDestConflict()
                    }

                    // Clone destination conflict (#268 §8)
                    if cloneDestConflict {
                        cloneDestConflictView
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

    // MARK: - Clone Destination Conflict (#268 §8)

    // Issue #268 — Conflict view with Path A guidance
    @ViewBuilder
    private var cloneDestConflictView: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    "exclamationmark.triangle.fill",
                    size: .xs,
                    color: SemanticColor.warning(for: colorScheme)
                )
                Text("This folder already contains a directory named \"\(selectedGitHubRepo?.name ?? "")\".")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.warning(for: colorScheme))
            }

            Text("Use \"From Local Folder\" to link an existing repo, or choose a different destination to clone a fresh copy.")
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HStack(spacing: Spacing._2) {
                if let project = cloneDestConflictProject {
                    HelaiaButton(
                        "Open \(project.name)",
                        variant: .secondary,
                        size: .small,
                        fullWidth: false
                    ) {
                        Task { @MainActor in
                            let container = ServiceContainer.shared
                            if let selectionService = await container.resolveOptional(
                                (any ProjectSelectionServiceProtocol).self
                            ) {
                                await selectionService.select(project.id)
                            }
                        }
                    }
                }

                HelaiaButton(
                    "Use Local Folder",
                    icon: "folder",
                    variant: .secondary,
                    size: .small,
                    fullWidth: false
                ) {
                    withAnimation(ComponentAnimation.Card.press) {
                        selectedPath = .localFolder
                    }
                    openFolderPanel()
                }

                HelaiaButton(
                    "Choose Different",
                    variant: .ghost,
                    size: .small,
                    fullWidth: false
                ) {
                    chooseCloneDestination()
                }
            }
        }
        .padding(Spacing._3)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
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
                // Issue #268 — Folder destination via NSOpenPanel
                HStack(spacing: Spacing._2) {
                    Text("Create in:")
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                    if let dest = blankFolderDestination {
                        Text(dest.path)
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                            .lineLimit(1)
                    } else {
                        Text("Choose a folder…")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    }

                    Spacer()

                    HelaiaButton(
                        blankFolderDestination == nil ? "Choose Folder" : "Change",
                        variant: blankFolderDestination == nil ? .secondary : .ghost,
                        size: .small,
                        fullWidth: false
                    ) {
                        chooseBlankFolderDestination()
                    }
                }

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
            // Issue #268 — conflict blocks create entirely (no "Use Anyway")
            return selectedGitHubRepo != nil
                && cloneDestination != nil
                && !isCloning
                && !cloneDestConflict
        case .startBlank:
            // Issue #268 — require folder destination when createFolder is on
            if createFolder { return blankFolderDestination != nil }
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

        Task { @MainActor in
            let analysis = await analyzeFolder(url)
            folderAnalysis = analysis
            if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                projectName = url.lastPathComponent
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

    @MainActor
    private func checkFolderConflict(_ url: URL) async {
        do {
            let container = ServiceContainer.shared
            let repoPathRepo = try await container.resolve(
                (any GitLocalRepoPathRepositoryProtocol).self
            )
            let projectService = try await container.resolve(
                (any ProjectServiceProtocol).self
            )
            let allProjects = try await projectService.loadActive()
            for project in allProjects {
                if let existing = try await repoPathRepo.fetchByProject(project.id) {
                    if existing.displayPath == url.path {
                        conflictProject = project
                        showConflict = true
                        return
                    }
                }
            }
        } catch {
            // No conflict check possible — proceed
        }
    }

    /// Real home directory bypassing sandbox container redirect.
    private static func realHomeDirectory() -> URL? {
        guard let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir else { return nil }
        return URL(fileURLWithPath: String(cString: dir))
    }

    /// Check if a file exists at a URL, even when the sandbox blocks reading.
    /// Returns true if the file can be read OR if the error is "no permission"
    /// (which means the file exists but the sandbox blocked the read).
    private static func sshKeyExists(at url: URL) -> Bool {
        do {
            _ = try Data(contentsOf: url)
            return true
        } catch let error as CocoaError where error.code == .fileReadNoPermission {
            // Sandbox blocked the read — but the file exists
            return true
        } catch {
            // File doesn't exist or other error
            return false
        }
    }

    private func checkSSHKey() {
        let home = Self.realHomeDirectory()
            ?? FileManager.default.homeDirectoryForCurrentUser
        let ed25519 = home.appendingPathComponent(".ssh/id_ed25519")
        let rsa = home.appendingPathComponent(".ssh/id_rsa")
        let category = "ssh-key-check"

        Task {
            let logger = await ServiceContainer.shared.resolveOptional(
                (any HelaiaLoggerProtocol).self
            )
            logger?.info("realHomeDirectory = \(home.path)", category: category)
            logger?.info("Checking ed25519 at \(ed25519.path)", category: category)
            logger?.info("Checking rsa at \(rsa.path)", category: category)
        }

        // Detect SSH key existence via error codes. Inside App Sandbox,
        // Data(contentsOf:) fails for ~/.ssh/ but the error distinguishes:
        //   - CocoaError.fileReadNoPermission (257) → file EXISTS, sandbox blocked
        //   - CocoaError.fileReadNoSuchFile (260)   → file does NOT exist
        let ed25519Exists = Self.sshKeyExists(at: ed25519)
        let rsaExists = Self.sshKeyExists(at: rsa)

        sshKeyAvailable = ed25519Exists || rsaExists

        let result = sshKeyAvailable
        Task {
            let logger = await ServiceContainer.shared.resolveOptional(
                (any HelaiaLoggerProtocol).self
            )
            logger?.info(
                "sshKeyAvailable = \(result) (ed25519=\(ed25519Exists), rsa=\(rsaExists))",
                category: category
            )
        }
    }

    // Issue #268 — Sandbox-safe conflict detection for clone destination
    private func checkCloneDestConflict() {
        guard let repo = selectedGitHubRepo,
              let dest = cloneDestination else {
            cloneDestConflict = false
            cloneDestConflictProject = nil
            return
        }
        let target = dest.appendingPathComponent(repo.name)

        // Sandbox-safe existence check: FileManager.fileExists returns
        // false for paths outside the container. Use Data(contentsOf:)
        // which either succeeds or throws fileReadNoPermission (proves
        // the path exists).
        guard Self.directoryExistsInSandbox(at: target) else {
            cloneDestConflict = false
            cloneDestConflictProject = nil

            return
        }

        cloneDestConflict = true

        Task { @MainActor in
            let logger = await ServiceContainer.shared.resolveOptional(
                (any HelaiaLoggerProtocol).self
            )
            logger?.warning(
                "Clone destination exists: \(target.path)",
                category: "path-b"
            )

            // Check if folder is already linked to a CodalonProject
            do {
                let container = ServiceContainer.shared
                let repoPathRepo = try await container.resolve(
                    (any GitLocalRepoPathRepositoryProtocol).self
                )
                let projectService = try await container.resolve(
                    (any ProjectServiceProtocol).self
                )
                let allProjects = try await projectService.loadActive()
                for project in allProjects {
                    if let existing = try await repoPathRepo.fetchByProject(project.id) {
                        if existing.displayPath == target.path {
                            cloneDestConflictProject = project
                            logger?.info(
                                "Conflict folder linked to project: \(project.name)",
                                category: "path-b"
                            )
                            return
                        }
                    }
                }
            } catch {
                // No linked project found — that's fine
            }
            cloneDestConflictProject = nil
        }
    }

    /// Sandbox-safe directory existence check.
    /// NSOpenPanel-blessed parent URLs allow enumeration of children,
    /// so we check via FileManager on the blessed subtree.
    private static func directoryExistsInSandbox(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        // Fallback: if FileManager returns false (sandbox), try reading
        // the directory contents — a valid directory will throw
        // fileReadNoPermission, a nonexistent one throws fileNoSuchFile.
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: url.path)
            return true
        } catch let error as CocoaError
            where error.code == .fileReadNoPermission {
            return true
        } catch {
            return false
        }
    }

    private func chooseCloneDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to clone the repository"
        if panel.runModal() == .OK {
            cloneDestination = panel.url
            checkCloneDestConflict()
        }
    }

    private func chooseBlankFolderDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to create the project folder"
        if panel.runModal() == .OK {
            blankFolderDestination = panel.url
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
        do {
            let container = ServiceContainer.shared
            let logger = await container.resolveOptional(
                (any HelaiaLoggerProtocol).self
            )
            let gitHubService = try await container.resolve(
                (any GitHubServiceProtocol).self
            )
            logger?.info("Fetching repositories (search: \"\(repoSearch)\")", category: "path-b")
            let fetched = try await gitHubService.fetchRepositories(page: 1)
            logger?.info("Fetched \(fetched.count) repositories", category: "path-b")
            let query = repoSearch.trimmingCharacters(in: .whitespaces)
            let filtered: [GitHubRepo]
            if query.isEmpty {
                filtered = fetched
            } else {
                filtered = fetched.filter {
                    $0.fullName.localizedCaseInsensitiveContains(query)
                        || $0.name.localizedCaseInsensitiveContains(query)
                }
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
        } else if let analysis = folderAnalysis,
                  analysis.hasRemote,
                  let remoteURL = analysis.remoteURL,
                  let fullName = Self.parseGitHubFullName(from: remoteURL) {
            linkedRepos = [fullName]
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
            // Issue #268 — cloneDestination is required (panel-blessed URL)
            if let repo = selectedGitHubRepo, let dest = cloneDestination {
                localURL = dest.appendingPathComponent(repo.name)
                sideEffects.shouldClone = true
                sideEffects.cloneRemoteURL = URL(
                    string: "https://github.com/\(repo.fullName).git"
                )
            }

        case .startBlank:
            // Issue #268 — blankFolderDestination is panel-blessed
            if createFolder, let dest = blankFolderDestination {
                localURL = dest.appendingPathComponent(slug)
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

    // MARK: - GitHub Remote URL Parsing

    static func parseGitHubFullName(from remoteURL: String) -> String? {
        // Handles HTTPS: https://github.com/owner/repo.git
        // Handles SSH: git@github.com:owner/repo.git
        let url = remoteURL
            .replacingOccurrences(of: ".git", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if url.contains("github.com/") {
            let parts = url.components(separatedBy: "github.com/")
            guard parts.count == 2 else { return nil }
            let path = parts[1]
            let segments = path.split(separator: "/")
            guard segments.count >= 2 else { return nil }
            return "\(segments[0])/\(segments[1])"
        }

        if url.contains("github.com:") {
            let parts = url.components(separatedBy: "github.com:")
            guard parts.count == 2 else { return nil }
            let path = parts[1]
            let segments = path.split(separator: "/")
            guard segments.count >= 2 else { return nil }
            return "\(segments[0])/\(segments[1])"
        }

        return nil
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
        HelaiaMaterial.thick.apply(to: Color.clear)
    }
}

#Preview("Project Creation Flow — No GitHub") {
    ProjectCreationFlow(
        gitHubConnected: false
    ) { _, _, _ in }
    .padding(Spacing._8)
    .frame(width: 560, height: 500)
    .background {
        HelaiaMaterial.thick.apply(to: Color.clear)
    }
}
