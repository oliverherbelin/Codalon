// Issues #121, #129, #133, #136, #138, #141, #148 — Release ViewModel tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Test Double

private actor InertReleaseService: ReleaseServiceProtocol {
    private var store: [UUID: CodalonRelease] = [:]

    func save(_ release: CodalonRelease) async throws {
        store[release.id] = release
    }
    func load(id: UUID) async throws -> CodalonRelease {
        guard let release = store[id] else { throw TestError.notFound }
        return release
    }
    func delete(id: UUID) async throws {
        store.removeValue(forKey: id)
    }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        store.values.filter { $0.projectID == projectID }
    }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? {
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]
        return store.values.first { $0.projectID == projectID && !terminalStatuses.contains($0.status) }
    }

    func seed(_ release: CodalonRelease) {
        store[release.id] = release
    }
}

private actor FailingReleaseService: ReleaseServiceProtocol {
    func save(_ release: CodalonRelease) async throws { throw TestError.failed }
    func load(id: UUID) async throws -> CodalonRelease { throw TestError.failed }
    func delete(id: UUID) async throws { throw TestError.failed }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] { throw TestError.failed }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? { throw TestError.failed }
}

private enum TestError: Error {
    case notFound
    case failed
}

// MARK: - CRUD Tests (#121)

@Suite("ReleaseViewModel — CRUD")
@MainActor
struct ReleaseViewModelCRUDTests {

    let projectID = UUID()

    @Test("createRelease adds to list")
    func create() async {
        let service = InertReleaseService()
        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)

        await vm.createRelease(version: "1.0.0", buildNumber: "1", targetDate: nil, milestoneID: nil)
        await vm.loadReleases()

        #expect(vm.releases.count == 1)
        #expect(vm.releases.first?.version == "1.0.0")
    }

    @Test("loadReleases excludes soft-deleted")
    func loadExcludesDeleted() async {
        let service = InertReleaseService()
        var release = CodalonRelease(projectID: projectID, version: "1.0.0")
        release.deletedAt = .now
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        await vm.loadReleases()

        #expect(vm.releases.isEmpty)
    }

    @Test("deleteRelease clears selected")
    func delete() async {
        let service = InertReleaseService()
        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)

        await vm.createRelease(version: "1.0.0", buildNumber: "1", targetDate: nil, milestoneID: nil)
        await vm.loadReleases()
        let release = vm.releases.first!
        vm.selectedRelease = release

        await vm.deleteRelease(id: release.id)

        #expect(vm.selectedRelease == nil)
        #expect(vm.releases.isEmpty)
    }

    @Test("error message set on failure")
    func errorOnLoad() async {
        let service = FailingReleaseService()
        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)

        await vm.loadReleases()

        #expect(vm.errorMessage != nil)
    }
}

// MARK: - Status Tests (#148)

@Suite("ReleaseViewModel — Status")
@MainActor
struct ReleaseViewModelStatusTests {

    @Test("updateStatus changes selected release status")
    func updateStatus() async {
        let service = InertReleaseService()
        let projectID = UUID()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0", status: .drafting)
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.updateStatus(.testing)

        #expect(vm.selectedRelease?.status == .testing)
    }
}

// MARK: - Linking Tests (#129, #133, #136)

@Suite("ReleaseViewModel — Linking")
@MainActor
struct ReleaseViewModelLinkingTests {

    let projectID = UUID()

    @Test("linkMilestone sets milestone ID")
    func linkMilestone() async {
        let service = InertReleaseService()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        let milestoneID = UUID()
        await vm.linkMilestone(milestoneID)

        #expect(vm.selectedRelease?.linkedMilestoneID == milestoneID)
    }

    @Test("linkTask appends task ID")
    func linkTask() async {
        let service = InertReleaseService()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        let taskID = UUID()
        await vm.linkTask(taskID)

        #expect(vm.selectedRelease?.linkedTaskIDs == [taskID])
    }

    @Test("linkTask prevents duplicates")
    func linkTaskDuplicate() async {
        let service = InertReleaseService()
        let taskID = UUID()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0", linkedTaskIDs: [taskID])
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.linkTask(taskID)

        #expect(vm.selectedRelease?.linkedTaskIDs.count == 1)
    }

    @Test("unlinkTask removes task ID")
    func unlinkTask() async {
        let service = InertReleaseService()
        let taskID = UUID()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0", linkedTaskIDs: [taskID])
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.unlinkTask(taskID)

        #expect(vm.selectedRelease?.linkedTaskIDs.isEmpty == true)
    }

    @Test("linkGitHubIssue appends ref")
    func linkGitHubIssue() async {
        let service = InertReleaseService()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.linkGitHubIssue("owner/repo#42")

        #expect(vm.selectedRelease?.linkedGitHubIssueRefs == ["owner/repo#42"])
    }

