// Issue #145 — Insights widget

import SwiftUI
import HelaiaDesign

// MARK: - InsightsWidget

struct InsightsWidget: View {

    // MARK: - Properties

    let insights: [InsightWidgetItem]
    let onViewAll: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(
        insights: [InsightWidgetItem] = [],
        onViewAll: (() -> Void)? = nil
    ) {
        self.insights = insights
        self.onViewAll = onViewAll
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header
                if insights.isEmpty {
                    Text("No active insights")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                } else {
                    ForEach(insights.prefix(3)) { insight in
                        InsightCard(
                            insightType: insight.type,
                            severity: insight.severity,
                            title: insight.title,
                            message: insight.message
                        )
                    }
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "lightbulb.fill",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("INSIGHTS")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
            if let onViewAll, !insights.isEmpty {
                HelaiaButton.ghost("View All", action: onViewAll)
            }
        }
    }
}

// MARK: - InsightWidgetItem

struct InsightWidgetItem: Identifiable, Sendable {
    let id: UUID
    let type: InsightCard.InsightType
    let severity: InsightCard.InsightSeverity
    let title: String
    let message: String
}

// MARK: - Preview

#Preview("InsightsWidget") {
    VStack(spacing: 16) {
        InsightsWidget(
            insights: [
                InsightWidgetItem(
                    id: UUID(),
                    type: .anomaly,
                    severity: .warning,
                    title: "Crash rate spike",
                    message: "Crash rate up 40% in 24 hours"
                ),
                InsightWidgetItem(
                    id: UUID(),
                    type: .suggestion,
                    severity: .info,
                    title: "Split large epic",
                    message: "Epic 4 has 12 tasks"
                ),
                InsightWidgetItem(
                    id: UUID(),
                    type: .trend,
                    severity: .info,
                    title: "Velocity improving",
                    message: "Task completion rate up 15%"
                )
            ],
            onViewAll: {}
        )
        InsightsWidget()
    }
    .padding()
    .frame(width: 400)
}
