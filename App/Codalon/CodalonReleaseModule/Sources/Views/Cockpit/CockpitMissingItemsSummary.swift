// Issue #169 — Missing items summary

import SwiftUI
import HelaiaDesign

// MARK: - CockpitMissingItemsSummary

struct CockpitMissingItemsSummary: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let missing = missingItems
        if !missing.isEmpty {
            ReleaseCockpitPanel(
                title: "Missing Items",
                icon: "exclamationmark.triangle",
                badgeCount: missing.count
            ) {
                VStack(spacing: Spacing._2) {
                    ForEach(missing, id: \.self) { item in
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(
                                "circle.slash",
                                size: .xs,
                                color: SemanticColor.warning(for: colorScheme)
                            )
                            Text(item)
                                .helaiaFont(.subheadline)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Detection

    private var missingItems: [String] {
        var items: [String] = []

        let checklistTitles = Set(release.checklistItems.map { $0.title.lowercased() })

        // Auto-detect standard missing items
        let requiredItems: [(keyword: String, label: String)] = [
            ("screenshot", "Screenshots"),
            ("localization", "Localizations"),
            ("release note", "Release Notes"),
            ("metadata", "App Store Metadata"),
            ("privacy", "Privacy Manifest"),
        ]

        for required in requiredItems {
            let matchingItem = release.checklistItems.first {
                $0.title.lowercased().contains(required.keyword)
            }
            // Missing if: not in checklist at all, or in checklist but incomplete
            if matchingItem == nil {
                // Only flag if checklist has items (if empty, nothing to detect from)
                if !release.checklistItems.isEmpty {
                    items.append(required.label)
                }
            } else if let item = matchingItem, !item.isComplete {
                items.append(required.label)
            }
        }

        return items
    }
}

// MARK: - Preview

#Preview("CockpitMissingItemsSummary") {
    CockpitMissingItemsSummary(release: ReleasePreviewData.draftRelease)
        .padding()
        .frame(width: 400)
}

#Preview("CockpitMissingItemsSummary — All Complete") {
    CockpitMissingItemsSummary(release: ReleasePreviewData.readyRelease)
        .padding()
        .frame(width: 400)
}
