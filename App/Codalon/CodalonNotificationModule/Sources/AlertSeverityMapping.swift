// Issues #131, #134 — Alert severity and category display (non-UI properties)
// Uses nonisolated free functions to avoid MainActor isolation from module context.

import Foundation

// MARK: - Severity Helpers — Issue #131

nonisolated func severityIconName(_ severity: CodalonSeverity) -> String {
    switch severity {
    case .info: "info.circle.fill"
    case .warning: "exclamationmark.triangle.fill"
    case .error: "xmark.octagon.fill"
    case .critical: "flame.fill"
    }
}

nonisolated func severityDisplayName(_ severity: CodalonSeverity) -> String {
    switch severity {
    case .info: "Info"
    case .warning: "Warning"
    case .error: "Error"
    case .critical: "Critical"
    }
}

nonisolated func severityShouldNotifySystem(_ severity: CodalonSeverity) -> Bool {
    switch severity {
    case .info, .warning: false
    case .error, .critical: true
    }
}

nonisolated func severityNotificationSoundName(_ severity: CodalonSeverity) -> String? {
    switch severity {
    case .info, .warning: nil
    case .error: "Glass"
    case .critical: "Sosumi"
    }
}

// MARK: - Category Helpers — Issue #134

nonisolated func categoryIconName(_ category: CodalonAlertCategory) -> String {
    switch category {
    case .build: "hammer.fill"
    case .crash: "ant.fill"
    case .review: "star.fill"
    case .release: "shippingbox.fill"
    case .milestone: "flag.fill"
    case .security: "lock.shield.fill"
    case .general: "bell.fill"
    }
}

nonisolated func categoryDisplayName(_ category: CodalonAlertCategory) -> String {
    switch category {
    case .build: "Build"
    case .crash: "Crash"
    case .review: "Review"
    case .release: "Release"
    case .milestone: "Milestone"
    case .security: "Security"
    case .general: "General"
    }
}

// MARK: - Read State Helpers

nonisolated func readStateDisplayName(_ state: CodalonAlertReadState) -> String {
    switch state {
    case .unread: "Unread"
    case .read: "Read"
    case .dismissed: "Dismissed"
    }
}
