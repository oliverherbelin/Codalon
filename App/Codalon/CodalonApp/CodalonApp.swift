// Issues #8, #256 — Root window shell with HelaiaEngine bootstrap + crash reporting

import SwiftUI
import HelaiaEngine
import HelaiaLogger

@main
struct CodalonApp: App {

    @State private var appState = HelaiaAppState()
    @State private var shellState = CodalonShellState()
    @State private var hasLaunchedBefore = UserDefaults.standard.bool(forKey: "codalon.hasLaunchedBefore")

    var body: some Scene {
        WindowGroup {
            CodalonRootView()
                .environment(shellState)
                .task { await bootstrap() }
                .sheet(isPresented: Binding(
                    get: { !hasLaunchedBefore },
                    set: { if !$0 { completeOnboarding() } }
                )) {
                    OnboardingView {
                        completeOnboarding()
                    }
                }
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentMinSize)
    }

    private func bootstrap() async {
        // Issue #256 — Wire crash reporting
        let logDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("Codalon/Logs", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: logDirectory,
            withIntermediateDirectories: true
        )

        let crashReporter = CodalonCrashReporter(logDirectory: logDirectory)

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
            do {
                try await module.register(in: container)
            } catch {
                await crashReporter.capture(error, context: [
                    "module": String(describing: type(of: module)),
                    "phase": "register",
                ])
            }
        }

        for module in modules {
            await module.onLaunch()
        }

        await crashReporter.addBreadcrumb(
            "App bootstrap complete, \(modules.count) modules registered",
            category: "lifecycle"
        )

        EventBus.shared.publish(AppLaunchedEvent())
        appState.isLaunching = false
    }

    private func completeOnboarding() {
        hasLaunchedBefore = true
        UserDefaults.standard.set(true, forKey: "codalon.hasLaunchedBefore")
    }
}
