// Issues #111, #113 — Project form validation model

import Foundation

@MainActor
@Observable
public final class ProjectFormModel {

    public var name: String = ""
    public var slug: String = ""
    public var icon: String = "folder.fill"
    public var color: String = "#4A90D9"
    public var platform: CodalonPlatform = .macOS
    public var projectType: CodalonProjectType = .app

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !slug.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public init() {}

    /// Pre-populate from an existing project for editing (#113).
    public init(project: CodalonProject) {
        self.name = project.name
        self.slug = project.slug
        self.icon = project.icon
        self.color = project.color
        self.platform = project.platform
        self.projectType = project.projectType
    }

    /// Build a new CodalonProject for creation (#111).
    public func toNewProject() -> CodalonProject {
        CodalonProject(
            name: name.trimmingCharacters(in: .whitespaces),
            slug: slug.trimmingCharacters(in: .whitespaces),
            icon: icon,
            color: color,
            platform: platform,
            projectType: projectType
        )
    }

    /// Apply edits onto an existing project (#113).
    public func apply(to project: CodalonProject) -> CodalonProject {
        var updated = project
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.slug = slug.trimmingCharacters(in: .whitespaces)
        updated.icon = icon
        updated.color = color
        updated.platform = platform
        updated.projectType = projectType
        return updated
    }
}
