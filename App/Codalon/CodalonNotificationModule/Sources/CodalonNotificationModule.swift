// Issues #6, #131, #134, #137, #150, #156 — CodalonNotificationModule

import HelaiaEngine
import HelaiaLogger
import HelaiaNotify

final class CodalonNotificationModule: HelaiaModuleProtocol {
    let moduleID = "codalon.notification"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let logger = try await container.resolve(
            (any HelaiaLoggerProtocol).self
        )
        let alertRepository = try await container.resolve(
            (any AlertRepositoryProtocol).self
        )
        let releaseRepository = try await container.resolve(
            (any ReleaseRepositoryProtocol).self
        )
        let milestoneRepository = try await container.resolve(
            (any MilestoneRepositoryProtocol).self
        )

        // Issue #156 — Alert dismissal
        let dismissalService = await MainActor.run {
            AlertDismissalService(
                alertRepository: alertRepository,
                releaseRepository: releaseRepository,
                milestoneRepository: milestoneRepository,
                logger: logger
            )
        }

        await container.register(
            (any AlertDismissalServiceProtocol).self,
            scope: .singleton
        ) { dismissalService }

        // Issue #150 — Notification bridge
        let notificationService = try await container.resolve(
            (any NotificationServiceProtocol).self
        )
        let inAppCenter = try await container.resolve(
            InAppNotificationCenter.self
        )

        let bridge = await MainActor.run {
            AlertNotificationBridge(
                notificationService: notificationService,
                inAppCenter: inAppCenter,
                logger: logger
            )
        }

        await container.register(
            (any AlertNotificationBridgeProtocol).self,
            scope: .singleton
        ) { bridge }

        // Issue #137 — Alert generation
        let generationService = await MainActor.run {
            AlertGenerationService(
                alertRepository: alertRepository,
                notificationBridge: bridge,
                logger: logger
            )
        }

        await container.register(
            (any AlertGenerationServiceProtocol).self,
            scope: .singleton
        ) { generationService }
    }
}
