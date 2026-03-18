// Issue #217 — Release notes editor view

import SwiftUI
import HelaiaDesign

// MARK: - ASCReleaseNotesEditorView

struct ASCReleaseNotesEditorView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel
    @State private var editingLocaleID: String?
    @State private var editingText = ""

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel, versionID: String) {
        self._viewModel = State(initialValue: viewModel)
        self.versionID = versionID
    }

    private let versionID: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            Text("Release Notes")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            if viewModel.releaseNotes.isEmpty {
                HelaiaEmptyState(
                    icon: "doc.plaintext",
                    title: "No release notes",
                    description: "Add release notes per locale in App Store Connect"
                )
            } else {
                notesList
            }
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadReleaseNotes(versionID: versionID)
        }
    }

    // MARK: - Notes List

    @ViewBuilder
    private var notesList: some View {
        VStack(spacing: Spacing._2) {
            ForEach(viewModel.releaseNotes) { note in
                noteCard(note)
            }
        }
    }

    @ViewBuilder
    private func noteCard(_ note: ASCReleaseNotes) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._2) {
                HStack {
                    HelaiaIconView(
                        "globe",
                        size: .sm,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                    Text(note.locale)
                        .helaiaFont(.headline)

                    Spacer()

                    if editingLocaleID == note.id {
                        HStack(spacing: Spacing._2) {
                            HelaiaButton("Save", icon: .sfSymbol("checkmark")) {
                                Task {
                                    await viewModel.updateReleaseNotes(
                                        localizationID: note.id,
                                        whatsNew: editingText
                                    )
                                    editingLocaleID = nil
                                }
                            }
                            .fixedSize()
                            .disabled(viewModel.isUpdatingNotes)

                            HelaiaButton.ghost("Cancel") {
                                editingLocaleID = nil
                            }
                            .fixedSize()
                        }
                    } else {
                        HelaiaButton("Edit", icon: .sfSymbol("pencil")) {
                            editingLocaleID = note.id
                            editingText = note.whatsNew ?? ""
                        }
                        .fixedSize()
                    }
                }

                if editingLocaleID == note.id {
                    TextEditor(text: $editingText)
                        .font(.system(.body, design: .default))
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColor.border(for: colorScheme), lineWidth: 1)
                        )
                } else if let whatsNew = note.whatsNew, !whatsNew.isEmpty {
                    Text(whatsNew)
                        .helaiaFont(.body)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                } else {
                    Text("No release notes for this locale")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("ASCReleaseNotesEditorView") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.releaseNotes = [
        ASCReleaseNotes(id: "loc1", locale: "en-US", whatsNew: "Bug fixes and performance improvements.\n\n- Fixed crash on launch\n- Improved dark mode support"),
        ASCReleaseNotes(id: "loc2", locale: "de-DE", whatsNew: "Fehlerbehebungen und Leistungsverbesserungen."),
        ASCReleaseNotes(id: "loc3", locale: "fr-FR", whatsNew: nil),
    ]

    return ASCReleaseNotesEditorView(viewModel: vm, versionID: "v1")
        .frame(width: 500, height: 600)
}

#Preview("ASCReleaseNotesEditorView — Empty") {
    ASCReleaseNotesEditorView(
        viewModel: ASCViewModel(ascService: PreviewASCService(), projectID: UUID()),
        versionID: "v1"
    )
    .frame(width: 500, height: 200)
}