    @Test("unlinkGitHubIssue removes ref")
    func unlinkGitHubIssue() async {
        let service = InertReleaseService()
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            linkedGitHubIssueRefs: ["owner/repo#42"]
        )
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.unlinkGitHubIssue("owner/repo#42")

        #expect(vm.selectedRelease?.linkedGitHubIssueRefs.isEmpty == true)
    }
}

// MARK: - Checklist Tests (#138)

@Suite("ReleaseViewModel — Checklist")
@MainActor
struct ReleaseViewModelChecklistTests {

    let projectID = UUID()

    @Test("addChecklistItem appends item")
    func addItem() async {
        let service = InertReleaseService()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.addChecklistItem(title: "Test item")

        #expect(vm.selectedRelease?.checklistItems.count == 1)
        #expect(vm.selectedRelease?.checklistItems.first?.title == "Test item")
        #expect(vm.selectedRelease?.checklistItems.first?.isComplete == false)
    }

    @Test("toggleChecklistItem flips completion")
    func toggleItem() async {
        let service = InertReleaseService()
        let item = CodalonChecklistItem(title: "Test")
        let release = CodalonRelease(projectID: projectID, version: "1.0.0", checklistItems: [item])
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.toggleChecklistItem(item.id)

        #expect(vm.selectedRelease?.checklistItems.first?.isComplete == true)
    }

    @Test("removeChecklistItem removes by ID")
    func removeItem() async {
        let service = InertReleaseService()
        let item = CodalonChecklistItem(title: "Test")
        let release = CodalonRelease(projectID: projectID, version: "1.0.0", checklistItems: [item])
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.removeChecklistItem(item.id)

        #expect(vm.selectedRelease?.checklistItems.isEmpty == true)
    }
}

// MARK: - Blocker Tests (#141)

@Suite("ReleaseViewModel — Blockers")
@MainActor
struct ReleaseViewModelBlockerTests {

    let projectID = UUID()

    @Test("addBlocker appends blocker and updates count")
    func addBlocker() async {
        let service = InertReleaseService()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.addBlocker(title: "Crash", severity: .critical)

        #expect(vm.selectedRelease?.blockers.count == 1)
        #expect(vm.selectedRelease?.blockers.first?.title == "Crash")
        #expect(vm.selectedRelease?.blockers.first?.severity == .critical)
        #expect(vm.selectedRelease?.blockerCount == 1)
    }

    @Test("resolveBlocker marks as resolved and updates count")
    func resolveBlocker() async {
        let service = InertReleaseService()
        let blocker = CodalonReleaseBlocker(title: "Bug", severity: .error)
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            blockerCount: 1,
            blockers: [blocker]
        )
        await service.seed(release)

        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)
        vm.selectedRelease = release

        await vm.resolveBlocker(blocker.id)

        #expect(vm.selectedRelease?.blockers.first?.isResolved == true)
        #expect(vm.selectedRelease?.blockerCount == 0)
    }

    @Test("activeBlockers computed property filters resolved")
    func activeBlockers() {
        let service = InertReleaseService()
        let vm = ReleaseViewModel(releaseService: service, projectID: UUID())
        vm.selectedRelease = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            blockers: [
                CodalonReleaseBlocker(title: "Active", severity: .error),
                CodalonReleaseBlocker(title: "Resolved", severity: .warning, isResolved: true),
            ]
        )

        #expect(vm.activeBlockers.count == 1)
        #expect(vm.activeBlockers.first?.title == "Active")
    }
}

// MARK: - Computed Property Tests

@Suite("ReleaseViewModel — Computed")
@MainActor
struct ReleaseViewModelComputedTests {

    @Test("activeRelease returns first non-terminal")
    func activeRelease() {
        let service = InertReleaseService()
        let projectID = UUID()
        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)

        vm.releases = [
            CodalonRelease(projectID: projectID, version: "0.9.0", status: .released),
            CodalonRelease(projectID: projectID, version: "1.0.0", status: .testing),
            CodalonRelease(projectID: projectID, version: "1.1.0", status: .drafting),
        ]

        #expect(vm.activeRelease?.version == "1.0.0")
    }

    @Test("activeRelease returns nil when all terminal")
    func noActiveRelease() {
        let service = InertReleaseService()
        let projectID = UUID()
        let vm = ReleaseViewModel(releaseService: service, projectID: projectID)

        vm.releases = [
            CodalonRelease(projectID: projectID, version: "0.9.0", status: .released),
            CodalonRelease(projectID: projectID, version: "1.0.0", status: .cancelled),
        ]

        #expect(vm.activeRelease == nil)
    }
}
