// Issue #157 — Readiness summary panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitReadinessSummary

struct CockpitReadinessSummary: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(title: "Readiness", icon: "gauge.high") {
            HStack(spacing: CodalonSpacing.zoneGap) {
                HelaiaProgressRing(
                    value: release.readinessScore / 100,
                    size: 72,
                    lineWidth: 7,
                    label: "\(Int(release.readinessScore))%"
                )
                .tint(readinessColor)

                VStack(alignment: .leading, spacing: Spacing._2) {
                    Text(readinessLabel)
                        .helaiaFont(.headline)
                        .foregroundStyle(readinessColor)

                    if let date = release.targetDate {
                        HStack(spacing: Spacing._1) {
                            HelaiaIconView("calendar", size: .xs, color: SemanticColor.textTertiary(for: colorScheme))
                            Text("Target: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }
                    }

                    HStack(spacing: Spacing._3) {
                        metricPill(
                            label: "Checklist",
                            value: "\(completedChecklist)/\(release.checklistItems.count)"
                        )
                        metricPill(
                            label: "Blockers",
                            value: "\(release.blockerCount)",
                            isAlert: release.blockerCount > 0
                        )
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private var completedChecklist: Int {
        release.checklistItems.filter(\.isComplete).count
    }

    private var readinessLabel: String {
        switch release.readinessScore {
        case 80...: "Ready"
        case 50..<80: "In Progress"
        default: "Not Ready"
        }
    }

    private var readinessColor: Color {
        switch release.readinessScore {
        case 80...: SemanticColor.success(for: colorScheme)
        case 50..<80: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.error(for: colorScheme)
        }
    }

    @ViewBuilder
    private func metricPill(label: String, value: String, isAlert: Bool = false) -> some View {
        HStack(spacing: Spacing._1) {
            Text(label)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
            Text(value)
                .helaiaFont(.tag)
                .foregroundStyle(isAlert ? SemanticColor.error(for: colorScheme) : SemanticColor.textPrimary(for: colorScheme))
        }
    }
}

// MARK: - Preview

#Preview("CockpitReadinessSummary") {
    VStack(spacing: 16) {
        CockpitReadinessSummary(release: ReleasePreviewData.draftRelease)
        CockpitReadinessSummary(release: ReleasePreviewData.readyRelease)
    }
    .padding()
    .frame(width: 500)
}
