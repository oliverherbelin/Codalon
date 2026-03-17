// Issue #149 — Recent activity widget

import SwiftUI
import HelaiaDesign

// MARK: - RecentActivityWidget

struct RecentActivityWidget: View {

    // MARK: - Properties

    let events: [ActivityEvent]

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(events: [ActivityEvent] = []) {
        self.events = events
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header
                if events.isEmpty {
                    Text("No recent activity")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                } else {
                    ForEach(events.prefix(5)) { event in
                        eventRow(event)
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
                "clock.arrow.circlepath",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("RECENT ACTIVITY")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Event Row

    @ViewBuilder
    private func eventRow(_ event: ActivityEvent) -> some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                event.category.iconName,
                size: .xs,
                color: event.category.color(for: colorScheme)
            )
            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(event.title)
                    .helaiaFont(.footnote)
                    .lineLimit(1)
                Text(event.timeAgo)
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ActivityEvent

struct ActivityEvent: Identifiable, Sendable {
    let id: UUID
    let category: ActivityCategory
    let title: String
    let timeAgo: String

    init(
        id: UUID = UUID(),
        category: ActivityCategory,
        title: String,
        timeAgo: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.timeAgo = timeAgo
    }
}

// MARK: - ActivityCategory

enum ActivityCategory: Sendable {
    case git
    case issue
    case release
    case task

    var iconName: String {
        switch self {
        case .git: "arrow.triangle.branch"
        case .issue: "circle.fill"
        case .release: "shippingbox.fill"
        case .task: "checkmark.circle.fill"
        }
    }

    func color(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .git: SemanticColor.info(for: colorScheme)
        case .issue: SemanticColor.warning(for: colorScheme)
        case .release: SemanticColor.success(for: colorScheme)
        case .task: SemanticColor.textSecondary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("RecentActivityWidget") {
    VStack(spacing: 16) {
        RecentActivityWidget(events: [
            ActivityEvent(category: .git, title: "Pushed 3 commits to main", timeAgo: "2h"),
            ActivityEvent(category: .issue, title: "Closed #42: Fix login crash", timeAgo: "3h"),
            ActivityEvent(category: .release, title: "Release 1.1.0 submitted", timeAgo: "1d"),
            ActivityEvent(category: .task, title: "Completed: Add health widget", timeAgo: "1d"),
            ActivityEvent(category: .git, title: "Merged PR #15: Dashboard layout", timeAgo: "2d")
        ])
        RecentActivityWidget()
    }
    .padding()
    .frame(width: 400)
}
