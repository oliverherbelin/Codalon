// Issue #180 — Display health breakdown

import SwiftUI
import HelaiaDesign

// MARK: - HealthBreakdownView

struct HealthBreakdownView: View {

    // MARK: - State

    @State private var viewModel: InsightViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: InsightViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            header
            overallScore
            dimensionList
            weakestDimensionCallout
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.recalculateHealth()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "heart.text.square.fill",
                size: .md,
                color: SemanticColor.textPrimary(for: colorScheme)
            )
            Text("Project Health")
                .helaiaFont(.headline)
            Spacer()
        }
    }

    // MARK: - Overall Score

    @ViewBuilder
    private var overallScore: some View {
        if let result = viewModel.healthResult {
            HelaiaCard(variant: .outlined, padding: false) {
                HStack(spacing: CodalonSpacing.zoneGap) {
                    HelaiaProgressRing(
                        value: result.overallScore,
                        size: 64,
                        lineWidth: 6,
                        label: "\(viewModel.overallScorePercent)%"
                    )
                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("Overall Health")
                            .helaiaFont(.buttonSmall)
                        Text(scoreLabel(result.overallScore))
                            .helaiaFont(.caption1)
                            .foregroundStyle(scoreColor(result.overallScore))
                    }
                    Spacer()
                }
                .padding(CodalonSpacing.cardPadding)
            }
        } else {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, Spacing._4)
        }
    }

    // MARK: - Dimension List

    @ViewBuilder
    private var dimensionList: some View {
        if let dimensions = viewModel.healthResult?.dimensions {
            VStack(spacing: Spacing._2) {
                ForEach(dimensions) { dimension in
                    DimensionRowView(dimension: dimension)
                }
            }
        }
    }

    // MARK: - Weakest Dimension Callout

    @ViewBuilder
    private var weakestDimensionCallout: some View {
        if let weakest = viewModel.weakestDimension, weakest.value < 0.7 {
            AttentionCard(
                severity: weakest.value < 0.4 ? .critical : .warning,
                title: "\(weakest.label) needs attention",
                message: "\(weakest.label) is at \(Int(weakest.value * 100))% — the lowest dimension dragging your score down."
            )
        }
    }

    // MARK: - Helpers

    private func scoreLabel(_ score: Double) -> String {
        switch score {
        case 0.8...: "Healthy"
        case 0.6..<0.8: "Needs Attention"
        case 0.4..<0.6: "At Risk"
        default: "Critical"
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: SemanticColor.success(for: colorScheme)
        case 0.6..<0.8: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.error(for: colorScheme)
        }
    }
}

// MARK: - DimensionRowView

struct DimensionRowView: View {

    let dimension: HealthScoreDimension

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HelaiaCard(variant: .filled, padding: false) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    dimensionIcon(dimension.id),
                    size: .sm,
                    color: dimensionColor
                )
                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    HStack {
                        Text(dimension.label)
                            .helaiaFont(.buttonSmall)
                        Spacer()
                        Text("\(Int(dimension.value * 100))%")
                            .helaiaFont(.buttonSmall)
                            .codalonMonospaced()
                            .foregroundStyle(dimensionColor)
                    }
                    HelaiaProgressBar(
                        value: dimension.value,
                        color: dimensionColor,
                        height: .thin
                    )
                }
            }
            .padding(Spacing._3)
        }
    }

    private var dimensionColor: Color {
        switch dimension.value {
        case 0.8...: SemanticColor.success(for: colorScheme)
        case 0.6..<0.8: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.error(for: colorScheme)
        }
    }
}

// MARK: - Dimension Icon Helper

nonisolated func dimensionIcon(_ dimensionID: String) -> String {
    switch dimensionID {
    case HealthScoreDimensionID.planning: "list.bullet.clipboard"
    case HealthScoreDimensionID.release: "shippingbox"
    case HealthScoreDimensionID.github: "network"
    case HealthScoreDimensionID.store: "storefront"
    default: "chart.bar"
    }
}

// MARK: - Preview

#Preview("HealthBreakdownView") {
    let projectID = UUID()
    HealthBreakdownView(
        viewModel: InsightViewModel(
            insightRepository: PreviewInsightRepository(projectID: projectID),
            ruleEngine: PreviewRuleEngine(),
            healthScoreService: PreviewHealthScoreService(),
            projectID: projectID
        )
    )
    .frame(width: 500, height: 600)
}
