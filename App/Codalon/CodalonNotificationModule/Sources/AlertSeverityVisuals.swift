// Issues #131, #134 — Alert severity visual properties (SwiftUI-dependent, MainActor)

import SwiftUI
import HelaiaDesign

// MARK: - Severity Visuals

extension CodalonSeverity {

    /// Semantic color for the severity level.
    public func color(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .info: SemanticColor.textSecondary(for: colorScheme)
        case .warning: SemanticColor.warning(for: colorScheme)
        case .error: SemanticColor.error(for: colorScheme)
        case .critical: SemanticColor.error(for: colorScheme)
        }
    }

    /// Maps to AttentionCard.Severity for dashboard widgets.
    public var attentionSeverity: AttentionCard.Severity {
        switch self {
        case .info: .info
        case .warning: .warning
        case .error, .critical: .critical
        }
    }

    /// SF Symbol name (MainActor version for Views).
    public var iconName: String {
        severityIconName(self)
    }

    /// Display label (MainActor version for Views).
    public var displayName: String {
        severityDisplayName(self)
    }
}

// MARK: - Category Visuals

extension CodalonAlertCategory {

    /// SF Symbol name (MainActor version for Views).
    public var iconName: String {
        categoryIconName(self)
    }

    /// Display label (MainActor version for Views).
    public var displayName: String {
        categoryDisplayName(self)
    }
}

// MARK: - Read State Visuals

extension CodalonAlertReadState {

    /// Display label (MainActor version for Views).
    public var displayName: String {
        readStateDisplayName(self)
    }
}
