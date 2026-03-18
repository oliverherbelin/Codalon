// Issue #72 — Decision log filter bar

import SwiftUI
import HelaiaDesign

// MARK: - DecisionLogFilterBar

struct DecisionLogFilterBar: View {

    // MARK: - Bindings

    @Binding var categoryFilter: CodalonDecisionCategory?

    // MARK: - State

    @State private var selection: DecisionCategoryOption = .all

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing._2) {
            HelaiaDropdownPicker(
                selection: $selection,
                options: DecisionCategoryOption.allOptions,
                label: "Category"
            )
            .frame(width: 160)
            .onChange(of: selection) { _, newValue in
                categoryFilter = newValue.category
            }

            if categoryFilter != nil {
                HelaiaButton.ghost("Clear") {
                    selection = .all
                    categoryFilter = nil
                }
                .fixedSize()
            }
        }
    }
}

// MARK: - DecisionCategoryOption

enum DecisionCategoryOption: String, Hashable, Sendable, CaseIterable {
    case all
    case architecture
    case design
    case scope
    case process
    case tooling
    case other

    nonisolated var category: CodalonDecisionCategory? {
        switch self {
        case .all: nil
        case .architecture: .architecture
        case .design: .design
        case .scope: .scope
        case .process: .process
        case .tooling: .tooling
        case .other: .other
        }
    }

    nonisolated static var allOptions: [HelaiaPickerOption<DecisionCategoryOption>] {
        [HelaiaPickerOption(id: .all, label: "All Categories")]
            + CodalonDecisionCategory.allCases.map {
                HelaiaPickerOption(id: DecisionCategoryOption(from: $0), label: $0.rawValue.capitalized)
            }
    }

    nonisolated init(from category: CodalonDecisionCategory) {
        switch category {
        case .architecture: self = .architecture
        case .design: self = .design
        case .scope: self = .scope
        case .process: self = .process
        case .tooling: self = .tooling
        case .other: self = .other
        }
    }
}

// MARK: - Preview

#Preview("DecisionLogFilterBar") {
    struct PreviewWrapper: View {
        @State private var category: CodalonDecisionCategory? = nil

        var body: some View {
            DecisionLogFilterBar(categoryFilter: $category)
                .padding()
        }
    }

    return PreviewWrapper()
}
