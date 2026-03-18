// Issue #139 — Preview helpers for alert module

import Foundation

// MARK: - Preview Alert Repository

actor PreviewAlertRepository: AlertRepositoryProtocol {
    private var alerts: [CodalonAlert] = [
        CodalonAlert(
            projectID: UUID(),
            severity: .critical,
            category: .build,
            title: "Build Failed",
            message: "CI build failed on main branch — 3 test failures detected"
        ),
        CodalonAlert(
            projectID: UUID(),
            severity: .warning,
            category: .release,
            title: "Release Blockers",
            message: "Release 1.2.0 has 2 unresolved blockers"
        ),
        CodalonAlert(
            projectID: UUID(),
            severity: .info,
            category: .review,
            title: "New App Store Review",
            message: "4-star review received for version 1.1.0",
            readState: .read
        ),
    ]

    func save(_ alert: CodalonAlert) async throws {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
        } else {
            alerts.append(alert)
        }
    }

    func load(id: UUID) async throws -> CodalonAlert {
        guard let alert = alerts.first(where: { $0.id == id }) else {
            throw PreviewError.notFound
        }
        return alert
    }

    func loadAll() async throws -> [CodalonAlert] { alerts }
    func delete(id: UUID) async throws { alerts.removeAll { $0.id == id } }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert] { alerts }

    func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.readState == .unread }
    }

    func fetchByCategory(_ category: CodalonAlertCategory, projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.category == category }
    }

    func markRead(id: UUID) async throws {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].readState = .read
        }
    }

    func dismiss(id: UUID) async throws {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].readState = .dismissed
        }
    }
}

// MARK: - Preview Dismissal Service

actor PreviewAlertDismissalService: AlertDismissalServiceProtocol {
    func evaluateDismissals(projectID: UUID) async throws -> Int { 0 }
}

// MARK: - Preview Notification Bridge

actor PreviewAlertNotificationBridge: AlertNotificationBridgeProtocol {
    func deliver(_ alert: CodalonAlert) async {}
    func requestPermission() async throws -> Bool { true }
}

private enum PreviewError: Error {
    case notFound
}
