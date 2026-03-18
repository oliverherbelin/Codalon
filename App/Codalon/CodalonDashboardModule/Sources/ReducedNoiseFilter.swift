// Issue #200 — Reduced-noise filtering

import Foundation

// MARK: - WidgetPriority

/// Priority level for a dashboard widget within a given context.
public enum WidgetPriority: Int, Comparable, Sendable {
    case essential = 3
    case standard = 2
    case lowPriority = 1

    nonisolated public static func < (lhs: WidgetPriority, rhs: WidgetPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ReducedNoiseFilter

/// Determines widget visibility based on context and reduced-noise mode.
/// In reduced-noise mode, only essential and standard widgets are shown.
/// Low-priority widgets are hidden to minimise distraction.
public enum ReducedNoiseFilter {

    /// Widget IDs and their priority per context.
    public static func widgetPriority(
        _ widgetID: String,
        context: CodalonContext
    ) -> WidgetPriority {
        let map = priorities(for: context)
        return map[widgetID] ?? .standard
    }

    /// Whether a widget should be visible given the current noise mode.
    public static func isVisible(
        widgetID: String,
        context: CodalonContext,
        reducedNoise: Bool
    ) -> Bool {
        if !reducedNoise { return true }
        let priority = widgetPriority(widgetID, context: context)
        return priority >= .standard
    }

    // MARK: - Priority Maps

    private static func priorities(for context: CodalonContext) -> [String: WidgetPriority] {
        switch context {
        case .development:
            [
                "milestoneFocus": .essential,
                "gitActivity": .essential,
                "sprintHorizon": .standard,
                "attention": .standard,
                "alerts": .lowPriority,
                "insights": .lowPriority,
            ]
        case .release:
            [
                "releaseReadiness": .essential,
                "blockers": .essential,
                "checklist": .standard,
                "attention": .standard,
                "alerts": .standard,
                "insights": .lowPriority,
            ]
        case .launch:
            [
                "launchSummary": .essential,
                "crashRate": .essential,
                "reviews": .standard,
                "attention": .standard,
                "alerts": .standard,
                "insights": .lowPriority,
            ]
        case .maintenance:
            [
                "maintenanceSummary": .essential,
                "health": .standard,
                "bugs": .standard,
                "attention": .lowPriority,
                "alerts": .lowPriority,
                "insights": .standard,
            ]
        }
    }
}
