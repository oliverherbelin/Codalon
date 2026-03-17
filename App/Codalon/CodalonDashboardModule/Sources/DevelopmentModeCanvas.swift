// Issue #125 — Dashboard layout: Development Mode Canvas

import SwiftUI
import HelaiaDesign

// MARK: - DevelopmentModeCanvas

struct DevelopmentModeCanvas: View {

    // MARK: - Properties

    let milestone: MilestoneFocusData?
    let commits: [CommitRowData]
    let activeMilestoneTaskRefs: Set<String>
    let currentBranch: String
    let upcomingMilestones: [SprintMilestoneData]
    let onTaskToggle: ((UUID) -> Void)?
    let onCreateMilestone: (() -> Void)?

    // MARK: - Environment

    @Environment(\.projectContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var appeared = false

    // MARK: - Init

    init(
        milestone: MilestoneFocusData? = nil,
        commits: [CommitRowData] = [],
        activeMilestoneTaskRefs: Set<String> = [],
        currentBranch: String = "main",
        upcomingMilestones: [SprintMilestoneData] = [],
        onTaskToggle: ((UUID) -> Void)? = nil,
        onCreateMilestone: (() -> Void)? = nil
    ) {
        self.milestone = milestone
        self.commits = commits
        self.activeMilestoneTaskRefs = activeMilestoneTaskRefs
        self.currentBranch = currentBranch
        self.upcomingMilestones = upcomingMilestones
        self.onTaskToggle = onTaskToggle
        self.onCreateMilestone = onCreateMilestone
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let canvasHeight = geo.size.height

            VStack(spacing: CodalonSpacing.zoneGap) {
                // Zone 1 — Milestone Focus Card (60%)
                MilestoneFocusCard(
                    milestone: milestone,
                    onTaskToggle: onTaskToggle,
                    onCreateMilestone: onCreateMilestone
                )
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight * 0.60)
                .dashboardWidgetAppearance(delay: 0)

                // Zones 2 & 3 — Bottom row (40%)
                HStack(spacing: CodalonSpacing.zoneGap) {
                    // Zone 2 — Git Activity Feed
                    GitActivityFeed(
                        commits: commits,
                        activeMilestoneTaskRefs: activeMilestoneTaskRefs,
                        currentBranch: currentBranch
                    )
                    .frame(maxWidth: .infinity)
                    .dashboardWidgetAppearance(delay: 0.06)

                    // Zone 3 — Sprint Horizon
                    SprintHorizon(
                        milestones: upcomingMilestones,
                        onCreateMilestone: onCreateMilestone
                    )
                    .frame(maxWidth: .infinity)
                    .dashboardWidgetAppearance(delay: 0.12)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(24)
        }
    }
}

// MARK: - Preview

#Preview("DevelopmentModeCanvas — Populated") {
    let milestone = MilestoneFocusData(
        id: UUID(),
        title: "Beta Release",
        description: "First public beta with core features",
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now),
        progress: 0.65,
        blockers: [
            TaskRowData(
                id: UUID(), title: "Fix crash on launch",
                status: .inProgress, priority: .critical, hasGitHubRef: true
            )
        ],
        openTasks: [
            TaskRowData(id: UUID(), title: "Implement dashboard layout", status: .inProgress, priority: .high, hasGitHubRef: true),
            TaskRowData(id: UUID(), title: "Add project summary card", status: .todo, priority: .medium, hasGitHubRef: false),
            TaskRowData(id: UUID(), title: "Write unit tests", status: .todo, priority: .low, hasGitHubRef: true)
        ]
    )

    DevelopmentModeCanvas(
        milestone: milestone,
        commits: [
            CommitRowData(hash: "a1b2c3d", message: "Fix dashboard layout spacing", timeAgo: "2h", relatedRefs: ["#42"]),
            CommitRowData(hash: "e4f5g6h", message: "Add project health widget", timeAgo: "3h"),
            CommitRowData(hash: "i7j8k9l", message: "Refactor milestone service", timeAgo: "5h")
        ],
        activeMilestoneTaskRefs: ["#42"],
        currentBranch: "feature/dashboard",
        upcomingMilestones: [
            SprintMilestoneData(title: "Public Launch", taskCount: 15, dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)),
            SprintMilestoneData(title: "Post-Launch Polish", taskCount: 5)
        ]
    )
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .development)
}

#Preview("DevelopmentModeCanvas — Empty") {
    DevelopmentModeCanvas(onCreateMilestone: {})
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .development)
}
