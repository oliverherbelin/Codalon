// Issues #125, #190 — Main dashboard view with context routing

import SwiftUI
import HelaiaDesign
import HelaiaEngine

// MARK: - DashboardView

struct DashboardView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var refreshState = DashboardRefreshState()

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
                    AttentionWidget()
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
            DevelopmentModeCanvas()
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
                try? await Task.sleep(for: .milliseconds(500))
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
}

// MARK: - Preview

#Preview("DashboardView — Development") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .development)
}

#Preview("DashboardView — Release") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .release)
}

#Preview("DashboardView — Launch") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .launch)
}

#Preview("DashboardView — Maintenance") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .maintenance)
}
