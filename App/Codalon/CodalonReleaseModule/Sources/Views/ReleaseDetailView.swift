// Issues #124, #129, #133, #136, #138, #141 — Release detail view

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseDetailView

struct ReleaseDetailView: View {

    // MARK: - State

    @State private var viewModel: ReleaseViewModel
    @State private var showEditForm = false
    @State private var newChecklistTitle = ""
    @State private var newBlockerTitle = ""
    @State private var newBlockerSeverity: CodalonSeverity = .warning

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ReleaseViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        if let release = viewModel.selectedRelease {
            VStack(spacing: 0) {
                detailHeader(release)
                Divider()
                ScrollView {
                    VStack(spacing: CodalonSpacing.zoneGap) {
                        readinessSection(release)
                        statusSection(release)
                        checklistSection(release)
                        blockersSection(release)
                        linkedMilestoneSection(release)
                        linkedTasksSection(release)
                        linkedGitHubSection(release)
                    }
                    .padding(CodalonSpacing.cardPadding)
                }
            }
            .sheet(isPresented: $showEditForm) {
                ReleaseFormView(viewModel: viewModel, editingRelease: release)
            }
        } else {
            HelaiaEmptyState(
                icon: "shippingbox",
                title: "No release selected",
                description: "Select a release from the list"
            )
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func detailHeader(_ release: CodalonRelease) -> some View {
        HStack(spacing: Spacing._3) {
            ReleaseStatusBadge(status: release.status)

            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("v\(release.version)")
                    .helaiaFont(.title3)
                Text("Build \(release.buildNumber)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }

            Spacer()

            HelaiaButton.secondary("Edit") { showEditForm = true }
                .fixedSize()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Issue #144 — Readiness

    @ViewBuilder
    private func readinessSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            HStack(spacing: Spacing._8) {
                HelaiaProgressRing(
                    value: release.readinessScore / 100,
                    size: 64,
                    lineWidth: 6
                )
                .tint(readinessColor(release.readinessScore))

                VStack(alignment: .leading, spacing: Spacing._2) {
                    Text("Readiness Score")
                        .helaiaFont(.headline)
                    Text("\(Int(release.readinessScore))%")
                        .helaiaFont(.title2)
                        .foregroundStyle(readinessColor(release.readinessScore))

                    if let date = release.targetDate {
                        HStack(spacing: Spacing._1) {
                            HelaiaIconView("calendar", size: .xs, color: SemanticColor.textTertiary(for: colorScheme))
                            Text("Target: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Issue #148 — Status

    @ViewBuilder
    private func statusSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("STATUS")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                Picker("Status", selection: Binding(
                    get: { release.status },
                    set: { newStatus in
                        Task { await viewModel.updateStatus(newStatus) }
                    }
                )) {
                    ForEach(CodalonReleaseStatus.allCases, id: \.self) { status in
                        Text(statusLabel(status)).tag(status)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private func statusLabel(_ status: CodalonReleaseStatus) -> String {
        switch status {
        case .drafting: "Draft"
        case .readyForQA: "Ready for QA"
        case .testing: "Testing"
        case .readyForSubmission: "Ready for Submission"
        case .submitted: "Submitted"
        case .inReview: "In Review"
        case .approved: "Approved"
        case .released: "Released"
        case .rejected: "Rejected"
        case .cancelled: "Cancelled"
        }
    }

    // MARK: - Issue #138 — Checklist

    @ViewBuilder
    private func checklistSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("CHECKLIST")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    let completed = release.checklistItems.filter(\.isComplete).count
                    Text("\(completed)/\(release.checklistItems.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                ForEach(release.checklistItems, id: \.id) { item in
                    HStack(spacing: Spacing._2) {
                        Button {
                            Task { await viewModel.toggleChecklistItem(item.id) }
                        } label: {
                            HelaiaIconView(
                                item.isComplete ? "checkmark.circle.fill" : "circle",
                                size: .sm,
                                color: item.isComplete
                                    ? SemanticColor.success(for: colorScheme)
                                    : SemanticColor.textTertiary(for: colorScheme)
                            )
                        }
                        .buttonStyle(.plain)

                        Text(item.title)
                            .helaiaFont(.body)
                            .strikethrough(item.isComplete)
                            .foregroundStyle(
                                item.isComplete
                                    ? SemanticColor.textTertiary(for: colorScheme)
                                    : SemanticColor.textPrimary(for: colorScheme)
                            )

                        Spacer()

                        Button {
                            Task { await viewModel.removeChecklistItem(item.id) }
                        } label: {
                            HelaiaIconView("xmark", size: .xs, color: SemanticColor.textTertiary(for: colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: Spacing._2) {
                    HelaiaTextField(
                        title: "",
                        text: $newChecklistTitle,
                        placeholder: "Add checklist item…"
                    )
                    HelaiaButton.secondary("Add") {
                        guard !newChecklistTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        Task {
                            await viewModel.addChecklistItem(title: newChecklistTitle)
                            newChecklistTitle = ""
                        }
                    }
                    .fixedSize()
                }
            }
        }
    }

    // MARK: - Issue #141 — Blockers

    @ViewBuilder
    private func blockersSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    HelaiaIconView(
                        "exclamationmark.triangle.fill",
                        size: .sm,
                        color: SemanticColor.warning(for: colorScheme)
                    )
                    Text("BLOCKERS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    let active = release.blockers.filter { !$0.isResolved }.count
                    Text("\(active) active")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                ForEach(release.blockers) { blocker in
                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            blocker.isResolved ? "checkmark.circle.fill" : "xmark.circle.fill",
                            size: .sm,
                            color: blocker.isResolved
                                ? SemanticColor.success(for: colorScheme)
                                : severityColor(blocker.severity)
                        )

                        VStack(alignment: .leading, spacing: 0) {
                            Text(blocker.title)
                                .helaiaFont(.body)
                                .strikethrough(blocker.isResolved)
                            if !blocker.source.isEmpty {
                                Text(blocker.source)
                                    .helaiaFont(.caption1)
                                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                            }
                        }

                        Spacer()

                        if !blocker.isResolved {
                            HelaiaButton.ghost("Resolve") {
                                Task { await viewModel.resolveBlocker(blocker.id) }
                            }
                            .fixedSize()
                        }
                    }
                }

                HStack(spacing: Spacing._2) {
                    HelaiaTextField(
                        title: "",
                        text: $newBlockerTitle,
                        placeholder: "Add blocker…"
                    )
                    Picker("", selection: $newBlockerSeverity) {
                        Text("Warning").tag(CodalonSeverity.warning)
                        Text("Error").tag(CodalonSeverity.error)
                        Text("Critical").tag(CodalonSeverity.critical)
                    }
                    .frame(width: 100)
                    HelaiaButton.destructive("Add") {
                        guard !newBlockerTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        Task {
                            await viewModel.addBlocker(title: newBlockerTitle, severity: newBlockerSeverity)
                            newBlockerTitle = ""
                        }
                    }
                    .fixedSize()
                }
            }
        }
    }

    private func severityColor(_ severity: CodalonSeverity) -> Color {
        switch severity {
        case .info: SemanticColor.info(for: colorScheme)
        case .warning: SemanticColor.warning(for: colorScheme)
        case .error: SemanticColor.error(for: colorScheme)
        case .critical: SemanticColor.error(for: colorScheme)
        }
    }

    // MARK: - Issue #129 — Linked Milestone

    @ViewBuilder
    private func linkedMilestoneSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("LINKED MILESTONE")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                if let milestoneID = release.linkedMilestoneID {
                    HelaiaSettingsRow(
                        title: "Milestone",
                        icon: "flag.fill",
                        iconColor: SemanticColor.textSecondary(for: colorScheme),
                        variant: .value(milestoneID.uuidString.prefix(8).description)
                    )
                } else {
                    Text("No milestone linked")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                }
            }
        }
    }

    // MARK: - Issue #133 — Linked Tasks

    @ViewBuilder
    private func linkedTasksSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("LINKED TASKS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(release.linkedTaskIDs.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                if release.linkedTaskIDs.isEmpty {
                    Text("No tasks linked to this release")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(release.linkedTaskIDs, id: \.self) { taskID in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView("checkmark.circle", size: .xs, color: SemanticColor.textSecondary(for: colorScheme))
                            Text(taskID.uuidString.prefix(8).description)
                                .helaiaFont(.footnote)
                            Spacer()
                            Button {
                                Task { await viewModel.unlinkTask(taskID) }
                            } label: {
                                HelaiaIconView("xmark", size: .xs, color: SemanticColor.textTertiary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Issue #136 — Linked GitHub Issues

    @ViewBuilder
    private func linkedGitHubSection(_ release: CodalonRelease) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("LINKED GITHUB ISSUES")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(release.linkedGitHubIssueRefs.count)")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                if release.linkedGitHubIssueRefs.isEmpty {
                    Text("No GitHub issues linked")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(release.linkedGitHubIssueRefs, id: \.self) { ref in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView("exclamationmark.circle", size: .xs, color: SemanticColor.textSecondary(for: colorScheme))
                            Text(ref)
                                .helaiaFont(.footnote)
                            Spacer()
                            Button {
                                Task { await viewModel.unlinkGitHubIssue(ref) }
                            } label: {
                                HelaiaIconView("xmark", size: .xs, color: SemanticColor.textTertiary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func readinessColor(_ score: Double) -> Color {
        switch score {
        case 80...: SemanticColor.success(for: colorScheme)
        case 50..<80: SemanticColor.warning(for: colorScheme)
        default: SemanticColor.error(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("ReleaseDetailView — Draft") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.selectedRelease = ReleasePreviewData.draftRelease

    return ReleaseDetailView(viewModel: vm)
        .frame(width: 600, height: 800)
}

#Preview("ReleaseDetailView — Ready") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.selectedRelease = ReleasePreviewData.readyRelease

    return ReleaseDetailView(viewModel: vm)
        .frame(width: 600, height: 700)
}

#Preview("ReleaseDetailView — No Selection") {
    ReleaseDetailView(viewModel: ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: UUID()
    ))
    .frame(width: 600, height: 400)
}
