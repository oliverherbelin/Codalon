// Issue #6 — Epic 1 + Epic 4: CodalonProjectModule

import Foundation
import HelaiaEngine

final class CodalonProjectModule: HelaiaModuleProtocol {
    let moduleID = "codalon.project"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let projectRepo = try await container.resolve(
            (any ProjectRepositoryProtocol).self
        )
        let taskRepo = try await container.resolve(
            (any TaskRepositoryProtocol).self
        )
        let milestoneRepo = try await container.resolve(
            (any MilestoneRepositoryProtocol).self
        )
        let releaseRepo = try await container.resolve(
            (any ReleaseRepositoryProtocol).self
        )

        // Create instances on MainActor (project default isolation)
        let projectService = await MainActor.run {
            ProjectService(repository: projectRepo)
        }
        let selectionService = await MainActor.run {
            ProjectSelectionService(repository: projectRepo)
        }
        let recentService = await MainActor.run {
            RecentProjectsService()
        }
        let summaryService = await MainActor.run {
            ProjectSummaryService(
                projectRepository: projectRepo,
                taskRepository: taskRepo,
                milestoneRepository: milestoneRepo,
                releaseRepository: releaseRepo
            )
        }

        // #111, #113, #114, #115 — Project CRUD
        await container.register(
            (any ProjectServiceProtocol).self,
            scope: .singleton
        ) { projectService }

        // #117, #118 — Project selection + persistence
        await container.register(
            (any ProjectSelectionServiceProtocol).self,
            scope: .singleton
        ) { selectionService }

        // #116 — Recent projects
        await container.register(
            (any RecentProjectsServiceProtocol).self,
            scope: .singleton
        ) { recentService }

        // #120 — Project summary calculations
        await container.register(
            (any ProjectSummaryServiceProtocol).self,
            scope: .singleton
        ) { summaryService }
    }

    func onLaunch() async {
        // #118 — Restore last selected project on launch
        let container = ServiceContainer.shared
        if let selectionService = await container.resolveOptional(
            (any ProjectSelectionServiceProtocol).self
        ) {
            await selectionService.restoreLastSelection()
        }
    }
}
