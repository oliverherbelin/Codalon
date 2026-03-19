// Issues #6, #204 — CodalonSettingsModule with service registration

import HelaiaEngine

final class CodalonSettingsModule: HelaiaModuleProtocol {
    let moduleID = "codalon.settings"
    let dependencies = ["codalon.core"]

    func register(in container: ServiceContainer) async throws {
        let store = await MainActor.run { SettingsStore() }
        await container.register(
            (any SettingsStoreProtocol).self,
            scope: .singleton
        ) { store }
    }
}
