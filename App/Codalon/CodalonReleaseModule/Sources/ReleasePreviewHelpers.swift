// Epic 12 — Preview helpers for release module

import Foundation

// MARK: - Preview Service

actor PreviewReleaseService: ReleaseServiceProtocol {
    private var store: [UUID: CodalonRelease] = [:]

    func save(_ release: CodalonRelease) async throws {
        store[release.id] = release
    }
    func load(id: UUID) async throws -> CodalonRelease {
        guard let release = store[id] else { throw ReleaseServiceError.notFound }
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
}

// MARK: - Error

enum ReleaseServiceError: Error {
    case notFound
}

// MARK: - Preview Data

enum ReleasePreviewData {

    static let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!

    static let draftRelease = CodalonRelease(
        projectID: projectID,
        version: "1.0.0",
        buildNumber: "1",
        targetDate: Date().addingTimeInterval(86400 * 14),
        status: .drafting,
        readinessScore: 35,
        checklistItems: [
            CodalonChecklistItem(title: "Code complete", isComplete: true),
            CodalonChecklistItem(title: "QA pass", isComplete: false),
            CodalonChecklistItem(title: "Screenshots updated", isComplete: false),
            CodalonChecklistItem(title: "Metadata complete", isComplete: true),
            CodalonChecklistItem(title: "Localizations verified", isComplete: false),
        ],
        blockerCount: 1,
        blockers: [
            CodalonReleaseBlocker(title: "Crash on cold start", severity: .critical),
            CodalonReleaseBlocker(title: "UI regression in settings", severity: .warning, isResolved: true),
        ]
    )

    static let readyRelease = CodalonRelease(
        projectID: projectID,
        version: "0.9.0",
        buildNumber: "42",
        targetDate: Date().addingTimeInterval(-86400 * 3),
        status: .readyForSubmission,
        readinessScore: 92,
        checklistItems: [
            CodalonChecklistItem(title: "Code complete", isComplete: true),
            CodalonChecklistItem(title: "QA pass", isComplete: true),
            CodalonChecklistItem(title: "Screenshots updated", isComplete: true),
            CodalonChecklistItem(title: "Metadata complete", isComplete: true),
        ]
    )

    static let releasedRelease = CodalonRelease(
        projectID: projectID,
        version: "0.8.0",
        buildNumber: "38",
        status: .released,
        readinessScore: 100
    )
}
