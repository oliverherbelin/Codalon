// Issues #6, #156 — CodalonNotificationModule

import HelaiaEngine
import HelaiaLogger

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

        let service = await MainActor.run {
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
        ) { service }
    }
}
