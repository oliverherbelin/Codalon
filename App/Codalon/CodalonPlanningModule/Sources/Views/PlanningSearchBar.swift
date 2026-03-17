// Issue #33 — Roadmap search

import SwiftUI
import HelaiaDesign

// MARK: - PlanningSearchBar

struct PlanningSearchBar: View {

    // MARK: - Binding

    @Binding var query: String

    // MARK: - Body

    var body: some View {
        HelaiaTextField(
            title: "",
            text: $query,
            placeholder: "Search milestones…"
        )
        .frame(width: 200)
        .accessibilityLabel("Search milestones")
    }
}

// MARK: - Preview

#Preview("PlanningSearchBar") {
    struct PreviewWrapper: View {
        @State private var query = ""

        var body: some View {
            PlanningSearchBar(query: $query)
                .padding()
        }
    }

    return PreviewWrapper()
}
