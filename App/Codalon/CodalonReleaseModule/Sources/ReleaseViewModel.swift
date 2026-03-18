// Issues #121, #122, #124, #127, #129, #133, #136, #138, #141, #144, #148, #151 — Release view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - ReleaseViewModel

@Observable
final class ReleaseViewModel {

    // MARK: - State

    var releases: [CodalonRelease] = []
    var selectedRelease: CodalonRelease?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let releaseService: any ReleaseServiceProtocol
    let projectID: UUID

    // MARK: - Init

    init(releaseService: any ReleaseServiceProtocol, projectID: UUID) {
        self.releaseService = releaseService
        self.projectID = projectID
    }

    // MARK: - Issue #121 — CRUD

    func loadReleases() async {
        isLoading = true
        do {
            releases = try await releaseService.fetchByProject(projectID)
                .filter { $0.deletedAt == nil }
                .sorted { ($0.createdAt) > ($1.createdAt) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadRelease(id: UUID) async {
        do {
            selectedRelease = try await releaseService.load(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createRelease(version: String, buildNumber: String, targetDate: Date?, milestoneID: UUID?) async {
        let release = CodalonRelease(
            projectID: projectID,
            version: version,
            buildNumber: buildNumber,
            targetDate: targetDate,
            linkedMilestoneID: milestoneID
        )
        do {
            try await releaseService.save(release)
            await publishOnMain(ReleaseCreatedEvent(
                releaseID: release.id, version: version, projectID: projectID
            ))
            await loadReleases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateRelease(_ release: CodalonRelease) async {
        var updated = release
        updated.updatedAt = .now
        do {
            try await releaseService.save(updated)
            await publishOnMain(ReleaseUpdatedEvent(
                releaseID: updated.id, version: updated.version
            ))
            selectedRelease = updated
            await loadReleases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRelease(id: UUID) async {
        do {
            try await releaseService.delete(id: id)
            selectedRelease = nil
            await loadReleases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #148 — Status Change

    func updateStatus(_ status: CodalonReleaseStatus) async {
        guard var release = selectedRelease else { return }
        let oldStatus = release.status
        release.status = status
        release.updatedAt = .now
        do {
            try await releaseService.save(release)
            await publishOnMain(ReleaseStatusChangedEvent(
                releaseID: release.id, oldStatus: oldStatus, newStatus: status
            ))
            selectedRelease = release
            await loadReleases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #129 — Link Milestone

    func linkMilestone(_ milestoneID: UUID?) async {
        guard var release = selectedRelease else { return }
        release.linkedMilestoneID = milestoneID
        release.updatedAt = .now
        await updateRelease(release)
    }

    // MARK: - Issue #133 — Link Tasks

    func linkTask(_ taskID: UUID) async {
        guard var release = selectedRelease else { return }
        guard !release.linkedTaskIDs.contains(taskID) else { return }
        release.linkedTaskIDs.append(taskID)
        release.updatedAt = .now
        await updateRelease(release)
    }

    func unlinkTask(_ taskID: UUID) async {
        guard var release = selectedRelease else { return }
        release.linkedTaskIDs.removeAll { $0 == taskID }
        release.updatedAt = .now
        await updateRelease(release)
    }

    // MARK: - Issue #136 — Link GitHub Issues

    func linkGitHubIssue(_ issueRef: String) async {
        guard var release = selectedRelease else { return }
        guard !release.linkedGitHubIssueRefs.contains(issueRef) else { return }
        release.linkedGitHubIssueRefs.append(issueRef)
        release.updatedAt = .now
        await updateRelease(release)
    }

    func unlinkGitHubIssue(_ issueRef: String) async {
        guard var release = selectedRelease else { return }
        release.linkedGitHubIssueRefs.removeAll { $0 == issueRef }
        release.updatedAt = .now
        await updateRelease(release)
    }

    // MARK: - Issue #138 — Checklist

    func toggleChecklistItem(_ itemID: UUID) async {
        guard var release = selectedRelease else { return }
        guard let index = release.checklistItems.firstIndex(where: { $0.id == itemID }) else { return }
        release.checklistItems[index].isComplete.toggle()
        release.updatedAt = .now
        recalculateReadiness(&release)
        await updateRelease(release)
    }

    func addChecklistItem(title: String) async {
        guard var release = selectedRelease else { return }
        release.checklistItems.append(CodalonChecklistItem(title: title))
        release.updatedAt = .now
        recalculateReadiness(&release)
        await updateRelease(release)
    }

    func removeChecklistItem(_ itemID: UUID) async {
        guard var release = selectedRelease else { return }
        release.checklistItems.removeAll { $0.id == itemID }
        release.updatedAt = .now
        recalculateReadiness(&release)
        await updateRelease(release)
    }

    // MARK: - Issue #141 — Blockers

    func addBlocker(title: String, severity: CodalonSeverity) async {
        guard var release = selectedRelease else { return }
        release.blockers.append(CodalonReleaseBlocker(title: title, severity: severity))
        release.blockerCount = release.blockers.filter { !$0.isResolved }.count
        release.updatedAt = .now
        recalculateReadiness(&release)
        await updateRelease(release)
    }

    func resolveBlocker(_ blockerID: UUID) async {
        guard var release = selectedRelease else { return }
        guard let index = release.blockers.firstIndex(where: { $0.id == blockerID }) else { return }
        release.blockers[index].isResolved = true
        release.blockerCount = release.blockers.filter { !$0.isResolved }.count
        release.updatedAt = .now
        recalculateReadiness(&release)
        await updateRelease(release)
    }

    // MARK: - Issue #144 — Readiness

    private func recalculateReadiness(_ release: inout CodalonRelease) {
        let oldScore = release.readinessScore
        release.readinessScore = ReleaseReadinessCalculator.score(for: release)
        if oldScore != release.readinessScore {
            let releaseID = release.id
            let newScore = release.readinessScore
            Task {
                await publishOnMain(ReleaseReadinessChangedEvent(
                    releaseID: releaseID, oldScore: oldScore, newScore: newScore
                ))
            }
        }
    }

    // MARK: - Computed

    var activeRelease: CodalonRelease? {
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]
        return releases.first { !terminalStatuses.contains($0.status) }
    }

    var activeBlockers: [CodalonReleaseBlocker] {
        selectedRelease?.blockers.filter { !$0.isResolved } ?? []
    }

    // MARK: - Private

    private func publishOnMain<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}
