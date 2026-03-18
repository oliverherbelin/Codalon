// Issues #178, #180 — Insight center view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - InsightViewModel

@Observable
final class InsightViewModel {

    // MARK: - State

    var insights: [CodalonInsight] = []
    var healthResult: HealthScoreResult?
    var isLoading = false
    var errorMessage: String?

    // Issue #178 — Filters
    var severityFilter: CodalonSeverity?
    var typeFilter: CodalonInsightType?

    // MARK: - Dependencies

    private let insightRepository: any InsightRepositoryProtocol
    private let ruleEngine: any InsightRuleEngineProtocol
    private let healthScoreService: any HealthScoreServiceProtocol
    let projectID: UUID

    // MARK: - Init

    init(
        insightRepository: any InsightRepositoryProtocol,
        ruleEngine: any InsightRuleEngineProtocol,
        healthScoreService: any HealthScoreServiceProtocol,
        projectID: UUID
    ) {
        self.insightRepository = insightRepository
        self.ruleEngine = ruleEngine
        self.healthScoreService = healthScoreService
        self.projectID = projectID
    }

    // MARK: - Load

    func loadInsights() async {
        isLoading = true
        do {
            insights = try await insightRepository.fetchByProject(projectID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func runRules() async {
        do {
            let newInsights = try await ruleEngine.runAllRules(projectID: projectID)
            if !newInsights.isEmpty {
                await loadInsights()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recalculateHealth() async {
        do {
            healthResult = try await healthScoreService.recalculate(projectID: projectID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered + Sorted

    /// Insights sorted by severity (descending) then newest first,
    /// with actionable items (anomaly, suggestion) highlighted.
    var filteredInsights: [CodalonInsight] {
        var result = insights.filter { $0.deletedAt == nil }

        if let severityFilter {
            result = result.filter { $0.severity == severityFilter }
        }

        if let typeFilter {
            result = result.filter { $0.type == typeFilter }
        }

        return result.sorted { lhs, rhs in
            if lhs.severity != rhs.severity {
                return lhs.severity > rhs.severity
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var actionableInsights: [CodalonInsight] {
        filteredInsights.filter { $0.type == .anomaly || $0.type == .suggestion }
    }

    var informationalInsights: [CodalonInsight] {
        filteredInsights.filter { $0.type == .trend || $0.type == .reminder }
    }

    var hasActiveFilters: Bool {
        severityFilter != nil || typeFilter != nil
    }

    func clearFilters() {
        severityFilter = nil
        typeFilter = nil
    }

    // MARK: - Health Score Helpers

    var overallScorePercent: Int {
        guard let result = healthResult else { return 0 }
        return Int(result.overallScore * 100)
    }

    /// Returns the dimension dragging the score down most.
    var weakestDimension: HealthScoreDimension? {
        healthResult?.dimensions.min(by: { $0.value < $1.value })
    }
}
