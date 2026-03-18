// Issue #148 — Release status display

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseStatusBadge

struct ReleaseStatusBadge: View {

    let status: CodalonReleaseStatus

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(displayLabel)
            .helaiaFont(.tag)
            .lineLimit(1)
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._1)
            .foregroundStyle(statusColor)
            .background(statusColor.opacity(0.15), in: Capsule())
    }

    // MARK: - Display Helpers

    private var displayLabel: String {
        switch status {
        case .drafting: "Draft"
        case .readyForQA: "Ready for QA"
        case .testing: "Testing"
        case .readyForSubmission: "Ready"
        case .submitted: "Submitted"
        case .inReview: "In Review"
        case .approved: "Approved"
        case .released: "Released"
        case .rejected: "Rejected"
        case .cancelled: "Cancelled"
        }
    }

    private var statusColor: Color {
        switch status {
        case .drafting: SemanticColor.textSecondary(for: colorScheme)
        case .readyForQA, .testing: SemanticColor.warning(for: colorScheme)
        case .readyForSubmission, .approved: SemanticColor.success(for: colorScheme)
        case .submitted, .inReview: SemanticColor.info(for: colorScheme)
        case .released: SemanticColor.success(for: colorScheme)
        case .rejected: SemanticColor.error(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("ReleaseStatusBadge") {
    VStack(spacing: 8) {
        ForEach(CodalonReleaseStatus.allCases, id: \.self) { status in
            ReleaseStatusBadge(status: status)
        }
    }
    .padding()
}
