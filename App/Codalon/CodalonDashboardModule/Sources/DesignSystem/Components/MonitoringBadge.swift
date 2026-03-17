// Issue #55 — Monitoring badges

import SwiftUI
import HelaiaDesign

// MARK: - MonitoringBadge

public struct MonitoringBadge: View {

    // MARK: - Properties

    private let variant: Variant

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(variant: Variant) {
        self.variant = variant
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: Spacing._1) {
            HelaiaIconView(
                variant.iconName,
                size: .xs,
                color: variant.foreground(for: colorScheme)
            )
            Text(variant.label)
                .helaiaFont(.tag)
        }
        .padding(.horizontal, Spacing._2)
        .padding(.vertical, Spacing._1)
        .foregroundStyle(variant.foreground(for: colorScheme))
        .background {
            Capsule()
                .fill(variant.background(for: colorScheme))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(variant.accessibilityLabel)
    }
}

// MARK: - Variant

extension MonitoringBadge {

    public enum Variant: Sendable {
        case alertCount(Int)
        case healthScore(Double)
        case buildStatus(BuildStatus)

        public var iconName: String {
            switch self {
            case .alertCount: "bell.fill"
            case .healthScore: "heart.fill"
            case .buildStatus(let status): status.iconName
            }
        }

        public var label: String {
            switch self {
            case .alertCount(let count): "\(count)"
            case .healthScore(let score): "\(Int(score * 100))%"
            case .buildStatus(let status): status.label
            }
        }

        public func foreground(for colorScheme: ColorScheme) -> Color {
            switch self {
            case .alertCount(let count):
                count > 0
                    ? .white
                    : SemanticColor.textSecondary(for: colorScheme)
            case .healthScore(let score):
                score >= 0.8
                    ? SemanticColor.success(for: colorScheme)
                    : score >= 0.5
                        ? SemanticColor.warning(for: colorScheme)
                        : SemanticColor.error(for: colorScheme)
            case .buildStatus(let status):
                status.color(for: colorScheme)
            }
        }

        public func background(for colorScheme: ColorScheme) -> Color {
            switch self {
            case .alertCount(let count):
                count > 0
                    ? SemanticColor.error(for: colorScheme)
                    : SemanticColor.textSecondary(for: colorScheme)
                        .opacity(Opacity.faint)
            case .healthScore:
                foreground(for: colorScheme).opacity(Opacity.faint)
            case .buildStatus(let status):
                status.color(for: colorScheme).opacity(Opacity.faint)
            }
        }

        public var accessibilityLabel: String {
            switch self {
            case .alertCount(let count):
                "\(count) alert\(count == 1 ? "" : "s")"
            case .healthScore(let score):
                "Health score \(Int(score * 100)) percent"
            case .buildStatus(let status):
                "Build \(status.label)"
            }
        }
    }
}

// MARK: - BuildStatus

extension MonitoringBadge {

    public enum BuildStatus: Sendable {
        case passing
        case failing
        case pending

        public var iconName: String {
            switch self {
            case .passing: "checkmark.circle.fill"
            case .failing: "xmark.circle.fill"
            case .pending: "clock.fill"
            }
        }

        public var label: String {
            switch self {
            case .passing: "Passing"
            case .failing: "Failing"
            case .pending: "Pending"
            }
        }

        public func color(for colorScheme: ColorScheme) -> Color {
            switch self {
            case .passing: SemanticColor.success(for: colorScheme)
            case .failing: SemanticColor.error(for: colorScheme)
            case .pending: SemanticColor.warning(for: colorScheme)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension MonitoringBadge {

    public static func alerts(_ count: Int) -> MonitoringBadge {
        MonitoringBadge(variant: .alertCount(count))
    }

    public static func health(_ score: Double) -> MonitoringBadge {
        MonitoringBadge(variant: .healthScore(score))
    }

    public static func build(_ status: BuildStatus) -> MonitoringBadge {
        MonitoringBadge(variant: .buildStatus(status))
    }
}

// MARK: - Preview

#Preview("MonitoringBadge") {
    HStack(spacing: 12) {
        MonitoringBadge.alerts(3)
        MonitoringBadge.alerts(0)
        MonitoringBadge.health(0.92)
        MonitoringBadge.health(0.55)
        MonitoringBadge.health(0.25)
        MonitoringBadge.build(.passing)
        MonitoringBadge.build(.failing)
        MonitoringBadge.build(.pending)
    }
    .padding()
}
