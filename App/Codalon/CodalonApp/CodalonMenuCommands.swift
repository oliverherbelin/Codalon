// Issue #8 — macOS menu commands for Settings, Project Switcher, and Context shortcuts

import SwiftUI

struct CodalonMenuCommands: Commands {

    @Bindable var shellState: CodalonShellState

    var body: some Commands {
        // Project menu
        CommandMenu("Project") {
            Button("Switch Project") {
                shellState.isProjectSwitcherVisible.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        // Context menu
        CommandMenu("Context") {
            Button("Development") {
                shellState.activeContext = .development
            }
            .keyboardShortcut("1", modifiers: .option)

            Button("Release") {
                shellState.activeContext = .release
            }
            .keyboardShortcut("2", modifiers: .option)

            Button("Launch") {
                shellState.activeContext = .launch
            }
            .keyboardShortcut("3", modifiers: .option)
        }
    }
}
