// Issues #6, #160, #162, #176 — CodalonInsightModule

import HelaiaEngine
import HelaiaLogger
import HelaiaAI
import HelaiaKeychain

final class CodalonInsightModule: HelaiaModuleProtocol {
    let moduleID = "codalon.insight"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let logger = try await container.resolve(
            (any HelaiaLoggerProtocol).self
        )
        let taskRepository = try await container.resolve(
            (any TaskRepositoryProtocol).self
        )
        let milestoneRepository = try await container.resolve(
            (any MilestoneRepositoryProtocol).self
        )
        let releaseRepository = try await container.resolve(
            (any ReleaseRepositoryProtocol).self
        )
        let alertRepository = try await container.resolve(
            (any AlertRepositoryProtocol).self
        )
        let insightRepository = try await container.resolve(
            (any InsightRepositoryProtocol).self
        )

        // AI Provider Manager
        let keychain = try await container.resolve(
            (any KeychainServiceProtocol).self
        )

        let anthropicProvider = AnthropicProvider(keychain: keychain, logger: logger)
        let openAIProvider = OpenAIProvider(keychain: keychain, logger: logger)
        let ollamaProvider = OllamaProvider(logger: logger)

        let aiManager = HelaiaAI.AIProviderManager(logger: logger)
        await aiManager.register(anthropicProvider)
        await aiManager.register(openAIProvider)
        await aiManager.register(ollamaProvider)

        await container.register(
            HelaiaAI.AIProviderManager.self,
            scope: .singleton
        ) { aiManager }

        // Health Score Service
        let healthScoreService = await MainActor.run {
            HealthScoreService(
                taskRepository: taskRepository,
                milestoneRepository: milestoneRepository,
                releaseRepository: releaseRepository,
                alertRepository: alertRepository,
                logger: logger
            )
        }
        await container.register(
            (any HealthScoreServiceProtocol).self,
            scope: .singleton
        ) { healthScoreService }

        // Rule Engine
        let rules: [any InsightRuleProtocol] = [
            OverdueMilestoneRule(),
            OverdueTaskRule(),
            BlockedReleaseRule(),
            StaleGitHubIssueRule(),
            MissingASCMetadataRule(),
            TooManyCriticalAlertsRule(),
        ]

        let ruleEngine = await MainActor.run {
            InsightRuleEngine(
                rules: rules,
                taskRepository: taskRepository,
                milestoneRepository: milestoneRepository,
                releaseRepository: releaseRepository,
                alertRepository: alertRepository,
                insightRepository: insightRepository,
                logger: logger
            )
        }
        await container.register(
            (any InsightRuleEngineProtocol).self,
            scope: .singleton
        ) { ruleEngine }
    }
}
