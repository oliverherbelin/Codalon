// Issue #172 — Detect missing ASC metadata

import Foundation

// MARK: - MissingASCMetadataRule

/// Rule: active release linked to ASC app with missing required metadata fields.
/// Since metadata completeness is tracked via checklist items, this rule
/// checks for releases with an ASC build ref but incomplete checklists.
public struct MissingASCMetadataRule: InsightRuleProtocol {

    public let ruleID = "missing_asc_metadata"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]

        return context.releases
            .filter { release in
                !terminalStatuses.contains(release.status)
                    && release.deletedAt == nil
                    && release.linkedASCBuildRef != nil
                    && hasIncompleteChecklist(release)
            }
            .map { release in
                let incomplete = release.checklistItems.filter { !$0.isComplete }
                return DetectedInsight(
                    ruleID: ruleID,
                    type: .reminder,
                    severity: .warning,
                    title: "Release \(release.version) has incomplete checklist",
                    message: "\(incomplete.count) item\(incomplete.count == 1 ? "" : "s") remaining: \(incomplete.prefix(3).map(\.title).joined(separator: ", "))",
                    deduplicationKey: "\(ruleID):\(release.id):\(incomplete.count)"
                )
            }
    }

    private func hasIncompleteChecklist(_ release: CodalonRelease) -> Bool {
        !release.checklistItems.isEmpty && release.checklistItems.contains { !$0.isComplete }
    }
}
