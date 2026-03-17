// Issue #132 — Release readiness widget

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseReadinessWidget

struct ReleaseReadinessWidget: View {

    // MARK: - Properties

    let release: ReleaseWidgetData?

    // MARK: - Body

    var body: some View {
        if let release {
            ReleaseReadinessCard(
                version: release.version,
                readinessScore: release.readinessScore,
                blockerCount: release.blockerCount,
                targetDate: release.targetDate
            )
        } else {
            HelaiaEmptyState(
                icon: "shippingbox",
                title: "No active release",
                description: "Create a release to track readiness"
            )
        }
    }
}

// MARK: - ReleaseWidgetData

struct ReleaseWidgetData: Sendable, Equatable {
    let id: UUID
    let version: String
    let readinessScore: Double
    let blockerCount: Int
    let targetDate: Date?
}

// MARK: - Preview

#Preview("ReleaseReadinessWidget") {
    VStack(spacing: 16) {
        ReleaseReadinessWidget(
            release: ReleaseWidgetData(
                id: UUID(),
                version: "1.2.0",
                readinessScore: 0.72,
                blockerCount: 2,
                targetDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)
            )
        )
        ReleaseReadinessWidget(release: nil)
            .frame(height: 120)
    }
    .padding()
    .frame(width: 400)
}
