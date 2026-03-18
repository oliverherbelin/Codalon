// Issue #90 — Waiting-on-third-party section

import SwiftUI
import HelaiaDesign

// MARK: - WaitingExternalSection

struct WaitingExternalSection: View {

    // MARK: - Properties

    let tasks: [CodalonTask]
    let onClearWaiting: ((UUID) -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        tasks: [CodalonTask],
        onClearWaiting: ((UUID) -> Void)? = nil
    ) {
        self.tasks = tasks
        self.onClearWaiting = onClearWaiting
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header

                if tasks.isEmpty {
                    emptyState
                } else {
                    ForEach(tasks) { task in
                        waitingRow(task)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Waiting on third party")
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "hourglass",
                size: .sm,
                color: SemanticColor.info(for: colorScheme)
            )
            Text("WAITING ON THIRD PARTY")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
            if !tasks.isEmpty {
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.info(for: colorScheme))
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func waitingRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._3) {
            priorityDot(task.priority)

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(task.title)
                    .helaiaFont(.footnote)
                    .lineLimit(1)

                Text(task.status.rawValue.capitalized)
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
            }

            Spacer()

            Button {
                onClearWaiting?(task.id)
            } label: {
                Text("Resolved")
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.success(for: colorScheme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(task.title) as no longer waiting")
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Priority Dot

    @ViewBuilder
    private func priorityDot(_ priority: CodalonPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .critical: SemanticColor.error(for: colorScheme)
        case .high: SemanticColor.warning(for: colorScheme)
        case .medium: SemanticColor.info(for: colorScheme)
        case .low: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        Text("Nothing waiting on external parties")
            .helaiaFont(.footnote)
            .helaiaForeground(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing._4)
    }
}

// MARK: - Preview

#Preview("WaitingExternalSection") {
    WaitingExternalSection(
        tasks: [
            CodalonTask(
                projectID: UUID(),
                title: "Waiting on API access from vendor",
                status: .todo,
                priority: .medium,
                waitingExternal: true
            ),
            CodalonTask(
                projectID: UUID(),
                title: "App Store review pending",
                status: .inProgress,
                priority: .high,
                waitingExternal: true
            ),
        ]
    )
    .frame(width: 400)
    .padding()
    .environment(\.projectContext, .development)
}

#Preview("WaitingExternalSection — Empty") {
    WaitingExternalSection(tasks: [])
        .frame(width: 400)
        .padding()
        .environment(\.projectContext, .development)
}
