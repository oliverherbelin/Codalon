// Issues #6, #179, #181, #185 — CodalonAppStoreModule

import HelaiaEngine
import HelaiaKeychain
import HelaiaLogger

final class CodalonAppStoreModule: HelaiaModuleProtocol {
    let moduleID = "codalon.appstore"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let keychain = try await container.resolve(
            (any KeychainServiceProtocol).self
        )
        let logger = try await container.resolve(
            (any HelaiaLoggerProtocol).self
        )
        let projectRepository = try await container.resolve(
            (any ProjectRepositoryProtocol).self
        )

        // Credential Service
        let credentialService = await MainActor.run {
            ASCCredentialService(keychain: keychain, logger: logger)
        }
        await container.register(
            (any ASCCredentialServiceProtocol).self,
            scope: .singleton
        ) { credentialService }

        // API Client
        let apiClient = await MainActor.run {
            ASCAPIClient(logger: logger)
        }
        await container.register(
            (any ASCAPIClientProtocol).self,
            scope: .singleton
        ) { apiClient }

        // ASC Service
        let service = await MainActor.run {
            ASCService(
                credentialService: credentialService,
                apiClient: apiClient,
                projectRepository: projectRepository,
                logger: logger
            )
        }
        await container.register(
            (any ASCServiceProtocol).self,
            scope: .singleton
        ) { service }
    }
}
