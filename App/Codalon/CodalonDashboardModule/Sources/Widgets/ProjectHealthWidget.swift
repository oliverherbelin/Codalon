// Issue #128 — Project health widget

import SwiftUI
import HelaiaDesign

// MARK: - ProjectHealthWidget

struct ProjectHealthWidget: View {

    // MARK: - Properties

    let healthScore: Double
    let planningHealth: Double
    let releaseHealth: Double
    let gitHealth: Double
    let storeHealth: Double

    // MARK: - Body

    var body: some View {
        ProjectHealthCard(
            healthScore: healthScore,
            dimensions: [
                .init(id: "planning", label: "Planning", value: planningHealth),
                .init(id: "release", label: "Release", value: releaseHealth),
                .init(id: "git", label: "GitHub", value: gitHealth),
                .init(id: "store", label: "App Store", value: storeHealth)
            ]
        )
    }
}

// MARK: - Preview

#Preview("ProjectHealthWidget") {
    VStack(spacing: 16) {
        ProjectHealthWidget(
            healthScore: 0.78,
            planningHealth: 0.90,
            releaseHealth: 0.65,
            gitHealth: 0.80,
            storeHealth: 0.55
        )
        ProjectHealthWidget(
            healthScore: 0.32,
            planningHealth: 0.20,
            releaseHealth: 0.10,
            gitHealth: 0.50,
            storeHealth: 0.40
        )
    }
    .padding()
    .frame(width: 400)
}
