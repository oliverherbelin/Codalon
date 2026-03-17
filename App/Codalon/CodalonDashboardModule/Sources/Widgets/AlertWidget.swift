// Issue #142 — Alert widget

import SwiftUI
import HelaiaDesign

// MARK: - AlertWidget

struct AlertWidget: View {

    // MARK: - Properties

    let unreadCount: Int
    let topAlert: AlertWidgetItem?
    let onViewAll: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(
        unreadCount: Int = 0,
        topAlert: AlertWidgetItem? = nil,
        onViewAll: (() -> Void)? = nil
    ) {
        self.unreadCount = unreadCount
        self.topAlert = topAlert
        self.onViewAll = onViewAll
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header
                if let topAlert {
                    AttentionCard(
                        severity: topAlert.severity,
                        title: topAlert.title,
                        message: topAlert.message
                    )
                } else {
                    Text("No unread alerts")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
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
                "bell.fill",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("ALERTS")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            if unreadCount > 0 {
                MonitoringBadge.alerts(unreadCount)
            }
            Spacer()
            if let onViewAll {
                HelaiaButton.ghost("View All", action: onViewAll)
            }
        }
    }
}

// MARK: - AlertWidgetItem

struct AlertWidgetItem: Sendable, Equatable {
    let id: UUID
    let severity: AttentionCard.Severity
    let title: String
    let message: String

    static func == (lhs: AlertWidgetItem, rhs: AlertWidgetItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview("AlertWidget") {
    VStack(spacing: 16) {
        AlertWidget(
            unreadCount: 3,
            topAlert: AlertWidgetItem(
                id: UUID(),
                severity: .critical,
                title: "Build Failed",
                message: "CI build failed on main branch"
            ),
            onViewAll: {}
        )
        AlertWidget()
    }
    .padding()
    .frame(width: 400)
}
