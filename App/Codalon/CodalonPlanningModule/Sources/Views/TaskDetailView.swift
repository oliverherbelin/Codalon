// Issue #38 — Task detail view

import SwiftUI
import HelaiaDesign

// MARK: - TaskDetailView

struct TaskDetailView: View {

    // MARK: - State

    let task: CodalonTask
    let onUpdate: (CodalonTask) async -> Void

    @State private var showEditor = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
                header
                detailsSection
                linksSection
                flagsSection
            }
            .padding(CodalonSpacing.cardPadding)
        }
        .sheet(isPresented: $showEditor) {
            TaskEditorView(task: task, onSave: onUpdate)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack {
                Text(task.title)
                    .helaiaFont(.title2)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                Spacer()
                HelaiaButton.secondary("Edit", icon: .sfSymbol("pencil")) {
                    showEditor = true
                }
                .fixedSize()
            }
            if !task.summary.isEmpty {
                Text(task.summary)
                    .helaiaFont(.body)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            }
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var detailsSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                detailRow(label: "Status", value: task.status.displayLabel)
                detailRow(label: "Priority", value: task.priority.rawValue.capitalized)

                if let estimate = task.estimate {
                    detailRow(label: "Estimate", value: String(format: "%.1fh", estimate))
                }
                if let dueDate = task.dueDate {
                    HStack {
                        Text("Due Date")
                            .helaiaFont(.subheadline)
                            .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                        Spacer()
                        Text(dueDate, style: .date)
                            .helaiaFont(.body)
                            .foregroundStyle(
                                dueDate < Date()
                                    ? SemanticColor.error(for: colorScheme)
                                    : SemanticColor.textPrimary(for: colorScheme)
                            )
                    }
                }
                if let ref = task.githubIssueRef {
                    detailRow(label: "GitHub Issue", value: ref)
                }
            }
        }
    }

    // MARK: - Links

    @ViewBuilder
    private var linksSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Links")
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                detailRow(
                    label: "Milestone",
                    value: task.milestoneID?.uuidString.prefix(8).description ?? "None"
                )
                detailRow(
                    label: "Epic",
                    value: task.epicID?.uuidString.prefix(8).description ?? "None"
                )
            }
        }
    }

    // MARK: - Flags

    @ViewBuilder
    private var flagsSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Flags")
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

                flagRow(icon: "xmark.octagon.fill", label: "Blocked", isActive: task.isBlocked)
                flagRow(icon: "bolt.fill", label: "Launch Critical", isActive: task.isLaunchCritical)
                flagRow(icon: "clock.badge.questionmark", label: "Waiting External", isActive: task.waitingExternal)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .helaiaFont(.body)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
        }
    }

    @ViewBuilder
    private func flagRow(icon: String, label: String, isActive: Bool) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                icon,
                size: .sm,
                color: isActive ? SemanticColor.warning(for: colorScheme) : SemanticColor.textTertiary(for: colorScheme)
            )
            Text(label)
                .helaiaFont(.body)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            Spacer()
            Text(isActive ? "Yes" : "No")
                .helaiaFont(.body)
                .foregroundStyle(
                    isActive ? SemanticColor.warning(for: colorScheme) : SemanticColor.textTertiary(for: colorScheme)
                )
        }
    }
}

// MARK: - Preview

#Preview("TaskDetailView") {
    TaskDetailView(
        task: CodalonTask(
            projectID: UUID(),
            milestoneID: UUID(),
            epicID: UUID(),
            title: "Implement task list",
            summary: "Create the main task list view with grouping and sorting",
            status: .inProgress,
            priority: .high,
            estimate: 4.0,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
            isBlocked: false,
            isLaunchCritical: true,
            waitingExternal: false,
            githubIssueRef: "#36"
        ),
        onUpdate: { _ in }
    )
}