// Issue #171 — Ship-readiness state indicator

import SwiftUI
import HelaiaDesign

// MARK: - CockpitShipReadinessIndicator

struct CockpitShipReadinessIndicator: View {

    let release: CodalonRelease
    var readinessThreshold: Double = 80

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HelaiaCard(variant: isShipReady ? .filled : .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    isShipReady ? "checkmark.seal.fill" : "xmark.seal",
                    size: .lg,
                    color: isShipReady
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.error(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(isShipReady ? "Ready to Ship" : "Not Ship-Ready")
                        .helaiaFont(.headline)
                        .foregroundStyle(isShipReady
                            ? SemanticColor.success(for: colorScheme)
                            : SemanticColor.error(for: colorScheme)
                        )

                    if !isShipReady {
                        Text(blockerReason)
                            .helaiaFont(.caption1)
                            .helaiaForeground(.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Computed

    private var isShipReady: Bool {
        release.readinessScore >= readinessThreshold
            && activeBlockerCount == 0
    }

    private var activeBlockerCount: Int {
        release.blockers.filter { !$0.isResolved }.count
    }

    private var blockerReason: String {
        var reasons: [String] = []
        if release.readinessScore < readinessThreshold {
            reasons.append("Score below \(Int(readinessThreshold))%")
        }
        if activeBlockerCount > 0 {
            reasons.append("\(activeBlockerCount) active blocker\(activeBlockerCount == 1 ? "" : "s")")
        }
        return reasons.joined(separator: " · ")
    }
}

// MARK: - Preview

#Preview("CockpitShipReadinessIndicator") {
    VStack(spacing: 16) {
        CockpitShipReadinessIndicator(release: ReleasePreviewData.readyRelease)
        CockpitShipReadinessIndicator(release: ReleasePreviewData.draftRelease)
    }
    .padding()
    .frame(width: 500)
}
