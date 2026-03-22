// Issue #287 — Inline diff view with hunk headers and line rendering

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct InlineDiffView: View {

    let diff: GitFileDiff

    @Environment(\.colorScheme) private var colorScheme

    private let maxLines = 500
    private let batchSize = 200

    @State private var visibleLineCount = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visibleHunks.enumerated()), id: \.offset) { _, hunk in
                // Hunk header
                Text(hunk.header)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .padding(.vertical, Spacing._0_5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SemanticColor.surface(for: colorScheme))

                // Lines
                ForEach(Array(hunk.lines.prefix(visibleLineCount).enumerated()), id: \.offset) { _, line in
                    diffLineRow(line)
                }
            }

            if totalLineCount > visibleLineCount {
                Button("Show \(min(batchSize, totalLineCount - visibleLineCount)) more lines") {
                    visibleLineCount = min(visibleLineCount + batchSize, maxLines)
                }
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                .padding(.vertical, Spacing._1)
                .buttonStyle(.plain)
            }

            if totalLineCount > maxLines {
                Text("Diff truncated at \(maxLines) lines")
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .padding(.vertical, Spacing._0_5)
            }
        }
        .background(SemanticColor.surface(for: colorScheme).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    @ViewBuilder
    private func diffLineRow(_ line: GitDiffLine) -> some View {
        HStack(spacing: 0) {
            Text(line.type.rawValue)
                .helaiaFont(.caption2)
                .foregroundStyle(lineColor(for: line.type))
                .frame(width: 14, alignment: .center)

            Text(line.content)
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing._1)
        .background(lineBackground(for: line.type))
    }

    private func lineColor(for type: GitDiffLine.LineType) -> Color {
        switch type {
        case .added: SemanticColor.success(for: colorScheme)
        case .removed: SemanticColor.error(for: colorScheme)
        case .context: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private func lineBackground(for type: GitDiffLine.LineType) -> Color {
        switch type {
        case .added: SemanticColor.success(for: colorScheme).opacity(0.06)
        case .removed: SemanticColor.error(for: colorScheme).opacity(0.06)
        case .context: .clear
        }
    }

    private var visibleHunks: [GitDiffHunk] {
        diff.hunks
    }

    private var totalLineCount: Int {
        diff.hunks.reduce(0) { $0 + $1.lines.count }
    }
}

#Preview("InlineDiffView") {
    let diff = GitFileDiff(
        path: "Sources/MyFile.swift",
        hunks: [
            GitDiffHunk(
                header: "@@ -1,5 +1,7 @@",
                lines: [
                    GitDiffLine(type: .context, content: "import Foundation"),
                    GitDiffLine(type: .context, content: ""),
                    GitDiffLine(type: .removed, content: "let oldValue = 42"),
                    GitDiffLine(type: .added, content: "let newValue = 100"),
                    GitDiffLine(type: .added, content: "let extra = true"),
                    GitDiffLine(type: .context, content: ""),
                ]
            )
        ]
    )
    InlineDiffView(diff: diff)
        .frame(width: 300)
        .padding()
}