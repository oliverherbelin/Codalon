// Issue #8 — Root window shell (Root Shell Spec v1.0)

import SwiftUI

struct CodalonRootView: View {

    @Environment(CodalonShellState.self) private var shellState

    var body: some View {
        ZStack {
            // Layer 0 — Ambient: context-reactive background
            AmbientLayer()

            // Layer 1 — Canvas: primary working surface (stub)
            Color.clear

            // Layer 2 — Overlay: popovers, inspector, sheets (stub)
            Color.clear

            // Layer 3 — HUD: persistent anchor strip (stub)
            Color.clear

            // Layer 4 — Proposal: context-change proposal pill (stub)
            Color.clear
        }
        .frame(minWidth: 1200, minHeight: 760)
        .environment(\.projectContext, shellState.activeContext)
        .environment(\.healthState, shellState.healthState)
        .environment(\.activeMilestoneID, shellState.activeMilestoneID)
        .environment(\.activeReleaseID, shellState.activeReleaseID)
        .environment(\.activeDistributionTargets, shellState.activeDistributionTargets)
    }
}
