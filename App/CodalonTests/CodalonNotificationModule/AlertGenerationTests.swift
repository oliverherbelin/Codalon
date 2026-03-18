// Issue #137 — Alert generation service tests

import Foundation
import Testing
import HelaiaLogger
@testable import Codalon

// MARK: - Mock Alert Repository

private actor MockAlertRepo: AlertRepositoryProtocol {
    var alerts: [CodalonAlert] = []

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
    func delete(id: UUID) async throws { alerts.removeAll { $0.id == id } }
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

// MARK: - Mock Notification Bridge

private actor MockNotificationBridge: AlertNotificationBridgeProtocol {
    var deliveredAlerts: [CodalonAlert] = []

    func deliver(_ alert: CodalonAlert) async {
        deliveredAlerts.append(alert)
    }

    func requestPermission() async throws -> Bool { true }
}

private enum TestError: Error { case notFound }

// MARK: - Tests

@Suite("AlertGenerationTests")
@MainActor
struct AlertGenerationTests {

    let projectID = UUID()

    // MARK: - #137 — Generate Alert

    @Test("generates alert and saves to repository")
    func generatesSavesAlert() async throws {
        let repo = MockAlertRepo()
        let bridge = MockNotificationBridge()
        let service = await MainActor.run {
            AlertGenerationService(
                alertRepository: repo,
                notificationBridge: bridge,
                logger: HelaiaMockLogger()
            )
        }

        let alert = try await service.generateAlert(
            projectID: projectID,
            severity: .warning,
            category: .release,
            title: "Release Blockers",
            message: "2 blockers found",
            actionRoute: nil
        )

        let stored = await repo.alerts
        #expect(stored.count == 1)
        #expect(stored[0].id == alert.id)
        #expect(stored[0].severity == .warning)
    }

    @Test("generates alert from event")
    func generatesFromEvent() async throws {
        let repo = MockAlertRepo()
        let bridge = MockNotificationBridge()
        let service = await MainActor.run {
            AlertGenerationService(
                alertRepository: repo,
                notificationBridge: bridge,
                logger: HelaiaMockLogger()
            )
        }

        let event = AlertTriggerEvent(
            projectID: projectID,
            severity: .critical,
            category: .build,
            title: "Build Failed",
            message: "CI pipeline failed",
            actionRoute: "build/\(projectID.uuidString)"
        )

        let alert = try await service.generateFromEvent(event)
        #expect(alert.severity == .critical)
        #expect(alert.category == .build)
        #expect(alert.actionRoute != nil)
    }

    // MARK: - #150 — System Notification Delivery

    @Test("delivers system notification for critical alerts")
    func deliversNotificationForCritical() async throws {
        let repo = MockAlertRepo()
        let bridge = MockNotificationBridge()
        let service = await MainActor.run {
            AlertGenerationService(
                alertRepository: repo,
                notificationBridge: bridge,
                logger: HelaiaMockLogger()
            )
        }

        _ = try await service.generateAlert(
            projectID: projectID,
            severity: .critical,
            category: .build,
            title: "Build Failed",
            message: "Pipeline error",
            actionRoute: nil
        )

        let delivered = await bridge.deliveredAlerts
        #expect(delivered.count == 1)
        #expect(delivered[0].severity == .critical)
    }

    @Test("skips system notification for info alerts")
    func skipsNotificationForInfo() async throws {
        let repo = MockAlertRepo()
        let bridge = MockNotificationBridge()
        let service = await MainActor.run {
            AlertGenerationService(
                alertRepository: repo,
                notificationBridge: bridge,
                logger: HelaiaMockLogger()
            )
        }

        _ = try await service.generateAlert(
            projectID: projectID,
            severity: .info,
            category: .general,
            title: "Info Update",
            message: "Something informational",
            actionRoute: nil
        )

        let delivered = await bridge.deliveredAlerts
        #expect(delivered.isEmpty)
    }
}
