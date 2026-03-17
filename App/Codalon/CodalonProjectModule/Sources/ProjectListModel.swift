// Issue #112 — Project list data model

import Foundation

@MainActor
@Observable
public final class ProjectListModel {

    public private(set) var projects: [CodalonProject] = []
    public private(set) var isLoading: Bool = false

    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    public func load() async {
        isLoading = true
        do {
            projects = try await projectService.loadActive()
        } catch {
            projects = []
        }
        isLoading = false
    }
}
