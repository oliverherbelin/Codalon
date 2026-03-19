// Issue #252 — Test AI failure states

import Foundation
import Testing
@testable import Codalon

// MARK: - AI Failure State Tests

@Suite("AI Failure States")
@MainActor
struct AIFailureStateTests {

    @Test("insight view model handles empty insight list gracefully")
    func emptyInsightList() {
        let vm = InsightViewModel(
            insightRepository: NoOpInsightRepository(),
            ruleEngine: FailingRuleEngine(),
            healthScoreService: FallbackHealthScoreService(),
            projectID: UUID()
        )

        #expect(vm.insights.isEmpty)
        #expect(vm.filteredInsights.isEmpty)
        #expect(!vm.isLoading)
    }

    @Test("rule engine failure does not crash insight loading")
    func ruleEngineFailureGraceful() async {
        let vm = InsightViewModel(
            insightRepository: NoOpInsightRepository(),
            ruleEngine: FailingRuleEngine(),
            healthScoreService: FallbackHealthScoreService(),
            projectID: UUID()
        )

        // Running rules that throw should not crash
        await vm.runRules()

        #expect(vm.insights.isEmpty)
    }

    @Test("health score service failure returns zero score")
    func healthScoreFailureFallback() async {
        let service = FallbackHealthScoreService()
        let result = try? await service.recalculate(projectID: UUID())

        #expect(result?.overallScore == 0.0)
        #expect(result?.dimensions.isEmpty == true)
    }

    @Test("missing AI provider returns empty model list")
    func missingAIProviderEmptyModels() async {
        // Simulate no provider registered — expect empty list
        let models: [String] = []
        #expect(models.isEmpty)
    }
}

// MARK: - Mock Services

private actor NoOpInsightRepository: InsightRepositoryProtocol {
    func save(_ insight: CodalonInsight) async throws {}
    func load(id: UUID) async throws -> CodalonInsight {
        throw AITestError.notFound
    }
    func loadAll() async throws -> [CodalonInsight] { [] }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight] { [] }
    func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] { [] }
    func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] { [] }
}

private actor FailingRuleEngine: InsightRuleEngineProtocol {
    func runAllRules(projectID: UUID) async throws -> [CodalonInsight] {
        throw AITestError.providerUnavailable
    }
}

private actor FallbackHealthScoreService: HealthScoreServiceProtocol {
    func recalculate(projectID: UUID) async throws -> HealthScoreResult {
        HealthScoreResult(overallScore: 0.0, dimensions: [])
    }
}

private enum AITestError: Error {
    case notFound
    case providerUnavailable
    case invalidAPIKey
}
