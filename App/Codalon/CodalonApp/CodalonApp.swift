// Issue #6 — Epic 1: Create CodalonApp entry point

import SwiftUI
import HelaiaEngine

@main
struct CodalonApp: App {

    @State private var appState = HelaiaAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        let registry = ModuleRegistry.shared
        let container = ServiceContainer.shared

        let modules: [any HelaiaModuleProtocol] = [
            CodalonCoreModule(),
            CodalonProjectModule(),
            CodalonPlanningModule(),
            CodalonGitHubModule(),
            CodalonAppStoreModule(),
            CodalonReleaseModule(),
            CodalonInsightModule(),
            CodalonNotificationModule(),
            CodalonDashboardModule(),
            CodalonSettingsModule()
        ]

        for module in modules {
            registry.register(module)
        }

        for module in modules {
            try? await module.register(in: container)
        }

        for module in modules {
            await module.onLaunch()
        }

        EventBus.shared.publish(AppLaunchedEvent())
        appState.isLaunching = false
    }
}
