// Issue #158 — Notification tests: alert generation, severity mapping, dismissal

import Foundation
import Testing
import HelaiaLogger
@testable import Codalon

// MARK: - Preview Repositories for Testing

private actor MockAlertRepository: AlertRepositoryProtocol {
    var alerts: [CodalonAlert] = []
    var dismissedIDs: [UUID] = []

    func save(_ alert: CodalonAlert) async throws {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
        } else {
            alerts.append(alert)
        }
    }
    func load(id: UUID) async throws -> CodalonAlert {
        guard let alert = alerts.first(where: { $0.id == id }) else {
            throw TestError.notFound
        }
        return alert
    }
    func loadAll() async throws -> [CodalonAlert] { alerts }
    func delete(id: UUID) async throws {
        alerts.removeAll { $0.id == id }
    }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID }
    }
    func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID && $0.readState == .unread }
    }
    func fetchByCategory(_ category: CodalonAlertCategory, projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID && $0.category == category }
    }
    func markRead(id: UUID) async throws {
        guard let index = alerts.firstIndex(where: { $0.id == id }) else { return }
        alerts[index].readState = .read
    }
    func dismiss(id: UUID) async throws {
        guard let index = alerts.firstIndex(where: { $0.id == id }) else { return }
        alerts[index].readState = .dismissed
        dismissedIDs.append(id)
    }
}

private actor MockReleaseRepository: ReleaseRepositoryProtocol {
    var releases: [CodalonRelease] = []

    func save(_ release: CodalonRelease) async throws {
        if let index = releases.firstIndex(where: { $0.id == release.id }) {
            releases[index] = release
        } else {
            releases.append(release)
        }
    }
    func load(id: UUID) async throws -> CodalonRelease {
        guard let r = releases.first(where: { $0.id == id }) else {
            throw TestError.notFound
        }
        return r
    }
    func delete(id: UUID) async throws {
        releases.removeAll { $0.id == id }
    }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        releases.filter { $0.projectID == projectID }
    }
    func loadAll() async throws -> [CodalonRelease] { releases }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? {
        let terminal: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]
        return releases.first { $0.projectID == projectID && !terminal.contains($0.status) }
    }
    func fetchByStatus(_ status: CodalonReleaseStatus, projectID: UUID) async throws -> [CodalonRelease] {
        releases.filter { $0.projectID == projectID && $0.status == status }
    }
}

private actor MockMilestoneRepository: MilestoneRepositoryProtocol {
    var milestones: [CodalonMilestone] = []

    func save(_ milestone: CodalonMilestone) async throws {
        milestones.append(milestone)
    }
    func load(id: UUID) async throws -> CodalonMilestone {
        guard let m = milestones.first(where: { $0.id == id }) else {
            throw TestError.notFound
        }
        return m
    }
    func loadAll() async throws -> [CodalonMilestone] { milestones }
    func delete(id: UUID) async throws {
        milestones.removeAll { $0.id == id }
    }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        milestones.filter { $0.projectID == projectID }
    }
    func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone] {
        milestones.filter { $0.projectID == projectID && $0.status == status }
    }
    func fetchOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private enum TestError: Error {
    case notFound
}

// Uses HelaiaMockLogger from HelaiaLogger framework

// MARK: - Tests

@Suite("AlertDismissalService")
struct AlertDismissalTests {

    let projectID = UUID()

    @Test("dismisses release blocker alert when blockers resolved")
    func dismissesBlockerAlert() async throws {
        let alertRepo = MockAlertRepository()
        let releaseRepo = MockReleaseRepository()
        let milestoneRepo = MockMilestoneRepository()

        // Release with zero blockers
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            blockerCount: 0
        )
        try await releaseRepo.save(release)

        // Alert about blockers
        let alert = CodalonAlert(
            projectID: projectID,
            severity: .warning,
            category: .release,
            title: "Release has 2 blockers",
            message: "Resolve blockers before shipping"
        )
        try await alertRepo.save(alert)

        let service = await MainActor.run {
            AlertDismissalService(
                alertRepository: alertRepo,
                releaseRepository: releaseRepo,
                milestoneRepository: milestoneRepo,
                logger: HelaiaMockLogger()
            )
        }

        let dismissed = try await service.evaluateDismissals(projectID: projectID)
        #expect(dismissed == 1)

        let updated = try await alertRepo.load(id: alert.id)
        #expect(updated.readState == .dismissed)
    }

    @Test("does not dismiss alert when blockers still exist")
    func doesNotDismissWithActiveBlockers() async throws {
        let alertRepo = MockAlertRepository()
        let releaseRepo = MockReleaseRepository()
        let milestoneRepo = MockMilestoneRepository()

        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            blockerCount: 1,
            blockers: [CodalonReleaseBlocker(title: "Bug")]
        )
        try await releaseRepo.save(release)

        let alert = CodalonAlert(
            projectID: projectID,
            severity: .warning,
            category: .release,
            title: "Release has blocker issues",
            message: "Fix them"
        )
        try await alertRepo.save(alert)

        let service = await MainActor.run {
            AlertDismissalService(
                alertRepository: alertRepo,
                releaseRepository: releaseRepo,
                milestoneRepository: milestoneRepo,
                logger: HelaiaMockLogger()
            )
        }

        let dismissed = try await service.evaluateDismissals(projectID: projectID)
        #expect(dismissed == 0)
    }

    @Test("dismisses milestone alert when milestone completed")
    func dismissesMilestoneAlert() async throws {
        let alertRepo = MockAlertRepository()
        let releaseRepo = MockReleaseRepository()
        let milestoneRepo = MockMilestoneRepository()

        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Beta Release",
            status: .completed
        )
        try await milestoneRepo.save(milestone)

        let alert = CodalonAlert(
            projectID: projectID,
            severity: .info,
            category: .milestone,
            title: "Beta Release overdue",
            message: "Milestone was due yesterday"
        )
        try await alertRepo.save(alert)

        let service = await MainActor.run {
            AlertDismissalService(
                alertRepository: alertRepo,
                releaseRepository: releaseRepo,
                milestoneRepository: milestoneRepo,
                logger: HelaiaMockLogger()
            )
        }

        let dismissed = try await service.evaluateDismissals(projectID: projectID)
        #expect(dismissed == 1)
    }

    @Test("severity mapping — critical alert stays unread")
    func criticalAlertStaysIfUnresolved() async throws {
        let alertRepo = MockAlertRepository()
        let releaseRepo = MockReleaseRepository()
        let milestoneRepo = MockMilestoneRepository()

        let alert = CodalonAlert(
            projectID: projectID,
            severity: .critical,
            category: .security,
            title: "Security vulnerability detected",
            message: "Urgent fix needed"
        )
        try await alertRepo.save(alert)

        let service = await MainActor.run {
            AlertDismissalService(
                alertRepository: alertRepo,
                releaseRepository: releaseRepo,
                milestoneRepository: milestoneRepo,
                logger: HelaiaMockLogger()
            )
        }

        let dismissed = try await service.evaluateDismissals(projectID: projectID)
        #expect(dismissed == 0)
    }
}
