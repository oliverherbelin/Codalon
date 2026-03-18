// Issues #72, #78, #80 — Decision log entry row

import SwiftUI
import HelaiaDesign

// MARK: - DecisionLogEntryRow

struct DecisionLogEntryRow: View {

    // MARK: - Properties

    let entry: CodalonDecisionLogEntry
    var linkedObjectTitle: String? = nil
    let onDelete: () -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    categoryBadge
                    Spacer()
                    Text(entry.createdAt, style: .date)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }

                Text(entry.title)
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .helaiaFont(.body)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                        .lineLimit(4)
                }

                // Issue #78, #80 — Show linked object
                if let linkedTitle = linkedObjectTitle {
                    HStack(spacing: Spacing._1_5) {
                        HelaiaIconView(
                            "link",
                            size: .xs,
                            color: SemanticColor.textTertiary(for: colorScheme)
                        )
                        Text(linkedTitle)
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    }
                }

                HStack {
                    Spacer()
                    HelaiaButton.ghost("Delete") {
                        onDelete()
                    }
                    .fixedSize()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.category.rawValue), \(entry.createdAt.formatted(date: .abbreviated, time: .omitted))")
    }

    // MARK: - Category Badge

    @ViewBuilder
    private var categoryBadge: some View {
        Text(entry.category.rawValue.capitalized)
            .helaiaFont(.caption2)
            .foregroundStyle(categoryColor)
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._0_5)
            .background(
                Capsule().fill(categoryColor.opacity(0.15))
            )
    }

    private var categoryColor: Color {
        switch entry.category {
        case .architecture: SemanticColor.info(for: colorScheme)
        case .design: SemanticColor.success(for: colorScheme)
        case .scope: SemanticColor.warning(for: colorScheme)
        case .process: SemanticColor.textSecondary(for: colorScheme)
        case .tooling: SemanticColor.info(for: colorScheme)
        case .other: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("DecisionLogEntryRow") {
    VStack(spacing: 8) {
        DecisionLogEntryRow(
            entry: CodalonDecisionLogEntry(
                projectID: UUID(),
                category: .architecture,
                title: "Use actor-based services",
                note: "All services in Codalon use Swift actors for thread safety."
            ),
            linkedObjectTitle: nil,
            onDelete: {}
        )
        DecisionLogEntryRow(
            entry: CodalonDecisionLogEntry(
                projectID: UUID(),
                relatedObjectID: UUID(),
                category: .scope,
                title: "Defer companion app",
                note: "CodalonCompanion is post-MVP. Focus on macOS cockpit first."
            ),
            linkedObjectTitle: "MVP Launch",
            onDelete: {}
        )
    }
    .padding()
}
