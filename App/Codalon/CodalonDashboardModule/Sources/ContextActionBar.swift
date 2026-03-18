// Issue #194 — Context-aware action bar

import SwiftUI
import HelaiaDesign

// MARK: - ContextAction

/// A primary action available in the action bar, determined by context.
public struct ContextAction: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let iconName: String
    public let isPrimary: Bool

    public init(id: String, label: String, iconName: String, isPrimary: Bool = false) {
        self.id = id
        self.label = label
        self.iconName = iconName
        self.isPrimary = isPrimary
    }
}

// MARK: - ContextActionConfig

/// Returns context-relevant primary actions.
public enum ContextActionConfig {

    public static func actions(for context: CodalonContext) -> [ContextAction] {
        switch context {
        case .development:
            developmentActions
        case .release:
            releaseActions
        case .launch:
            launchActions
        case .maintenance:
            maintenanceActions
        }
    }

    private static let developmentActions: [ContextAction] = [
        ContextAction(id: "newTask", label: "New Task", iconName: "plus.circle.fill", isPrimary: true),
        ContextAction(id: "newMilestone", label: "New Milestone", iconName: "flag.fill"),
        ContextAction(id: "syncGitHub", label: "Sync GitHub", iconName: "arrow.triangle.2.circlepath"),
    ]

    private static let releaseActions: [ContextAction] = [
        ContextAction(id: "submitBuild", label: "Submit Build", iconName: "paperplane.fill", isPrimary: true),
        ContextAction(id: "checkMetadata", label: "Check Metadata", iconName: "doc.text.magnifyingglass"),
        ContextAction(id: "viewChecklist", label: "Checklist", iconName: "checklist"),
    ]

    private static let launchActions: [ContextAction] = [
        ContextAction(id: "viewReviews", label: "View Reviews", iconName: "star.fill", isPrimary: true),
        ContextAction(id: "checkCrashes", label: "Crash Report", iconName: "exclamationmark.triangle.fill"),
        ContextAction(id: "replyReview", label: "Reply to Review", iconName: "bubble.left.fill"),
    ]

    private static let maintenanceActions: [ContextAction] = [
        ContextAction(id: "newBugfix", label: "New Bug Fix", iconName: "ladybug.fill", isPrimary: true),
        ContextAction(id: "runHealth", label: "Health Check", iconName: "heart.text.square.fill"),
        ContextAction(id: "startRelease", label: "Start Release", iconName: "shippingbox"),
    ]
}

// MARK: - ContextActionBarView

struct ContextActionBarView: View {

    // MARK: - Properties

    let onAction: (String) -> Void

    // MARK: - Environment

    @Environment(\.projectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        let actions = ContextActionConfig.actions(for: context)
        let tint = context.theme.color(for: colorScheme)

        HStack(spacing: Spacing._2) {
            ForEach(actions) { action in
                if action.isPrimary {
                    HelaiaButton(action.label, icon: action.iconName, variant: .primary) {
                        onAction(action.id)
                    }
                } else {
                    HelaiaButton.ghost(action.label, icon: action.iconName) {
                        onAction(action.id)
                    }
                }
            }
            Spacer()
        }
        .animation(
            CodalonAnimation.animation(
                CodalonAnimation.contextTransition,
                reduceMotion: reduceMotion
            ),
            value: context
        )
    }
}

// MARK: - Preview

#Preview("ContextActionBar — Development") {
    ContextActionBarView(onAction: { _ in })
        .padding()
        .environment(\.projectContext, .development)
}

#Preview("ContextActionBar — Release") {
    ContextActionBarView(onAction: { _ in })
        .padding()
        .environment(\.projectContext, .release)
}

#Preview("ContextActionBar — Launch") {
    ContextActionBarView(onAction: { _ in })
        .padding()
        .environment(\.projectContext, .launch)
}

#Preview("ContextActionBar — Maintenance") {
    ContextActionBarView(onAction: { _ in })
        .padding()
        .environment(\.projectContext, .maintenance)
}
