// Issue #127 — Release create/edit form

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseFormView

struct ReleaseFormView: View {

    // MARK: - State

    @State private var viewModel: ReleaseViewModel
    @State private var version = ""
    @State private var buildNumber = "1"
    @State private var targetDate: Date = Date().addingTimeInterval(86400 * 14)
    @State private var hasTargetDate = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    var editingRelease: CodalonRelease?

    // MARK: - Init

    init(viewModel: ReleaseViewModel, editingRelease: CodalonRelease? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.editingRelease = editingRelease
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
        }
        .frame(minWidth: 450, minHeight: 300)
        .onAppear {
            if let release = editingRelease {
                version = release.version
                buildNumber = release.buildNumber
                if let date = release.targetDate {
                    targetDate = date
                    hasTargetDate = true
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                editingRelease == nil ? "plus.circle.fill" : "pencil.circle.fill",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text(editingRelease == nil ? "New Release" : "Edit Release")
                .helaiaFont(.title3)
            Spacer()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Form

    @ViewBuilder
    private var form: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            HelaiaTextField(
                title: "Version",
                text: $version,
                placeholder: "1.0.0"
            )

            HelaiaTextField(
                title: "Build Number",
                text: $buildNumber,
                placeholder: "1"
            )

            VStack(alignment: .leading, spacing: Spacing._2) {
                HelaiaToggle(isOn: $hasTargetDate, label: "Target Date")

                if hasTargetDate {
                    DatePicker("", selection: $targetDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            HStack(spacing: Spacing._3) {
                HelaiaButton(editingRelease == nil ? "Create" : "Save", icon: .sfSymbol("checkmark")) {
                    Task {
                        if var release = editingRelease {
                            release.version = version
                            release.buildNumber = buildNumber
                            release.targetDate = hasTargetDate ? targetDate : nil
                            await viewModel.updateRelease(release)
                        } else {
                            await viewModel.createRelease(
                                version: version,
                                buildNumber: buildNumber,
                                targetDate: hasTargetDate ? targetDate : nil,
                                milestoneID: nil
                            )
                        }
                        dismiss()
                    }
                }
                .disabled(version.trimmingCharacters(in: .whitespaces).isEmpty)
                .fixedSize()

                HelaiaButton.ghost("Cancel") { dismiss() }
                    .fixedSize()
            }
        }
        .padding(CodalonSpacing.cardPadding)
    }
}

// MARK: - Preview

#Preview("ReleaseFormView — New") {
    ReleaseFormView(viewModel: ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: UUID()
    ))
    .frame(width: 500, height: 350)
}

#Preview("ReleaseFormView — Edit") {
    ReleaseFormView(
        viewModel: ReleaseViewModel(
            releaseService: PreviewReleaseService(),
            projectID: ReleasePreviewData.projectID
        ),
        editingRelease: ReleasePreviewData.draftRelease
    )
    .frame(width: 500, height: 350)
}
