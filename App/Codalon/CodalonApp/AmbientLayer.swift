// Issue #8 — Ambient layer stub (solid color per context)

import SwiftUI
import HelaiaDesign

struct AmbientLayer: View {

    @Environment(\.projectContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            SemanticColor.background(for: colorScheme)
            context.theme.color(for: colorScheme).opacity(0.12)
        }
        .ignoresSafeArea()
    }
}

#Preview("Development") {
    AmbientLayer()
        .environment(\.projectContext, .development)
}

#Preview("Release") {
    AmbientLayer()
        .environment(\.projectContext, .release)
}

#Preview("Launch") {
    AmbientLayer()
        .environment(\.projectContext, .launch)
}
