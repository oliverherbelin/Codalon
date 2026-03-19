// Issues #237-#240 — Export formatters: entity → ShareableContent

import Foundation
import HelaiaShare

// MARK: - CodalonExportFormatter

/// Pure formatting functions that convert Codalon entities into ShareableContent.
/// Each method builds Markdown body + metadata for use with HelaiaShare's ExportEngine.
nonisolated enum CodalonExportFormatter {

    // MARK: - #237 — Roadmap Export

    static func roadmapContent(
        milestones: [CodalonMilestone],
        tasks: [UUID: [CodalonTask]],
        projectName: String
    ) -> ShareableContent {
        var body = ""

        let sorted = milestones.sorted {
            ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
        }

        for milestone in sorted {
            body += "## \(milestone.title)\n\n"
            body += "- **Status:** \(milestone.status.rawValue)\n"
            body += "- **Priority:** \(milestone.priority.rawValue)\n"
            body += "- **Progress:** \(Int(milestone.progress * 100))%\n"
            if let dueDate = milestone.dueDate {
                body += "- **Due:** \(dueDate.formatted(date: .abbreviated, time: .omitted))\n"
            }
            if !milestone.summary.isEmpty {
                body += "\n\(milestone.summary)\n"
            }

            if let milestoneTasks = tasks[milestone.id], !milestoneTasks.isEmpty {
                body += "\n### Tasks\n\n"
                for task in milestoneTasks {
                    let checkbox = task.status == .done ? "[x]" : "[ ]"
                    body += "- \(checkbox) \(task.title)"
                    if task.priority == .critical || task.priority == .high {
                        body += " (\(task.priority.rawValue))"
                    }
                    body += "\n"
                }
            }
            body += "\n"
        }

        let activeMilestones = milestones.filter { $0.status == .active }
        let completedMilestones = milestones.filter { $0.status == .completed }

        return ShareableContent(
            title: "\(projectName) — Roadmap",
            body: body,
            metadata: [
                "project": projectName,
                "total_milestones": "\(milestones.count)",
                "active": "\(activeMilestones.count)",
                "completed": "\(completedMilestones.count)",
                "exported": Date().formatted(date: .abbreviated, time: .shortened),
            ],
            entityType: "CodalonRoadmap",
            entityID: UUID()
        )
    }

    // MARK: - #238 — Release Checklist Export

    static func releaseChecklistContent(
        release: CodalonRelease
    ) -> ShareableContent {
        var body = ""

        // Readiness
        body += "## Readiness Score\n\n"
        body += "**\(Int(release.readinessScore))%** — "
        body += release.readinessScore >= 80
            ? "Ready"
            : (release.readinessScore >= 50 ? "In Progress" : "Not Ready")
        body += "\n\n"

        // Blockers
        if !release.blockers.isEmpty {
            body += "## Blockers\n\n"
            for blocker in release.blockers {
                let status = blocker.isResolved ? "[x]" : "[ ]"
                body += "- \(status) \(blocker.title) (\(blocker.severity.rawValue))\n"
            }
            body += "\n"
        }

        // Checklist
        if !release.checklistItems.isEmpty {
            body += "## Checklist\n\n"
            for item in release.checklistItems {
                let status = item.isComplete ? "[x]" : "[ ]"
                body += "- \(status) \(item.title)\n"
            }
            body += "\n"
        }

        // Linked issues
        if !release.linkedGitHubIssueRefs.isEmpty {
            body += "## Linked GitHub Issues\n\n"
            for ref in release.linkedGitHubIssueRefs {
                body += "- \(ref)\n"
            }
            body += "\n"
        }

        var metadata: [String: String] = [
            "version": release.version,
            "build": release.buildNumber,
            "status": release.status.rawValue,
            "readiness": "\(Int(release.readinessScore))%",
        ]
        if let target = release.targetDate {
            metadata["target_date"] = target.formatted(date: .abbreviated, time: .omitted)
        }

        return ShareableContent(
            title: "Release v\(release.version) Summary",
            body: body,
            metadata: metadata,
            entityType: "CodalonRelease",
            entityID: release.id
        )
    }

    // MARK: - #239 — Project Summary Export

    static func projectSummaryContent(
        project: CodalonProject,
        summary: ProjectSummary,
        milestones: [CodalonMilestone]
    ) -> ShareableContent {
        var body = ""

        body += "## Overview\n\n"
        body += "- **Platform:** \(project.platform.rawValue)\n"
        body += "- **Type:** \(project.projectType.rawValue)\n"
        body += "- **Health Score:** \(Int(summary.healthScore * 100))%\n"
        body += "- **Open Tasks:** \(summary.openTaskCount)\n"
        body += "- **Milestones:** \(summary.milestoneCount)\n"
        if let releaseVersion = summary.activeReleaseVersion {
            body += "- **Active Release:** v\(releaseVersion)\n"
        }
        body += "\n"

        let activeMilestones = milestones.filter { $0.status == .active }
        if !activeMilestones.isEmpty {
            body += "## Active Milestones\n\n"
            for m in activeMilestones {
                body += "- **\(m.title)** — \(Int(m.progress * 100))%"
                if let dueDate = m.dueDate {
                    body += " (due \(dueDate.formatted(date: .abbreviated, time: .omitted)))"
                }
                body += "\n"
            }
            body += "\n"
        }

        return ShareableContent(
            title: "\(project.name) — Project Summary",
            body: body,
            metadata: [
                "project": project.name,
                "platform": project.platform.rawValue,
                "health_score": "\(Int(summary.healthScore * 100))%",
                "open_tasks": "\(summary.openTaskCount)",
                "exported": Date().formatted(date: .abbreviated, time: .shortened),
            ],
            entityType: "CodalonProject",
            entityID: project.id
        )
    }

    // MARK: - #240 — Insights Report Export

    static func insightsReportContent(
        insights: [CodalonInsight],
        healthScore: Double,
        projectName: String
    ) -> ShareableContent {
        var body = ""

        body += "## Health Score\n\n"
        body += "**\(Int(healthScore * 100))%**\n\n"

        let actionable = insights.filter {
            $0.severity == .critical || $0.severity == .error || $0.severity == .warning
        }
        let informational = insights.filter { $0.severity == .info }

        if !actionable.isEmpty {
            body += "## Actionable\n\n"
            for insight in actionable {
                body += "- **[\(insight.severity.rawValue.uppercased())]** \(insight.title)\n"
                body += "  \(insight.message)\n"
            }
            body += "\n"
        }

        if !informational.isEmpty {
            body += "## Informational\n\n"
            for insight in informational {
                body += "- \(insight.title): \(insight.message)\n"
            }
            body += "\n"
        }

        return ShareableContent(
            title: "\(projectName) — Insights Report",
            body: body,
            metadata: [
                "project": projectName,
                "health_score": "\(Int(healthScore * 100))%",
                "total_insights": "\(insights.count)",
                "actionable": "\(actionable.count)",
                "exported": Date().formatted(date: .abbreviated, time: .shortened),
            ],
            entityType: "CodalonInsightReport",
            entityID: UUID()
        )
    }
}
