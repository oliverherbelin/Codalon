// Issues #6, #121 — CodalonReleaseModule

import HelaiaEngine
import HelaiaLogger

final class CodalonReleaseModule: HelaiaModuleProtocol {
    let moduleID = "codalon.release"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let logger = try await container.resolve(
            (any HelaiaLoggerProtocol).self
        )
        let repository = try await container.resolve(
            (any ReleaseRepositoryProtocol).self
        )

        let service = await MainActor.run {
            ReleaseService(
                repository: repository,
                logger: logger
            )
        }

        await container.register(
            (any ReleaseServiceProtocol).self,
            scope: .singleton
        ) { service }
    }
}
