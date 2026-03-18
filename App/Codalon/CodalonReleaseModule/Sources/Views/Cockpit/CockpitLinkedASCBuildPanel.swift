// Issue #166 — Linked ASC build panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitLinkedASCBuildPanel

struct CockpitLinkedASCBuildPanel: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(title: "App Store Connect", icon: "app.badge") {
            if let buildRef = release.linkedASCBuildRef {
                VStack(alignment: .leading, spacing: Spacing._3) {
                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            "hammer.fill",
                            size: .sm,
                            color: SemanticColor.textSecondary(for: colorScheme)
                        )
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Build Reference")
                                .helaiaFont(.caption1)
                                .helaiaForeground(.textSecondary)
                            Text(buildRef)
                                .helaiaFont(.subheadline)
                                .codalonMonospaced()
                        }
                    }

                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            "number",
                            size: .sm,
                            color: SemanticColor.textSecondary(for: colorScheme)
                        )
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Build Number")
                                .helaiaFont(.caption1)
                                .helaiaForeground(.textSecondary)
                            Text(release.buildNumber)
                                .helaiaFont(.subheadline)
                                .codalonMonospaced()
                        }
                    }

                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            statusIcon,
                            size: .sm,
                            color: statusColor
                        )
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Status")
                                .helaiaFont(.caption1)
                                .helaiaForeground(.textSecondary)
                            Text(statusLabel)
                                .helaiaFont(.subheadline)
                                .foregroundStyle(statusColor)
                        }
                    }
                }
            } else {
                VStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "app.dashed",
                        size: .lg,
                        color: SemanticColor.textTertiary(for: colorScheme)
                    )
                    Text("No ASC build linked")
                        .helaiaFont(.subheadline)
                        .helaiaForeground(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing._3)
            }
        }
    }

    // MARK: - Status Helpers

    private var statusIcon: String {
        switch release.status {
        case .submitted, .inReview: "clock.fill"
        case .approved: "checkmark.seal.fill"
        case .rejected: "xmark.seal.fill"
        case .released: "checkmark.circle.fill"
        default: "ellipsis.circle"
        }
    }

    private var statusLabel: String {
        switch release.status {
        case .submitted: "Submitted for Review"
        case .inReview: "In Review"
        case .approved: "Approved"
        case .rejected: "Rejected"
        case .released: "Live on App Store"
        default: "Pending"
        }
    }

    private var statusColor: Color {
        switch release.status {
        case .approved, .released: SemanticColor.success(for: colorScheme)
        case .rejected: SemanticColor.error(for: colorScheme)
        case .submitted, .inReview: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.textSecondary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("CockpitLinkedASCBuildPanel — With Build") {
    var release = ReleasePreviewData.readyRelease
    release.linkedASCBuildRef = "com.helaia.codalon/1.0.0/42"

    return CockpitLinkedASCBuildPanel(release: release)
        .padding()
        .frame(width: 400)
}

#Preview("CockpitLinkedASCBuildPanel — No Build") {
    CockpitLinkedASCBuildPanel(release: ReleasePreviewData.draftRelease)
        .padding()
        .frame(width: 400)
}
