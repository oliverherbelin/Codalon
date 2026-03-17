// Issue #125 — Main dashboard view

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
            let canvasHeight = geo.size.height

            VStack(spacing: CodalonSpacing.zoneGap) {
                // Top strip: summary + health + release
                DashboardStrip(items: previewStripItems)
                    .dashboardWidgetAppearance(delay: 0)

                // Main canvas area
                DevelopmentModeCanvas()
                    .dashboardWidgetAppearance(delay: 0.04)

                // Bottom row: attention, alerts, insights, recent
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
            refreshButton
                .padding(24)
        }
    }

    // MARK: - Refresh Button

    @ViewBuilder
    private var refreshButton: some View {
        Button {
            refreshState.beginGlobalRefresh()
            // EventBus publish would go here
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

    // MARK: - Preview Strip Items

    private var previewStripItems: [DashboardStrip.Item] {
        [
            .init(id: "tasks", label: "Open Tasks", value: "—"),
            .init(id: "health", label: "Health", value: "—"),
            .init(id: "release", label: "Release", value: "—")
        ]
    }
}

// MARK: - Preview

#Preview("DashboardView") {
    DashboardView()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .development)
}
