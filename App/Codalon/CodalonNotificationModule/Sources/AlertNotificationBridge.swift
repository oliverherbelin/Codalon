// Issue #150 — Local notification delivery via HelaiaNotify

import Foundation
import HelaiaNotify
import HelaiaLogger

// MARK: - Protocol

public protocol AlertNotificationBridgeProtocol: Sendable {
    func deliver(_ alert: CodalonAlert) async
    func requestPermission() async throws -> Bool
}

// MARK: - Implementation

public actor AlertNotificationBridge: AlertNotificationBridgeProtocol {

    private let notificationService: any NotificationServiceProtocol
    private let inAppCenter: InAppNotificationCenter
    private let logger: any HelaiaLoggerProtocol

    public init(
        notificationService: any NotificationServiceProtocol,
        inAppCenter: InAppNotificationCenter,
        logger: any HelaiaLoggerProtocol
    ) {
        self.notificationService = notificationService
        self.inAppCenter = inAppCenter
        self.logger = logger
    }

    public func deliver(_ alert: CodalonAlert) async {
        // Always post in-app notification
        let inAppType = mapSeverityToInAppType(alert.severity)
        let entityLink: NotificationEntityLink? = alert.actionRoute.flatMap { route in
            NotificationEntityLink(
                entityID: alert.id,
                entityType: "alert",
                deepLinkURL: URL(string: "codalon://alert/\(alert.id.uuidString)")!
            )
        }

        let inApp = InAppNotification(
            title: alert.title,
            message: alert.message,
            type: inAppType,
            entityLink: entityLink
        )
        await inAppCenter.post(inApp)

        // Deliver macOS system notification for high-severity alerts
        guard severityShouldNotifySystem(alert.severity) else { return }

        let hasPermission = await notificationService.hasPermission()
        guard hasPermission else {
            logger.warning("No notification permission — skipping system notification for: \(alert.title)", category: "notification")
            return
        }

        let notification = HelaiaNotification(
            id: alert.id.uuidString,
            title: "[\(severityDisplayName(alert.severity))] \(categoryDisplayName(alert.category))",
            body: alert.title,
            trigger: .timeInterval(seconds: 0.5),
            entityLink: entityLink,
            categoryID: alert.category.rawValue
        )

        do {
            try await notificationService.schedule(notification)
            logger.info("System notification scheduled for alert: \(alert.title)", category: "notification")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)", category: "notification")
        }
    }

    public func requestPermission() async throws -> Bool {
        try await notificationService.requestPermission()
    }

    // MARK: - Private

    private func mapSeverityToInAppType(_ severity: CodalonSeverity) -> InAppNotificationType {
        switch severity {
        case .info: .info
        case .warning: .warning
        case .error: .error
        case .critical: .error
        }
    }
}
