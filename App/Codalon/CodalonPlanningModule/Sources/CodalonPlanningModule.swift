// Issues #6, #36, #72 — CodalonPlanningModule

import HelaiaEngine

final class CodalonPlanningModule: HelaiaModuleProtocol {
    let moduleID = "codalon.planning"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let milestoneRepo = try await container.resolve(
            (any MilestoneRepositoryProtocol).self
        )
        let taskRepo = try await container.resolve(
            (any TaskRepositoryProtocol).self
        )

        // PlanningService — milestones
        let planningService = await MainActor.run {
            PlanningService(
                milestoneRepository: milestoneRepo,
                taskRepository: taskRepo
            )
        }
        await container.register(
            (any PlanningServiceProtocol).self,
            scope: .singleton
        ) { planningService }

        // TaskService — tasks
        let taskService = await MainActor.run {
            TaskService(taskRepository: taskRepo)
        }
        await container.register(
            (any TaskServiceProtocol).self,
            scope: .singleton
        ) { taskService }
    }

    func onLaunch() async {
        // Detect overdue milestones on launch
        let container = ServiceContainer.shared
        if let service = await container.resolveOptional(
            (any PlanningServiceProtocol).self
        ) {
            // TODO: Needs active projectID — will wire once project selection is available
            _ = service
        }
    }
}
