// Issue #168 — Release timeline panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitTimelinePanel

struct CockpitTimelinePanel: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(title: "Timeline", icon: "calendar.badge.clock") {
            HStack(spacing: 0) {
                ForEach(Array(timelineEvents.enumerated()), id: \.element.id) { index, event in
                    if index > 0 {
                        timelineConnector(isPast: event.isPast)
                    }
                    timelineNode(event)
                }
                Spacer()
            }
        }
    }

    // MARK: - Node

    @ViewBuilder
    private func timelineNode(_ event: TimelineEvent) -> some View {
        VStack(spacing: Spacing._1) {
            Circle()
                .fill(event.isPast
                    ? SemanticColor.success(for: colorScheme)
                    : SemanticColor.textTertiary(for: colorScheme)
                )
                .frame(width: 10, height: 10)

            Text(event.label)
                .helaiaFont(.caption1)
                .helaiaForeground(event.isPast ? .textPrimary : .textTertiary)

            if let date = event.date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textSecondary)
            }
        }
        .frame(minWidth: 80)
    }

    @ViewBuilder
    private func timelineConnector(isPast: Bool) -> some View {
        Rectangle()
            .fill(isPast
                ? SemanticColor.success(for: colorScheme)
                : SemanticColor.textTertiary(for: colorScheme).opacity(0.3)
            )
            .frame(height: 2)
            .frame(maxWidth: 40)
            .padding(.bottom, 30)
    }

    // MARK: - Events

    private var timelineEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []

        events.append(TimelineEvent(
            id: "created",
            label: "Created",
            date: release.createdAt,
            isPast: true
        ))

        if let targetDate = release.targetDate {
            events.append(TimelineEvent(
                id: "target",
                label: "Target",
                date: targetDate,
                isPast: targetDate <= Date()
            ))
        }

        let submittedStatuses: Set<CodalonReleaseStatus> = [.submitted, .inReview, .approved, .released]
        events.append(TimelineEvent(
            id: "submitted",
            label: "Submitted",
            date: submittedStatuses.contains(release.status) ? release.updatedAt : nil,
            isPast: submittedStatuses.contains(release.status)
        ))

        events.append(TimelineEvent(
            id: "released",
            label: "Released",
            date: release.status == .released ? release.updatedAt : nil,
            isPast: release.status == .released
        ))

        return events
    }
}

// MARK: - TimelineEvent

private struct TimelineEvent: Identifiable {
    let id: String
    let label: String
    let date: Date?
    let isPast: Bool
}

// MARK: - Preview

#Preview("CockpitTimelinePanel") {
    VStack(spacing: 16) {
        CockpitTimelinePanel(release: ReleasePreviewData.draftRelease)
        CockpitTimelinePanel(release: ReleasePreviewData.readyRelease)
    }
    .padding()
    .frame(width: 600)
}
