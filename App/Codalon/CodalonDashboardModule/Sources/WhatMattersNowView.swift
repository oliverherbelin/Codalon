// Issue #198 — What-matters-now surface

import SwiftUI
import HelaiaDesign

// MARK: - WhatMattersNowItem

/// The single most important action or fact for the current context.
public struct WhatMattersNowItem: Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let actionLabel: String?

    public init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        actionLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.actionLabel = actionLabel
    }
}

// MARK: - WhatMattersNowConfig

/// Produces the "what matters now" item for each context.
public enum WhatMattersNowConfig {

    public static func placeholder(for context: CodalonContext) -> WhatMattersNowItem {
        switch context {
        case .development:
            WhatMattersNowItem(
                id: "dev-focus",
                title: "Focus on current milestone",
                subtitle: "Complete open tasks to stay on track",
                iconName: "flag.fill",
                actionLabel: "View Tasks"
            )
        case .release:
            WhatMattersNowItem(
                id: "release-focus",
                title: "Resolve blockers before submission",
                subtitle: "Clear all blockers to unblock the release",
                iconName: "xmark.octagon.fill",
                actionLabel: "View Blockers"
            )
        case .launch:
            WhatMattersNowItem(
                id: "launch-focus",
                title: "Monitor post-launch metrics",
                subtitle: "Watch crash rates and early reviews",
                iconName: "chart.line.uptrend.xyaxis",
                actionLabel: "View Metrics"
            )
        case .maintenance:
            WhatMattersNowItem(
                id: "maintenance-focus",
                title: "Keep the project healthy",
                subtitle: "Review open bugs and dependency updates",
                iconName: "wrench.and.screwdriver.fill",
                actionLabel: "View Health"
            )
        }
    }
}

// MARK: - WhatMattersNowView

/// Persistent header strip showing the single most important action
/// for the current context. Appears above the dashboard canvas.
struct WhatMattersNowView: View {

    // MARK: - Properties

    let item: WhatMattersNowItem
    let onAction: (() -> Void)?

    // MARK: - Environment

    @Environment(\.projectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    init(item: WhatMattersNowItem, onAction: (() -> Void)? = nil) {
        self.item = item
        self.onAction = onAction
    }

    // MARK: - Body

    var body: some View {
        let tint = context.theme.color(for: colorScheme)

        HelaiaMaterial.ultraThin.apply(to:
            HStack(spacing: Spacing._3) {
                HelaiaIconView(item.iconName, size: .sm, color: tint)

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text(item.title)
                        .helaiaFont(.buttonSmall)
                    Text(item.subtitle)
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                Spacer()

                if let actionLabel = item.actionLabel, let onAction {
                    HelaiaButton.ghost(actionLabel, action: onAction)
                }
            }
            .padding(.horizontal, CodalonSpacing.cardPadding)
            .padding(.vertical, Spacing._2)
        )
        .clipShape(RoundedRectangle(cornerRadius: CodalonRadius.row))
        .contextTransition(for: context)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("WhatMattersNow — Development") {
    WhatMattersNowView(
        item: WhatMattersNowConfig.placeholder(for: .development),
        onAction: {}
    )
    .padding()
    .environment(\.projectContext, .development)
}

#Preview("WhatMattersNow — Release") {
    WhatMattersNowView(
        item: WhatMattersNowConfig.placeholder(for: .release),
        onAction: {}
    )
    .padding()
    .environment(\.projectContext, .release)
}

#Preview("WhatMattersNow — Launch") {
    WhatMattersNowView(
        item: WhatMattersNowConfig.placeholder(for: .launch),
        onAction: {}
    )
    .padding()
    .environment(\.projectContext, .launch)
}

#Preview("WhatMattersNow — Maintenance") {
    WhatMattersNowView(
        item: WhatMattersNowConfig.placeholder(for: .maintenance),
        onAction: {}
    )
    .padding()
    .environment(\.projectContext, .maintenance)
}
