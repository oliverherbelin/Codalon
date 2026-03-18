// Issue #137 — Alert generation service

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol AlertGenerationServiceProtocol: Sendable {
    func generateAlert(
        projectID: UUID,
        severity: CodalonSeverity,
        category: CodalonAlertCategory,
        title: String,
        message: String,
        actionRoute: String?
    ) async throws -> CodalonAlert

    func generateFromEvent(_ event: AlertTriggerEvent) async throws -> CodalonAlert
}

// MARK: - Alert Trigger Event

public struct AlertTriggerEvent: Sendable {
    public let projectID: UUID
    public let severity: CodalonSeverity
    public let category: CodalonAlertCategory
    public let title: String
    public let message: String
    public let actionRoute: String?

    public init(
        projectID: UUID,
        severity: CodalonSeverity,
        category: CodalonAlertCategory,
        title: String,
        message: String,
        actionRoute: String? = nil
    ) {
        self.projectID = projectID
        self.severity = severity
        self.category = category
        self.title = title
        self.message = message
        self.actionRoute = actionRoute
    }
}

// MARK: - Implementation

public actor AlertGenerationService: AlertGenerationServiceProtocol {

    private let alertRepository: any AlertRepositoryProtocol
    private let notificationBridge: any AlertNotificationBridgeProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        alertRepository: any AlertRepositoryProtocol,
        notificationBridge: any AlertNotificationBridgeProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.alertRepository = alertRepository
        self.notificationBridge = notificationBridge
        self.logger = logger
    }

    public func generateAlert(
        projectID: UUID,
        severity: CodalonSeverity,
        category: CodalonAlertCategory,
        title: String,
        message: String,
        actionRoute: String?
    ) async throws -> CodalonAlert {
        let alert = CodalonAlert(
            projectID: projectID,
            severity: severity,
            category: category,
            title: title,
            message: message,
            actionRoute: actionRoute
        )

        try await alertRepository.save(alert)
        logger.info("Generated alert: [\(severity.rawValue)] \(title)", category: "notification")

        // Deliver system notification for high-severity alerts
        if severityShouldNotifySystem(severity) {
            await notificationBridge.deliver(alert)
        }

        // Publish event for UI reactivity
        await publish(AlertGeneratedEvent(alertID: alert.id, projectID: projectID, severity: severity))

        return alert
    }

    public func generateFromEvent(_ event: AlertTriggerEvent) async throws -> CodalonAlert {
        try await generateAlert(
            projectID: event.projectID,
            severity: event.severity,
            category: event.category,
            title: event.title,
            message: event.message,
            actionRoute: event.actionRoute
        )
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}

// MARK: - Events

public struct AlertGeneratedEvent: HelaiaEvent {
    public let timestamp: Date
    public let alertID: UUID
    public let projectID: UUID
    public let severity: CodalonSeverity

    public init(
        alertID: UUID,
        projectID: UUID,
        severity: CodalonSeverity,
        timestamp: Date = .now
    ) {
        self.timestamp = timestamp
        self.alertID = alertID
        self.projectID = projectID
        self.severity = severity
    }
}
