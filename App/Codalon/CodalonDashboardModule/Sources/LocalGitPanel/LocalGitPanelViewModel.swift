// Issues #279, #281-#298 — LocalGitPanel ViewModel

import Foundation
import Observation
import HelaiaEngine
import HelaiaGit
import HelaiaAI
import HelaiaLogger

@MainActor
@Observable
final class LocalGitPanelViewModel {

    // MARK: - Published State

    var repo: GitRepository?
    var status: GitStatus = GitStatus()
    var currentBranch: String = "main"
    var branches: [GitBranch] = []
    var commits: [GitCommit] = []
    var isLoading = false
    var isFetching = false
    var isCommitting = false
    var isPushing = false
    var isPulling = false

    var commitMessage = ""
    var commitError: String?
    var pushError: String?
    var pullError: String?
    var generalError: String?

    var expandedFilePath: String?
    var fileDiffs: [String: GitFileDiff] = [:]

    // Stash
    var stashes: [GitStash] = []
    var isStashing = false

    // Tags
    var tags: [GitTag] = []

    // Conflict
    var hasConflict = false
    var conflictFiles: [String] = []

    // Issue linking
    var linkableIssues: [LinkableIssue] = []
    var isLoadingIssues = false
    private var linkedRepoFullName: String?

    // AI commit message
    var isGeneratingCommitMessage = false
    var aiCommitError: String?
    var hasAIProvider = false

    // Auto-refresh (#299)
    private var refreshTask: Task<Void, Never>?

    // MARK: - Computed

    var hasStagedChanges: Bool { status.hasStagedChanges }
    var hasUnstagedChanges: Bool { !status.unstagedFiles.isEmpty || !status.untrackedFiles.isEmpty }
    var canCommit: Bool { hasStagedChanges && !commitMessage.trimmingCharacters(in: .whitespaces).isEmpty && !isCommitting }
    var isClean: Bool { status.isClean }

    // MARK: - Dependencies

    private let resolver: LocalRepoResolver
    private var scopedURL: URL?
    private var logger: (any HelaiaLoggerProtocol)?

    init(resolver: LocalRepoResolver = LocalRepoResolver()) {
        self.resolver = resolver
    }

    // MARK: - Load

    func load(projectID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        logger = await ServiceContainer.shared.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )
        logger?.info("load() called for projectID=\(projectID)", category: "local-git")

        guard let resolved = await resolver.resolve(projectID: projectID) else {
            logger?.warning("resolve() returned nil — no repo found for project \(projectID)", category: "local-git")
            return
        }

        repo = resolved.repository
        scopedURL = resolved.scopedURL
        logger?.info(
            "resolve() succeeded — path=\(resolved.scopedURL.path), repo.localPath=\(resolved.repository.localPath.path)",
            category: "local-git"
        )

        // Resolve linked GitHub repo for issue linking
        if let projectService = await ServiceContainer.shared.resolveOptional(
            (any ProjectServiceProtocol).self
        ) {
            if let project = try? await projectService.load(id: projectID) {
                linkedRepoFullName = project.linkedGitHubRepos.first
            }
        }

        // Check for active AI provider
        if let aiManager = await ServiceContainer.shared.resolveOptional(
            HelaiaAI.AIProviderManager.self
        ) {
            if let provider = try? await aiManager.activeProvider() {
                hasAIProvider = await provider.isConfigured
            }
        }

