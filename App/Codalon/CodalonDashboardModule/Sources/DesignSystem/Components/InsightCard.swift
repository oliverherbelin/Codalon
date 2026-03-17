// Issue #47 — InsightCard

import SwiftUI
import HelaiaDesign

// MARK: - InsightCard

public struct InsightCard: View {

    // MARK: - Properties

    private let insightType: InsightType
    private let severity: InsightSeverity
    private let title: String
    private let message: String
    private let actionLabel: String?
    private let onAction: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(
        insightType: InsightType,
        severity: InsightSeverity,
        title: String,
        message: String,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.insightType = insightType
        self.severity = severity
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
    }

    // MARK: - Body

    public var body: some View {
        HelaiaCard(variant: .filled, padding: false) {
            HStack(alignment: .top, spacing: CodalonSpacing.zoneGap) {
                HelaiaIconView(
                    insightType.iconName,
                    size: .lg,
                    color: severity.color(for: colorScheme)
                )
                content
                Spacer()
                if let actionLabel, let onAction {
                    HelaiaButton.ghost(actionLabel, action: onAction)
                        .accessibilityHint("Opens \(title) details")
                }
            }
            .padding(CodalonSpacing.cardPadding)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HStack(spacing: Spacing._1_5) {
                Text(insightType.label)
                    .helaiaFont(.tag)
                    .helaiaForeground(.textSecondary)
                    .textCase(.uppercase)
                Circle()
                    .fill(severity.color(for: colorScheme))
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
            Text(title)
                .helaiaFont(.buttonSmall)
            Text(message)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
                .lineLimit(3)
        }
    }
}

// MARK: - InsightType

extension InsightCard {

    public enum InsightType: Sendable {
        case suggestion
        case anomaly
        case trend
        case reminder

        public var iconName: String {
            switch self {
            case .suggestion: "lightbulb.fill"
            case .anomaly: "waveform.path.ecg"
            case .trend: "chart.line.uptrend.xyaxis"
            case .reminder: "bell.fill"
            }
        }

        public var label: String {
            switch self {
            case .suggestion: "Suggestion"
            case .anomaly: "Anomaly"
            case .trend: "Trend"
            case .reminder: "Reminder"
            }
        }
    }
}

// MARK: - InsightSeverity

extension InsightCard {

    public enum InsightSeverity: Sendable {
        case info
        case warning
        case critical

        public func color(for colorScheme: ColorScheme) -> Color {
            switch self {
            case .info: SemanticColor.textSecondary(for: colorScheme)
            case .warning: SemanticColor.warning(for: colorScheme)
            case .critical: SemanticColor.error(for: colorScheme)
            }
        }
    }
}

// MARK: - Preview

#Preview("InsightCard") {
    VStack(spacing: 12) {
        InsightCard(
            insightType: .anomaly,
            severity: .warning,
            title: "Crash rate spike",
            message: "Crash rate increased 40% in the last 24 hours",
            actionLabel: "Investigate",
            onAction: {}
        )
        InsightCard(
            insightType: .suggestion,
            severity: .info,
            title: "Consider splitting epic",
            message: "Epic 4 has 12 tasks — consider breaking it down"
        )
        InsightCard(
            insightType: .trend,
            severity: .info,
            title: "Velocity improving",
            message: "Task completion rate up 15% this sprint"
        )
    }
    .padding()
    .frame(width: 400)
}
