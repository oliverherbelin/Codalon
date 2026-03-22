// Issue #285 — File change row with type badge, stage/unstage action, diff expand

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct FileChangeRow: View {

    let filePath: String
    let changeType: GitFileChangeType
    let isStaged: Bool
    let isExpanded: Bool
    let diff: GitFileDiff?
    let onToggleStage: () -> Void
    let onToggleExpand: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing._2) {
                // Change type badge
                Text(changeType.rawValue)
                    .helaiaFont(.tag)
                    .foregroundStyle(badgeColor)
                    .frame(width: 18, height: 18)
                    .background(badgeColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

                // File name
                Button(action: onToggleExpand) {
                    Text(fileName)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Stage/Unstage button
                Button(action: onToggleStage) {
                    HelaiaIconView(
                        isStaged ? "minus.circle" : "plus.circle",
                        size: .xs,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                }
                .buttonStyle(.plain)
                .help(isStaged ? "Unstage" : "Stage")
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._1_5)
            .contentShape(Rectangle())
            // VoiceOver (#304)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isButton)

            // Inline diff (#287)
            if isExpanded, let diff {
                InlineDiffView(diff: diff)
                    .padding(.horizontal, Spacing._3)
                    .padding(.bottom, Spacing._2)
            }
        }
        // File move animation (#286, #303)
        .animation(
            reduceMotion ? .none : CodalonAnimation.cardInteraction,
            value: isStaged
        )
    }

    // MARK: - Accessibility (#304)

    private var accessibilityText: String {
        let typeLabel: String = switch changeType {
        case .added: "Added"
        case .modified: "Modified"
        case .deleted: "Deleted"
        case .renamed: "Renamed"
        case .copied: "Copied"
        }
        let stageLabel = isStaged ? "staged" : "unstaged"
        return "\(typeLabel) \(fileName), \(stageLabel)"
    }

    private var fileName: String {
        (filePath as NSString).lastPathComponent
    }

    private var badgeColor: Color {
        switch changeType {
        case .added: SemanticColor.success(for: colorScheme)
        case .modified: context.theme.color(for: colorScheme)
        case .deleted: SemanticColor.error(for: colorScheme)
        case .renamed: SemanticColor.warning(for: colorScheme)
        case .copied: SemanticColor.textSecondary(for: colorScheme)
        }
    }
}

#Preview("FileChangeRow") {
    VStack(spacing: 0) {
        FileChangeRow(
            filePath: "Sources/MyFile.swift",
            changeType: .modified,
            isStaged: false,
            isExpanded: false,
            diff: nil,
            onToggleStage: {},
            onToggleExpand: {}
        )
        FileChangeRow(
            filePath: "Sources/NewFile.swift",
            changeType: .added,
            isStaged: true,
            isExpanded: false,
            diff: nil,
            onToggleStage: {},
            onToggleExpand: {}
        )
        FileChangeRow(
            filePath: "Sources/OldFile.swift",
            changeType: .deleted,
            isStaged: false,
            isExpanded: false,
            diff: nil,
            onToggleStage: {},
            onToggleExpand: {}
        )
    }
    .frame(width: 320)
    .environment(\.projectContext, .development)
}