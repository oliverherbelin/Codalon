// Issue #147 — What-needs-attention widget

import SwiftUI
import HelaiaDesign

// MARK: - AttentionWidget

struct AttentionWidget: View {

    // MARK: - Properties

    let items: [AttentionWidgetItem]

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(items: [AttentionWidgetItem] = []) {
        self.items = items
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header
                if items.isEmpty {
                    Text("Nothing needs attention")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                } else {
                    ForEach(items) { item in
                        if item.onAction != nil {
                            Button {
                                item.onAction?()
                            } label: {
                                AttentionCard(
                                    severity: item.severity,
                                    title: item.title,
                                    message: item.message,
                                    actionLabel: item.actionLabel,
                                    isNavigable: item.actionRoute != nil
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            AttentionCard(
                                severity: item.severity,
                                title: item.title,
                                message: item.message,
                                actionLabel: item.actionLabel
                            )
                        }
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
                "exclamationmark.triangle.fill",
                size: .sm,
                color: items.isEmpty
                    ? SemanticColor.textSecondary(for: colorScheme)
                    : SemanticColor.warning(for: colorScheme)
            )
            Text("NEEDS ATTENTION")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            if !items.isEmpty {
                Text("\(items.count)")
                    .helaiaFont(.tag)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing._1_5)
                    .padding(.vertical, Spacing._0_5)
                    .background {
                        Capsule().fill(SemanticColor.warning(for: colorScheme))
                    }
            }
            Spacer()
        }
    }
}

// MARK: - AttentionWidgetItem

struct AttentionWidgetItem: Identifiable, Sendable {
    let id: UUID
    let severity: AttentionCard.Severity
    let title: String
    let message: String
    let actionLabel: String?
    let onAction: (@MainActor () -> Void)?
    let actionRoute: String?

    init(
        id: UUID = UUID(),
        severity: AttentionCard.Severity,
        title: String,
        message: String,
        actionLabel: String? = nil,
        onAction: (@MainActor () -> Void)? = nil,
        actionRoute: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.actionRoute = actionRoute
    }
}

// MARK: - Preview

#Preview("AttentionWidget") {
    VStack(spacing: 16) {
        AttentionWidget(items: [
            AttentionWidgetItem(
                severity: .critical,
                title: "2 Blocked Tasks",
                message: "Tasks blocked in Beta milestone",
                actionLabel: "View",
                onAction: {}
            ),
            AttentionWidgetItem(
                severity: .info,
                title: "Uncommitted changes",
                message: "You have 3 unstaged files",
                onAction: {},
                actionRoute: "localgitpanel/00000000-0000-0000-0000-000000000000"
            ),
            AttentionWidgetItem(
                severity: .warning,
                title: "Milestone Overdue",
                message: "Alpha milestone was due 3 days ago"
            )
        ])
        AttentionWidget()
    }
    .padding()
    .frame(width: 400)
}
