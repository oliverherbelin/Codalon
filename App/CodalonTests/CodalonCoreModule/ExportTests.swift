// Issue #244 — Export formatting tests

import Foundation
import Testing
import HelaiaShare
@testable import Codalon

// MARK: - Roadmap Export Tests

@Suite("Roadmap Export Formatting")
@MainActor
struct RoadmapExportTests {

    @Test("roadmapContent includes all milestones in body")
    func roadmapContentIncludesMilestones() {
        let milestones = [
            CodalonMilestone(
                projectID: UUID(),
                title: "Alpha",
                summary: "First alpha build",
                dueDate: Date(),
                status: .active,
                priority: .high,
                progress: 0.5
            ),
            CodalonMilestone(
                projectID: UUID(),
                title: "Beta",
                summary: "Public beta",
                dueDate: Date().addingTimeInterval(86400 * 30),
                status: .planned,
                priority: .medium,
                progress: 0.0
            ),
        ]

        let content = CodalonExportFormatter.roadmapContent(
            milestones: milestones,
            tasks: [:],
            projectName: "TestProject"
        )

        #expect(content.title == "TestProject — Roadmap")
        #expect(content.body.contains("## Alpha"))
        #expect(content.body.contains("## Beta"))
        #expect(content.body.contains("active"))
        #expect(content.body.contains("50%"))
        #expect(content.metadata["project"] == "TestProject")
        #expect(content.metadata["total_milestones"] == "2")
        #expect(content.metadata["active"] == "1")
        #expect(content.entityType == "CodalonRoadmap")
    }

    @Test("roadmapContent includes tasks with checkboxes")
    func roadmapContentIncludesTasks() {
        let milestone = CodalonMilestone(
            projectID: UUID(),
            title: "MVP",
            status: .active,
            priority: .high,
            progress: 0.5
        )
        let tasks = [
            CodalonTask(
                projectID: UUID(),
                title: "Build UI",
                status: .done,
                priority: .high
            ),
            CodalonTask(
                projectID: UUID(),
                title: "Write tests",
                status: .todo,
                priority: .medium
            ),
        ]

        let content = CodalonExportFormatter.roadmapContent(
            milestones: [milestone],
            tasks: [milestone.id: tasks],
            projectName: "Test"
        )

        #expect(content.body.contains("[x] Build UI"))
        #expect(content.body.contains("[ ] Write tests"))
    }

    @Test("roadmapContent with empty milestones produces valid content")
    func roadmapContentEmpty() {
        let content = CodalonExportFormatter.roadmapContent(
            milestones: [],
            tasks: [:],
            projectName: "Empty"
        )

        #expect(content.title == "Empty — Roadmap")
        #expect(content.metadata["total_milestones"] == "0")
    }
}

// MARK: - Release Checklist Export Tests

@Suite("Release Checklist Export Formatting")
@MainActor
struct ReleaseChecklistExportTests {

    @Test("releaseChecklistContent includes readiness, blockers, and checklist")
    func releaseChecklistContentComplete() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "2.0.0",
            buildNumber: "99",
            targetDate: Date(),
            status: .readyForQA,
            readinessScore: 75,
            checklistItems: [
                CodalonChecklistItem(title: "Code complete", isComplete: true),
                CodalonChecklistItem(title: "QA pass", isComplete: false),
            ],
            blockers: [
                CodalonReleaseBlocker(title: "Crash bug", severity: .critical),
            ]
        )

        let content = CodalonExportFormatter.releaseChecklistContent(release: release)

        #expect(content.title == "Release v2.0.0 Summary")
        #expect(content.body.contains("75%"))
        #expect(content.body.contains("In Progress"))
        #expect(content.body.contains("[ ] Crash bug (critical)"))
        #expect(content.body.contains("[x] Code complete"))
        #expect(content.body.contains("[ ] QA pass"))
        #expect(content.metadata["version"] == "2.0.0")
        #expect(content.metadata["build"] == "99")
        #expect(content.metadata["status"] == "readyForQA")
        #expect(content.entityType == "CodalonRelease")
        #expect(content.entityID == release.id)
    }

    @Test("releaseChecklistContent readiness labels are correct")
    func releaseChecklistReadinessLabels() {
        let ready = CodalonRelease(
            projectID: UUID(), version: "1.0", buildNumber: "1",
            status: .readyForSubmission, readinessScore: 90
        )
        let notReady = CodalonRelease(
            projectID: UUID(), version: "0.1", buildNumber: "1",
            status: .drafting, readinessScore: 30
        )

        let readyContent = CodalonExportFormatter.releaseChecklistContent(release: ready)
        let notReadyContent = CodalonExportFormatter.releaseChecklistContent(release: notReady)

        #expect(readyContent.body.contains("Ready"))
        #expect(notReadyContent.body.contains("Not Ready"))
    }
}

// MARK: - Project Summary Export Tests

@Suite("Project Summary Export Formatting")
@MainActor
struct ProjectSummaryExportTests {

