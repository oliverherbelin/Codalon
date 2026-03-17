// Issue #45 — AttentionCard

import SwiftUI
import HelaiaDesign

// MARK: - AttentionCard

public struct AttentionCard: View {

    // MARK: - Properties

    private let severity: Severity
    private let title: String
    private let message: String
    private let actionLabel: String?
    private let onAction: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(
        severity: Severity,
        title: String,
        message: String,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.severity = severity
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
    }

    // MARK: - Body

    public var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            HStack(spacing: CodalonSpacing.zoneGap) {
                severityIndicator
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

    // MARK: - Severity Indicator

    @ViewBuilder
    private var severityIndicator: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(severity.color(for: colorScheme))
            .frame(width: 4, height: 40)
            .accessibilityHidden(true)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(severity.iconName, size: .xs, color: severity.color(for: colorScheme))
                Text(title)
                    .helaiaFont(.buttonSmall)
            }
            Text(message)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
                .lineLimit(2)
        }
    }
}

// MARK: - Severity

extension AttentionCard {

    public enum Severity: Sendable {
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

        public var iconName: String {
            switch self {
            case .info: "info.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .critical: "xmark.octagon.fill"
            }
        }
    }
}

// MARK: - Preview

#Preview("AttentionCard") {
    VStack(spacing: 12) {
        AttentionCard(
            severity: .critical,
            title: "3 Blockers",
            message: "Release 1.2.0 has unresolved blockers",
            actionLabel: "View",
            onAction: {}
        )
        AttentionCard(
            severity: .warning,
            title: "Milestone Overdue",
            message: "Beta milestone was due 2 days ago"
        )
        AttentionCard(
            severity: .info,
            title: "New Review",
            message: "App Store review received"
        )
    }
    .padding()
    .frame(width: 400)
}
