// Issues #6, #274 — Epic 1 + Epic 24: CodalonCoreModule — infrastructure & repository registration

import Foundation
import HelaiaEngine
import HelaiaGit
import HelaiaLogger
import HelaiaKeychain
import HelaiaStorage
import HelaiaNotify

final class CodalonCoreModule: HelaiaModuleProtocol {
    let moduleID = "codalon.core"
    let dependencies: [String] = []

    func register(in container: ServiceContainer) async throws {

        // 1. Logger — no dependencies, everything else needs it
        let logger = HelaiaLogger(
            subsystem: "com.helaia.codalon",
            category: "App"
        )
        await container.register(
            (any HelaiaLoggerProtocol).self,
            scope: .singleton
        ) { logger }

        // 2. Keychain — depends on logger
        let keychain = HelaiaKeychainService(logger: logger)
        await container.register(
            (any KeychainServiceProtocol).self,
            scope: .singleton
        ) { keychain }

        // 3. Database + Storage — depends on logger
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("Codalon", isDirectory: true)

        try FileManager.default.createDirectory(
            at: appSupportURL,
            withIntermediateDirectories: true
        )

        let dbURL = appSupportURL.appendingPathComponent("codalon.db")
        let database = try HelaiaDatabase.persistent(at: dbURL, logger: logger)
        let storage = GRDBStorageService(database: database, logger: logger)
        await container.register(
            (any StorageServiceProtocol).self,
            scope: .singleton
        ) { storage }

        // 4. Notification services — depend on logger
        let notificationService = UNNotificationService(logger: logger)
        await container.register(
            (any NotificationServiceProtocol).self,
            scope: .singleton
        ) { notificationService }

        let inAppCenter = InAppNotificationCenter()
        await container.register(
            InAppNotificationCenter.self,
            scope: .singleton
        ) { inAppCenter }

        // 5. Repositories — all depend on storage, MainActor-isolated
        let projectRepo = await MainActor.run { ProjectRepository(storage: storage) }
        await container.register(
            (any ProjectRepositoryProtocol).self,
            scope: .singleton
        ) { projectRepo }

        let taskRepo = await MainActor.run { TaskRepository(storage: storage) }
        await container.register(
            (any TaskRepositoryProtocol).self,
            scope: .singleton
        ) { taskRepo }

        let milestoneRepo = await MainActor.run { MilestoneRepository(storage: storage) }
        await container.register(
            (any MilestoneRepositoryProtocol).self,
            scope: .singleton
        ) { milestoneRepo }

        let releaseRepo = await MainActor.run { ReleaseRepository(storage: storage) }
        await container.register(
            (any ReleaseRepositoryProtocol).self,
            scope: .singleton
        ) { releaseRepo }

        let alertRepo = await MainActor.run { AlertRepository(storage: storage) }
        await container.register(
            (any AlertRepositoryProtocol).self,
            scope: .singleton
        ) { alertRepo }

        let insightRepo = await MainActor.run { InsightRepository(storage: storage) }
        await container.register(
            (any InsightRepositoryProtocol).self,
            scope: .singleton
        ) { insightRepo }

        let decisionLogRepo = await MainActor.run { DecisionLogRepository(storage: storage) }
        await container.register(
            (any DecisionLogRepositoryProtocol).self,
            scope: .singleton
        ) { decisionLogRepo }

        let gitHubRepoRepo = await MainActor.run { GitHubRepoRepository(storage: storage) }
        await container.register(
            (any GitHubRepoRepositoryProtocol).self,
            scope: .singleton
        ) { gitHubRepoRepo }

        // #275 — GitLocalRepoPath repository
        let localRepoPathRepo = await MainActor.run {
            GitLocalRepoPathRepository(storage: storage)
        }
        await container.register(
            (any GitLocalRepoPathRepositoryProtocol).self,
            scope: .singleton
        ) { localRepoPathRepo }

        // #274 — SystemGitService registration (HTTPS+PAT auth)
        let credentialManager = GitCredentialManager(
            keychain: keychain, logger: logger
        )
        let gitService = SystemGitService(
            logger: logger,
            credentialManager: credentialManager
        )
        await container.register(
            (any GitServiceProtocol).self,
            scope: .singleton
        ) { gitService }
    }
}