    @Test("projectSummaryContent includes overview and active milestones")
    func projectSummaryContentComplete() {
        let project = CodalonProject(
            name: "Codalon",
            slug: "codalon",
            platform: .macOS,
            projectType: .app
        )
        let summary = ProjectSummary(
            projectID: project.id,
            openTaskCount: 12,
            milestoneCount: 3,
            activeReleaseVersion: "1.0.0",
            healthScore: 0.85
        )
        let milestones = [
            CodalonMilestone(
                projectID: project.id,
                title: "MVP",
                dueDate: Date(),
                status: .active,
                priority: .high,
                progress: 0.7
            ),
        ]

        let content = CodalonExportFormatter.projectSummaryContent(
            project: project,
            summary: summary,
            milestones: milestones
        )

        #expect(content.title == "Codalon — Project Summary")
        #expect(content.body.contains("macOS"))
        #expect(content.body.contains("85%"))
        #expect(content.body.contains("12"))
        #expect(content.body.contains("v1.0.0"))
        #expect(content.body.contains("## Active Milestones"))
        #expect(content.body.contains("MVP"))
        #expect(content.metadata["project"] == "Codalon")
        #expect(content.metadata["platform"] == "macOS")
        #expect(content.entityType == "CodalonProject")
    }
}

// MARK: - Insights Report Export Tests

@Suite("Insights Report Export Formatting")
@MainActor
struct InsightsReportExportTests {

    @Test("insightsReportContent separates actionable and informational")
    func insightsReportContentSeparation() {
        let projectID = UUID()
        let insights = [
            CodalonInsight(
                projectID: projectID,
                type: .anomaly,
                severity: .warning,
                source: .ruleEngine,
                title: "Tasks overdue",
                message: "3 tasks are past due."
            ),
            CodalonInsight(
                projectID: projectID,
                type: .trend,
                severity: .info,
                source: .analytics,
                title: "Completion trending up",
                message: "15% improvement this week."
            ),
        ]

        let content = CodalonExportFormatter.insightsReportContent(
            insights: insights,
            healthScore: 0.72,
            projectName: "TestApp"
        )

        #expect(content.title == "TestApp — Insights Report")
        #expect(content.body.contains("72%"))
        #expect(content.body.contains("## Actionable"))
        #expect(content.body.contains("[WARNING]"))
        #expect(content.body.contains("Tasks overdue"))
        #expect(content.body.contains("## Informational"))
        #expect(content.body.contains("Completion trending up"))
        #expect(content.metadata["total_insights"] == "2")
        #expect(content.metadata["actionable"] == "1")
        #expect(content.entityType == "CodalonInsightReport")
    }

    @Test("insightsReportContent with no insights produces valid content")
    func insightsReportContentEmpty() {
        let content = CodalonExportFormatter.insightsReportContent(
            insights: [],
            healthScore: 1.0,
            projectName: "Perfect"
        )

        #expect(content.title == "Perfect — Insights Report")
        #expect(content.body.contains("100%"))
        #expect(content.metadata["total_insights"] == "0")
        #expect(content.metadata["actionable"] == "0")
    }
}

// MARK: - ShareableContent Structure Tests

@Suite("ShareableContent Structure")
@MainActor
struct ShareableContentStructureTests {

    @Test("all formatters produce non-empty title and body")
    func allFormattersProduceContent() {
        let roadmap = CodalonExportFormatter.roadmapContent(
            milestones: [CodalonMilestone(
                projectID: UUID(), title: "M1",
                status: .active, priority: .medium, progress: 0.5
            )],
            tasks: [:],
            projectName: "App"
        )
        #expect(!roadmap.title.isEmpty)
        #expect(!roadmap.body.isEmpty)

        let release = CodalonExportFormatter.releaseChecklistContent(
            release: CodalonRelease(
                projectID: UUID(), version: "1.0", buildNumber: "1",
                status: .drafting, readinessScore: 50
            )
        )
        #expect(!release.title.isEmpty)
        #expect(!release.body.isEmpty)

        let project = CodalonExportFormatter.projectSummaryContent(
            project: CodalonProject(
                name: "App", slug: "app",
                platform: .iOS, projectType: .app
            ),
            summary: ProjectSummary(
                projectID: UUID(), openTaskCount: 5,
                milestoneCount: 2, activeReleaseVersion: nil,
                healthScore: 0.8
            ),
            milestones: []
        )
        #expect(!project.title.isEmpty)
        #expect(!project.body.isEmpty)

        let insights = CodalonExportFormatter.insightsReportContent(
            insights: [],
            healthScore: 0.9,
            projectName: "App"
        )
        #expect(!insights.title.isEmpty)
        #expect(!insights.body.isEmpty)
    }

    @Test("all formatters include exported timestamp in metadata")
    func allFormattersIncludeTimestamp() {
        let roadmap = CodalonExportFormatter.roadmapContent(
            milestones: [], tasks: [:], projectName: "App"
        )
        #expect(roadmap.metadata["exported"] != nil)

        let project = CodalonExportFormatter.projectSummaryContent(
            project: CodalonProject(
                name: "App", slug: "app",
                platform: .iOS, projectType: .app
            ),
            summary: ProjectSummary(
                projectID: UUID(), openTaskCount: 0,
                milestoneCount: 0, activeReleaseVersion: nil,
                healthScore: 0.0
            ),
            milestones: []
        )
        #expect(project.metadata["exported"] != nil)

        let insights = CodalonExportFormatter.insightsReportContent(
            insights: [], healthScore: 0.0, projectName: "App"
        )
        #expect(insights.metadata["exported"] != nil)
    }
}
