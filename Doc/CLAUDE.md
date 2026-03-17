# Codalon — CLAUDE.md

## Product
Codalon is a macOS command center for solo developers.
One cockpit replacing GitHub, App Store Connect, Git clients,
analytics, planning tools, and release management.

## Repo
/Users/oliverherbelin/Development/Helaia/Codalon
Xcode project: App/Codalon.xcodeproj
Source root: App/Codalon/
Companion: App/CodalonCompanion/
Design specs: Design/Specs/
Documentation: Doc/

## HelaiaFrameworks
/Users/oliverherbelin/Development/Helaia/HelaiaFrameworks
12 packages. Never reinvent what Helaia already provides.
Always check HelaiaFrameworks before writing infrastructure code.

## Stack
- macOS, SwiftUI, Swift 6 strict concurrency
- No SwiftData, no CoreData — HelaiaStorage owns all persistence
- DI via HelaiaEngine ServiceContainer
- All services depend on protocols, not concrete types

## Rules
- Swift 6 strict concurrency — no @unchecked Sendable shortcuts
- Zero SwiftLint warnings
- No code without a GitHub issue reference
- Soft deletes only
- No direct GRDB in product modules
- Repositories isolate all persistence access

## Module structure
App/Codalon/
 ├ CodalonApp/
 ├ CodalonCoreModule/
 ├ CodalonProjectModule/
 ├ CodalonPlanningModule/
 ├ CodalonDashboardModule/
 ├ CodalonGitHubModule/
 ├ CodalonReleaseModule/
 ├ CodalonAppStoreModule/
 ├ CodalonInsightModule/
 ├ CodalonNotificationModule/
 ├ CodalonSettingsModule/
 └ CodalonCompanionSyncModule (post-MVP)

## Before writing any code
1. Confirm the GitHub issue number
2. Read Doc/PROJECT_STATE.md
3. Read the relevant module CLAUDE.md if it exists
4. Check HelaiaFrameworks for existing solutions

## Definition of Done — Baseline
- Builds with zero warnings
- Zero SwiftLint warnings
- Swift 6 strict concurrency clean
- No @unchecked Sendable
- Code depends on protocols, not concretions
- GitHub issue number referenced in commit message

## HelaiaFrameworks Usage — Non-Negotiable
- Codalon is a Helaia product. It must look, feel, and behave
  like one.
- HelaiaDesign IS the design system. Never diverge from it.
- Before writing ANY new component, service, or utility,
  check HelaiaFrameworks first.
- If HelaiaFrameworks provides it, use it. Never reinvent it.
- This applies to: UI components, colors, typography, icons,
  animations, materials, empty states, loading states, buttons,
  checkboxes, progress indicators, menus, toasts, alerts,
  storage, keychain, logging, analytics, AI, git, sync,
  notifications, sharing.
- Codalon token files (CodalonSpacing, CodalonRadius,
  CodalonShadow, CodalonAnimation) extend HelaiaDesign with
  layout constants specific to Codalon's canvas. They do NOT
  replace HelaiaDesign visual identity.
- All colors come from HelaiaDesign SemanticColor tokens.
  Context tints use CodalonContext.theme (HelaiaTheme).
- Never describe Codalon as visually distinct from Helaia products.
  Audit path before coding:
  /Users/oliverherbelin/Development/Helaia/HelaiaFrameworks

## SwiftUI Previews — Non-Negotiable
- Every SwiftUI View file must include a #Preview block
- Previews must compile and render without requiring live data
- Use mock data or empty state for previews
- Never leave a View file without a preview

## Git Rules — Non-Negotiable
- Never run git commit
- Never run git push
- Never run git merge
- Never run any destructive git command
- Write files only. Oli runs all git commands manually.
