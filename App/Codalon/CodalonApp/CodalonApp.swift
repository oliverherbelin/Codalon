// Issue #8 — Root window shell with HelaiaEngine bootstrap

import SwiftUI
import HelaiaEngine

@main
struct CodalonApp: App {

    @State private var appState = HelaiaAppState()
    @State private var shellState = CodalonShellState()

    var body: some Scene {
        WindowGroup {
            CodalonRootView()
                .environment(shellState)
                .task { await bootstrap() }
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentMinSize)
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
