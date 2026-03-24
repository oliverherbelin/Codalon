// Issues #125, #190, #258 — Main dashboard view with context routing

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaLogger

// MARK: - DashboardView

struct DashboardView: View {

    // MARK: - Environment

    @Environment(CodalonShellState.self) private var shellState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var refreshState = DashboardRefreshState()
    @State private var commits: [CommitRowData] = []
    @State private var currentBranch: String = "main"
    @State private var attentionItems: [AttentionWidgetItem] = []
    @State private var gitStateSubscription: SubscriptionToken?

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: CodalonSpacing.zoneGap) {
                // Top strip: summary + health + release
                DashboardStrip(items: stripItems(for: context))
                    .dashboardWidgetAppearance(delay: 0)

                // Main canvas area — routed by context
                contextCanvas
                    .dashboardWidgetAppearance(delay: 0.04)

                // Bottom row: attention, alerts, insights
                HStack(spacing: CodalonSpacing.zoneGap) {
                    AttentionWidget(items: attentionItems)
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.16)

                    AlertWidget()
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.20)

                    InsightsWidget()
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.24)
                }
            }
            .padding(24)
        }
        .task {
            await loadCommits()
            await runInsightRules()
            await loadAttentionItems()
            subscribeToGitStateChanges()
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: Spacing._2) {
                DashboardShareButton(
                    project: nil,
                    summary: nil,
                    milestones: []
                )
                refreshButton
            }
            .padding(24)
        }
    }

    // MARK: - Context Canvas Routing

    @ViewBuilder
    private var contextCanvas: some View {
        switch context {
        case .development:
            DevelopmentModeCanvas(
                commits: commits,
                currentBranch: currentBranch,
                onOpenLocalPanel: { shellState.isLocalGitPanelVisible = true }
            )
        case .release:
            ReleaseModeCanvas()
        case .launch:
            LaunchModeCanvas()
        case .maintenance:
            MaintenanceModeCanvas()
        }
    }

    // MARK: - Strip Items Per Context

    private func stripItems(for context: CodalonContext) -> [DashboardStrip.Item] {
        switch context {
        case .development:
            [
                .init(id: "tasks", label: "Open Tasks", value: "—"),
                .init(id: "health", label: "Health", value: "—"),
                .init(id: "milestone", label: "Milestone", value: "—")
            ]
        case .release:
            [
                .init(id: "readiness", label: "Readiness", value: "—"),
                .init(id: "blockers", label: "Blockers", value: "—"),
                .init(id: "release", label: "Release", value: "—")
            ]
        case .launch:
            [
                .init(id: "version", label: "Version", value: "—"),
                .init(id: "crashes", label: "Crash Rate", value: "—"),
                .init(id: "reviews", label: "Reviews", value: "—")
            ]
        case .maintenance:
            [
                .init(id: "health", label: "Health", value: "—"),
                .init(id: "bugs", label: "Open Bugs", value: "—"),
                .init(id: "lastRelease", label: "Last Release", value: "—")
            ]
        }
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private var refreshButton: some View {
        Button {
            refreshState.beginGlobalRefresh()
            Task { @MainActor in
                await loadCommits()
                await runInsightRules()
                await loadAttentionItems()
                refreshState.endGlobalRefresh()
            }
        } label: {
            HelaiaIconView(
                "arrow.clockwise",
                size: .sm,
                color: refreshState.isRefreshing
                    ? SemanticColor.textTertiary(for: colorScheme)
                    : SemanticColor.textSecondary(for: colorScheme)
            )
            .rotationEffect(
                .degrees(refreshState.isRefreshing ? 360 : 0)
            )
            .animation(
                refreshState.isRefreshing
                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                    : .default,
                value: refreshState.isRefreshing
            )
        }
        .buttonStyle(.plain)
        .disabled(refreshState.isRefreshing)
        .accessibilityLabel("Refresh dashboard")
    }

    // MARK: - Issue #258 — Load Commits

    private func loadCommits() async {
        guard let projectID = shellState.selectedProjectID else { return }

        let container = ServiceContainer.shared
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )
        guard let gitHubService = await container.resolveOptional(
            (any GitHubServiceProtocol).self
        ) else {
            logger?.warning("loadCommits: GitHubService not available", category: "dashboard")
            return
        }

        do {
            let linkedRepos = try await gitHubService.linkedRepos(projectID: projectID)
            logger?.info(
                "loadCommits: found \(linkedRepos.count) linked repo(s) for project \(projectID)",
                category: "dashboard"
            )
            guard let repo = linkedRepos.first else { return }

            currentBranch = repo.defaultBranch
            let dtos = try await gitHubService.fetchCommits(
                owner: repo.owner,
                repo: repo.name,
                limit: 15
            )
            commits = dtos.map { dto in
                CommitRowData(
                    hash: dto.sha,
                    message: String(dto.commit.message.prefix(while: { $0 != "\n" })),
                    fullMessage: dto.commit.message,
                    timeAgo: dto.commit.committer.date.timeAgoDisplay(),
                    relatedRefs: parseRefs(from: dto.commit.message)
                )
            }
            logger?.info("loadCommits: loaded \(commits.count) commits", category: "dashboard")
        } catch {
            logger?.error("loadCommits: failed — \(error)", category: "dashboard")
        }
    }

    // Issue #176 — Run insight rules on dashboard load
    private func runInsightRules() async {
        guard let projectID = shellState.selectedProjectID else { return }

        let container = ServiceContainer.shared
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )

        guard let ruleEngine = await container.resolveOptional(
            (any InsightRuleEngineProtocol).self
        ) else {
            logger?.warning("runInsightRules: InsightRuleEngineProtocol not available", category: "insight-git")
            return
        }

        do {
            logger?.info("runInsightRules: triggering for project \(projectID)", category: "insight-git")
            let newInsights = try await ruleEngine.runAllRules(projectID: projectID)
            logger?.info("runInsightRules: \(newInsights.count) new insight(s) created", category: "insight-git")
        } catch {
            logger?.error("runInsightRules: failed — \(error.localizedDescription)", category: "insight-git")
        }
    }

    // Issue #176 — Subscribe to git state changes for reactive insight refresh
    private func subscribeToGitStateChanges() {
        gitStateSubscription = EventBus.shared.subscribe(
            to: LocalGitStateChangedEvent.self
        ) { event in
            await runInsightRulesWithState(event)
            await loadAttentionItems()
        }
    }

    // Issue #176 — Run insight rules with git state from event (avoids stale bookmark)
    private func runInsightRulesWithState(_ event: LocalGitStateChangedEvent) async {
        let container = ServiceContainer.shared
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )

        guard let ruleEngine = await container.resolveOptional(
            (any InsightRuleEngineProtocol).self
        ) else {
            logger?.warning("runInsightRulesWithState: InsightRuleEngineProtocol not available", category: "insight-git")
            return
        }

        do {
            logger?.info(
                "runInsightRulesWithState: project=\(event.projectID) unstaged=\(event.unstagedCount) staged=\(event.stagedCount) ahead=\(event.aheadCount)",
                category: "insight-git"
            )
            let newInsights = try await ruleEngine.runAllRules(
                projectID: event.projectID,
                localUnstagedCount: event.unstagedCount,
                localStagedCount: event.stagedCount,
                localAheadCount: event.aheadCount
            )
            logger?.info("runInsightRulesWithState: \(newInsights.count) new insight(s) created", category: "insight-git")
        } catch {
            logger?.error("runInsightRulesWithState: failed — \(error.localizedDescription)", category: "insight-git")
        }
    }

    // Issue #176 — Load attention items from InsightRepository after rules run
    private func loadAttentionItems() async {
        guard let projectID = shellState.selectedProjectID else { return }

        let container = ServiceContainer.shared
        let logger = await container.resolveOptional(
            (any HelaiaLoggerProtocol).self
        )
        guard let insightRepository = await container.resolveOptional(
            (any InsightRepositoryProtocol).self
        ) else {
            logger?.warning("loadAttentionItems: InsightRepository not available", category: "dashboard")
            return
        }

        do {
            let insights: [CodalonInsight] = try await insightRepository.fetchByProject(projectID)
            let active: [CodalonInsight] = insights
                .filter { $0.deletedAt == nil }
                .sorted { $0.severity > $1.severity }

            var items: [AttentionWidgetItem] = []
            for insight in active {
                var action: (@MainActor () -> Void)?
                if let route = AlertRoute.parse(insight.actionRoute) {
                    action = { [shellState] in
                        DashboardView.handleRoute(route, shellState: shellState)
                    }
                }
                items.append(AttentionWidgetItem(
                    id: insight.id,
                    severity: insight.severity.attentionSeverity,
                    title: insight.title,
                    message: insight.message,
                    onAction: action,
                    actionRoute: insight.actionRoute
                ))
            }
            attentionItems = items
            logger?.info(
                "loadAttentionItems: \(attentionItems.count) attention item(s) loaded",
                category: "dashboard"
            )
        } catch {
            logger?.error("loadAttentionItems: failed — \(error)", category: "dashboard")
        }
    }

    // Issue #176 — Route attention card taps to the relevant panel
    @MainActor
    private static func handleRoute(_ route: AlertRoute, shellState: CodalonShellState) {
        switch route {
        case .localGitPanel:
            shellState.isLocalGitPanelVisible = true

        case let .release(_, releaseID):
            shellState.activeReleaseID = releaseID
            shellState.inspectorSelection = .release(releaseID)
            shellState.isInspectorVisible = true

        case let .milestone(_, milestoneID):
            shellState.inspectorSelection = .milestone(milestoneID)
            shellState.isInspectorVisible = true

        case .build:
            // Build route — no dedicated panel yet
            break

        case .appStore:
            // App Store route — no dedicated panel yet
            break

        case let .insight(_, insightID):
            // Could open insight detail in the future
            _ = insightID

        case .settings:
            break

        case .unknown:
            break
        }
    }

    private func parseRefs(from message: String) -> [String] {
        let pattern = #"#\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(message.startIndex..., in: message)
        return regex.matches(in: message, range: range).compactMap { match in
            Range(match.range, in: message).map { String(message[$0]) }
        }
    }
}

// MARK: - Date Formatting

private extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        if days < 30 { return "\(days)d" }
        let months = days / 30
        return "\(months)mo"
    }
}

// MARK: - Preview

#Preview("DashboardView — Development") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(CodalonShellState())
        .environment(\.projectContext, .development)
}

#Preview("DashboardView — Release") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(CodalonShellState())
        .environment(\.projectContext, .release)
}

#Preview("DashboardView — Launch") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(CodalonShellState())
        .environment(\.projectContext, .launch)
}

#Preview("DashboardView — Maintenance") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(CodalonShellState())
        .environment(\.projectContext, .maintenance)
}
