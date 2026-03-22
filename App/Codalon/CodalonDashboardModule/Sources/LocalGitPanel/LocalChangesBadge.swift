// Issue #280 — Local changes badge on GitActivityFeed header

import SwiftUI
import HelaiaDesign

// MARK: - LocalChangesBadge

struct LocalChangesBadge: View {

    let unstagedCount: Int
    let stagedCount: Int
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    private var totalCount: Int { unstagedCount + stagedCount }

    private var badgeLabel: String {
        if stagedCount > 0, unstagedCount > 0 {
            return "\(totalCount)"
        } else if stagedCount > 0 {
            return "\(stagedCount)●"
        } else {
            return "\(unstagedCount)"
        }
    }

    var body: some View {
        if totalCount > 0 {
            Button(action: action) {
                HStack(spacing: Spacing._1) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 6, height: 6)

                    Text(badgeLabel)
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                }
                .padding(.horizontal, Spacing._1_5)
                .padding(.vertical, Spacing._px)
                .background {
                    Capsule()
                        .fill(badgeColor.opacity(0.12))
                }
            }
            .buttonStyle(.plain)
            .help("Open local git panel")
            .accessibilityLabel(accessibilityText)
        }
    }

    // MARK: - Badge Color

    private var badgeColor: Color {
        if stagedCount > 0, unstagedCount > 0 {
            return SemanticColor.warning(for: colorScheme)
        } else if stagedCount > 0 {
            return SemanticColor.success(for: colorScheme)
        } else {
            return context.theme.color(for: colorScheme)
        }
    }

    // MARK: - Accessibility (#304)

    private var accessibilityText: String {
        var parts: [String] = []
        if unstagedCount > 0 {
            parts.append("\(unstagedCount) unstaged")
        }
        if stagedCount > 0 {
            parts.append("\(stagedCount) staged")
        }
        return parts.joined(separator: ", ") + " — tap to open git panel"
    }
}

// MARK: - Preview

#Preview("LocalChangesBadge — Unstaged Only") {
    LocalChangesBadge(unstagedCount: 3, stagedCount: 0) {}
        .padding()
        .environment(\.projectContext, .development)
}

#Preview("LocalChangesBadge — Staged Only") {
    LocalChangesBadge(unstagedCount: 0, stagedCount: 2) {}
        .padding()
        .environment(\.projectContext, .development)
}

#Preview("LocalChangesBadge — Mixed") {
    LocalChangesBadge(unstagedCount: 4, stagedCount: 2) {}
        .padding()
        .environment(\.projectContext, .development)
}