        await refreshStatus()
        logger?.info(
            "After refreshStatus(): unstaged=\(status.unstagedFiles.count) staged=\(status.stagedFiles.count) untracked=\(status.untrackedFiles.count)",
            category: "local-git"
        )
        await refreshBranches()
        logger?.info("After refreshBranches(): \(branches.count) branches, current=\(currentBranch)", category: "local-git")
        startAutoRefresh()
    }

    // MARK: - Auto-refresh (#299)

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                await self?.refreshStatus()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
        revokeAccess()
    }

    private func revokeAccess() {
        guard let url = scopedURL else { return }
        url.stopAccessingSecurityScopedResource()
        logger?.info("Security-scoped access stopped: \(url.path)", category: "local-git")
        scopedURL = nil
    }

    func refreshStatus() async {
        guard let repo else { return }

        // Issue #279 — verify security-scoped access is active
        guard scopedURL != nil else {
            logger?.warning(
                "refreshStatus(): scopedURL is nil — security-scoped access not active, skipping",
                category: "local-git"
            )
            return
        }
        logger?.info(
            "refreshStatus(): scopedURL active at \(scopedURL?.path ?? "nil")",
            category: "local-git"
        )

        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            logger?.info("Calling status(in:) for \(repo.localPath.path)", category: "local-git")
            status = try await gitService.status(in: repo)
            logger?.info(
                "status(): staged=\(status.stagedFiles.count) unstaged=\(status.unstagedFiles.count) untracked=\(status.untrackedFiles.count)",
                category: "local-git"
            )
            currentBranch = (try? await gitService.currentBranch(in: repo))?.name ?? "main"
            hasConflict = false
            conflictFiles = []
        } catch let error as HelaiaGitError {
            logger?.error("status() HelaiaGitError: \(error)", category: "local-git")
            if case .mergeConflict(let files) = error {
                hasConflict = true
                conflictFiles = files
            }
        } catch {
            logger?.error("status() failed: \(error.localizedDescription)", category: "local-git")
            generalError = error.localizedDescription
        }
    }

    func refreshBranches() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            branches = try await gitService.branches(in: repo)
        } catch {
            // Fail silently — branches are supplementary
        }
    }

    // MARK: - Stage / Unstage

    func stageAll() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.stageAll(in: repo)
            await refreshStatus()
        } catch {
            generalError = "Failed to stage: \(error.localizedDescription)"
        }
    }

    func stageFiles(_ urls: [URL]) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.stage(files: urls, in: repo)
            await refreshStatus()
        } catch {
            generalError = "Failed to stage: \(error.localizedDescription)"
        }
    }

    func unstageAll() async {
        // HelaiaGit doesn't have unstageAll — stage empty to reset
        // For now, refresh status which will re-read the index
        await refreshStatus()
    }

    // MARK: - Commit (#289)

    func commit() async {
        guard let repo, canCommit else { return }
        isCommitting = true
        commitError = nil
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            _ = try await gitService.commit(message: commitMessage, in: repo)
            commitMessage = ""
            await refreshStatus()
        } catch {
            commitError = error.localizedDescription
        }
        isCommitting = false
    }

    // MARK: - Push (#291)

    func push() async {
        guard let repo else { return }
        isPushing = true
        pushError = nil
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.push(repo: repo, remote: "origin", branch: currentBranch)
        } catch {
            pushError = error.localizedDescription
        }
        isPushing = false
    }

    // MARK: - Commit & Push (#290)

    func commitAndPush() async {
        await commit()
        guard commitError == nil else { return }
        await push()
    }

    // MARK: - Pull (#295)

    func pull() async {
        guard let repo else { return }
        isPulling = true
        pullError = nil
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.pull(repo: repo, remote: "origin", branch: currentBranch)
            await refreshStatus()
        } catch {
            pullError = error.localizedDescription
        }
        isPulling = false
    }

    // MARK: - Fetch

    func fetch() async {
        guard let repo else { return }
        isFetching = true
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.fetch(repo: repo, remote: "origin")
        } catch {
            // Fetch failures are non-blocking
        }
        isFetching = false
    }

    // MARK: - Branches (#293, #294)

    func checkout(branch: String) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.checkout(branch: branch, in: repo)
            await refreshStatus()
            await refreshBranches()
        } catch {
            generalError = error.localizedDescription
        }
    }

    func createBranch(name: String) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.createBranch(name: name, in: repo)
            try await gitService.checkout(branch: name, in: repo)
            await refreshStatus()
            await refreshBranches()
        } catch {
            generalError = error.localizedDescription
        }
    }

    // MARK: - Stash (#296)

    func stashSave(message: String, includeUntracked: Bool = true) async {
        guard let repo else { return }
        isStashing = true
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            _ = try await gitService.stashSave(
                message: message, includeUntracked: includeUntracked, in: repo
            )
            await refreshStatus()
            await refreshStashes()
        } catch {
            generalError = error.localizedDescription
        }
        isStashing = false
    }

    func stashPop(index: Int = 0) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.stashPop(index: index, in: repo)
            await refreshStatus()
            await refreshStashes()
        } catch {
            generalError = error.localizedDescription
        }
    }

    func stashDrop(index: Int) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.stashDrop(index: index, in: repo)
            await refreshStashes()
        } catch {
            generalError = error.localizedDescription
        }
    }

    func refreshStashes() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            stashes = try await gitService.stashList(in: repo)
        } catch {
            stashes = []
        }
    }

    // MARK: - Tags (#297)

    func refreshTags() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            tags = try await gitService.tags(in: repo)
        } catch {
            tags = []
        }
    }

    func createTag(name: String, message: String?) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            _ = try await gitService.createTag(name: name, message: message, in: repo)
            await refreshTags()
        } catch {
            generalError = error.localizedDescription
        }
    }

    func deleteTag(name: String) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.deleteTag(name: name, in: repo)
            await refreshTags()
        } catch {
            generalError = error.localizedDescription
        }
    }

    func pushTags() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.pushTags(repo: repo, remote: "origin")
        } catch {
            generalError = error.localizedDescription
        }
    }

    // MARK: - Rebase (#298)

    func rebase(onto branch: String) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.rebase(onto: branch, in: repo)
            await refreshStatus()
        } catch let error as HelaiaGitError {
            if case .mergeConflict(let files) = error {
                hasConflict = true
                conflictFiles = files
            } else {
                generalError = error.localizedDescription
            }
        } catch {
            generalError = error.localizedDescription
        }
    }

    func abortRebase() async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            try await gitService.abortRebase(in: repo)
            hasConflict = false
            conflictFiles = []
            await refreshStatus()
        } catch {
            generalError = error.localizedDescription
        }
    }

    // MARK: - Diff (#287)

    // MARK: - Issue Linking

    var hasLinkedRepo: Bool { linkedRepoFullName != nil }

    func fetchLinkableIssues() async {
        guard let fullName = linkedRepoFullName else { return }
        let parts = fullName.split(separator: "/")
        guard parts.count == 2 else { return }

        isLoadingIssues = true
        defer { isLoadingIssues = false }

        do {
            let gitHubService = try await ServiceContainer.shared.resolve(
                (any GitHubServiceProtocol).self
            )
            let issues = try await gitHubService.fetchIssues(
                owner: String(parts[0]),
                repo: String(parts[1]),
                state: "open"
            )
            linkableIssues = issues.prefix(20).map { issue in
                LinkableIssue(
                    number: issue.number,
                    title: issue.title,
                    state: issue.state
                )
            }
            logger?.info(
                "fetchLinkableIssues: loaded \(linkableIssues.count) issues",
                category: "local-git"
            )
        } catch {
            logger?.error(
                "fetchLinkableIssues: \(error.localizedDescription)",
                category: "local-git"
            )
            linkableIssues = []
        }
    }

    func appendIssueReference(_ number: Int) {
        appendToCommitMessage("#\(number)")
    }

    func appendIssueClose(_ number: Int) {
        appendToCommitMessage("Closes #\(number)")
    }

    private func appendToCommitMessage(_ text: String) {
        if commitMessage.isEmpty {
            commitMessage = text
        } else if commitMessage.hasSuffix(" ") {
            commitMessage += text
        } else {
            commitMessage += " \(text)"
        }
    }

    // MARK: - AI Commit Message

    func generateCommitMessage() async {
        guard let repo, hasStagedChanges else { return }
        isGeneratingCommitMessage = true
        aiCommitError = nil

        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            let diffs = try await gitService.stagedDiff(in: repo)
            guard !diffs.isEmpty else {
                aiCommitError = "No staged changes to summarize"
                isGeneratingCommitMessage = false
                scheduleErrorClear()
                return
            }

            let diffText = diffs.map { fileDiff in
                let hunksText = fileDiff.hunks.map { hunk in
                    hunk.lines.map { line in
                        switch line.type {
                        case .added: return "+\(line.content)"
                        case .removed: return "-\(line.content)"
                        case .context: return " \(line.content)"
                        }
                    }.joined()
                }.joined(separator: "\n")
                return "--- \(fileDiff.path) ---\n\(hunksText)"
            }.joined(separator: "\n\n")

            let aiManager = try await ServiceContainer.shared.resolve(
                HelaiaAI.AIProviderManager.self
            )
            let provider = try await aiManager.activeProvider()
            let models = try await provider.availableModels()
            let modelID = models.first?.id ?? "gpt-4o"

            let request = AICompletionRequest(
                model: modelID,
                messages: [
                    .user("Write a concise git commit message (max 72 chars subject line, optional body) for these changes:\n\n\(diffText)")
                ],
                systemPrompt: "You are a helpful assistant that writes concise, conventional git commit messages. Reply with only the commit message, no quotes or explanation.",
                temperature: 0.3,
                maxTokens: 200
            )
            let response = try await aiManager.complete(request: request)
            commitMessage = response.content.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            logger?.info(
                "AI commit message generated (\(commitMessage.count) chars)",
                category: "local-git"
            )
        } catch {
            aiCommitError = "AI generation failed: \(error.localizedDescription)"
            logger?.error(
                "generateCommitMessage: \(error.localizedDescription)",
                category: "local-git"
            )
            scheduleErrorClear()
        }
        isGeneratingCommitMessage = false
    }

    private func scheduleErrorClear() {
        Task {
            try? await Task.sleep(for: .seconds(3))
            aiCommitError = nil
        }
    }

    // MARK: - Diff (#287)

    func loadDiff(for path: String) async {
        guard let repo else { return }
        do {
            let gitService = try await ServiceContainer.shared.resolve(
                (any GitServiceProtocol).self
            )
            let diffs = try await gitService.diff(in: repo)
            let repoBase = repo.localPath.path
            if let match = diffs.first(where: {
                repo.localPath.appendingPathComponent($0.path).path == path
            }) {
                fileDiffs[path] = match
                logger?.info(
                    "loadDiff: matched '\(match.path)' (\(match.hunks.count) hunks)",
                    category: "local-git"
                )
            } else {
                logger?.warning(
                    "loadDiff: no diff match for '\(path)' in \(diffs.count) diffs"
                        + " (repoBase=\(repoBase),"
                        + " diffPaths=\(diffs.map(\.path)))",
                    category: "local-git"
                )
            }
        } catch {
            logger?.error(
                "loadDiff: failed — \(error.localizedDescription)",
                category: "local-git"
            )
        }
    }
}

// MARK: - LinkableIssue

struct LinkableIssue: Identifiable, Sendable {
    let number: Int
    let title: String
    let state: String

    var id: Int { number }

    var isOpen: Bool { state == "open" }
}