// Issue #192 — Adapt side panels by context

import Foundation

// MARK: - SidebarSection

/// A navigation sidebar section that can be highlighted or hidden by context.
public struct SidebarSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let label: String
    public let iconName: String
    public let isHighlighted: Bool

    public init(id: String, label: String, iconName: String, isHighlighted: Bool = false) {
        self.id = id
        self.label = label
        self.iconName = iconName
        self.isHighlighted = isHighlighted
    }
}

// MARK: - ContextSidebarConfig

/// Returns context-relevant sidebar sections.
/// Highlighted sections appear first and are visually emphasised.
public enum ContextSidebarConfig {

    public static func sections(for context: CodalonContext) -> [SidebarSection] {
        switch context {
        case .development:
            developmentSections
        case .release:
            releaseSections
        case .launch:
            launchSections
        case .maintenance:
            maintenanceSections
        }
    }

    // MARK: - Development

    private static let developmentSections: [SidebarSection] = [
        SidebarSection(id: "dashboard", label: "Dashboard", iconName: "square.grid.2x2", isHighlighted: true),
        SidebarSection(id: "milestones", label: "Milestones", iconName: "flag.fill", isHighlighted: true),
        SidebarSection(id: "tasks", label: "Tasks", iconName: "checklist", isHighlighted: true),
        SidebarSection(id: "github", label: "GitHub", iconName: "network", isHighlighted: false),
        SidebarSection(id: "releases", label: "Releases", iconName: "shippingbox", isHighlighted: false),
        SidebarSection(id: "appstore", label: "App Store", iconName: "storefront", isHighlighted: false),
        SidebarSection(id: "insights", label: "Insights", iconName: "lightbulb.fill", isHighlighted: false),
        SidebarSection(id: "alerts", label: "Alerts", iconName: "bell.fill", isHighlighted: false),
        SidebarSection(id: "settings", label: "Settings", iconName: "gearshape", isHighlighted: false),
    ]

    // MARK: - Release

    private static let releaseSections: [SidebarSection] = [
        SidebarSection(id: "dashboard", label: "Dashboard", iconName: "square.grid.2x2", isHighlighted: true),
        SidebarSection(id: "releases", label: "Releases", iconName: "shippingbox", isHighlighted: true),
        SidebarSection(id: "appstore", label: "App Store", iconName: "storefront", isHighlighted: true),
        SidebarSection(id: "github", label: "GitHub", iconName: "network", isHighlighted: true),
        SidebarSection(id: "milestones", label: "Milestones", iconName: "flag.fill", isHighlighted: false),
        SidebarSection(id: "tasks", label: "Tasks", iconName: "checklist", isHighlighted: false),
        SidebarSection(id: "insights", label: "Insights", iconName: "lightbulb.fill", isHighlighted: false),
        SidebarSection(id: "alerts", label: "Alerts", iconName: "bell.fill", isHighlighted: false),
        SidebarSection(id: "settings", label: "Settings", iconName: "gearshape", isHighlighted: false),
    ]

    // MARK: - Launch

    private static let launchSections: [SidebarSection] = [
        SidebarSection(id: "dashboard", label: "Dashboard", iconName: "square.grid.2x2", isHighlighted: true),
        SidebarSection(id: "appstore", label: "App Store", iconName: "storefront", isHighlighted: true),
        SidebarSection(id: "alerts", label: "Alerts", iconName: "bell.fill", isHighlighted: true),
        SidebarSection(id: "insights", label: "Insights", iconName: "lightbulb.fill", isHighlighted: true),
        SidebarSection(id: "releases", label: "Releases", iconName: "shippingbox", isHighlighted: false),
        SidebarSection(id: "github", label: "GitHub", iconName: "network", isHighlighted: false),
        SidebarSection(id: "milestones", label: "Milestones", iconName: "flag.fill", isHighlighted: false),
        SidebarSection(id: "tasks", label: "Tasks", iconName: "checklist", isHighlighted: false),
        SidebarSection(id: "settings", label: "Settings", iconName: "gearshape", isHighlighted: false),
    ]

    // MARK: - Maintenance

    private static let maintenanceSections: [SidebarSection] = [
        SidebarSection(id: "dashboard", label: "Dashboard", iconName: "square.grid.2x2", isHighlighted: true),
        SidebarSection(id: "insights", label: "Insights", iconName: "lightbulb.fill", isHighlighted: true),
        SidebarSection(id: "tasks", label: "Tasks", iconName: "checklist", isHighlighted: false),
        SidebarSection(id: "github", label: "GitHub", iconName: "network", isHighlighted: false),
        SidebarSection(id: "releases", label: "Releases", iconName: "shippingbox", isHighlighted: false),
        SidebarSection(id: "appstore", label: "App Store", iconName: "storefront", isHighlighted: false),
        SidebarSection(id: "milestones", label: "Milestones", iconName: "flag.fill", isHighlighted: false),
        SidebarSection(id: "alerts", label: "Alerts", iconName: "bell.fill", isHighlighted: false),
        SidebarSection(id: "settings", label: "Settings", iconName: "gearshape", isHighlighted: false),
    ]
}
