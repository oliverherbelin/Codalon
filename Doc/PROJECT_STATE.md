# Codalon — Project State

## Last updated
2026-03-16

## Current phase
Epic 1 — App Bootstrap

## Active epic
Epic 1 — App Bootstrap (issues #6–#11)

## Last decision made
- CLAUDE.md created and committed
- PROJECT_STATE.md created and committed
- Persistence: HelaiaStorage only (no SwiftData, no CoreData)
- Team protocol: CEO chat, VP Designer chat, VP Architect chat, CC terminal
- PROJECT_STATE.md owned by Oli + CEO only
- GitHub labels created (26 labels)
- GitHub milestones created (23 milestones)
- GitHub project: Codalon MVP (#5)
- All MVP issues created: Epic 0–23 (#1–#258)
- Epic 0 complete: folder structure, HelaiaFrameworks, SwiftLint, module CLAUDE.md files, build verified
- Repo restructured: App/, Doc/, Design/Specs/ folders
- UI vision confirmed: no sidebar, game-inspired fluid environment
- Navigation model: contextual menus, popovers, sheets, inspector panels
- Context switching: automatic detection primary, manual override always available
- Project mode: one project active at a time
- Launch behaviour: drop straight into last active context

## Repo structure
/Users/oliverherbelin/Development/Helaia/Codalon
├── App/Codalon/          ← source
├── App/Codalon.xcodeproj
├── App/CodalonCompanion/
├── Design/Specs/         ← VP Designer specs land here
├── Doc/CLAUDE.md
└── Doc/PROJECT_STATE.md

## Completed epics
- Epic 0 — Architecture & Module Scaffold ✅

## Completed issues
- #1 Xcode folder structure ✅
- #2 HelaiaFrameworks dependencies ✅
- #3 SwiftLint configuration ✅
- #4 Module CLAUDE.md files ✅
- #5 Build verified ✅
- #6 CodalonApp entry point ✅
- #7 Module registration system ✅ (covered by #6)

## Active issue
Issue #8 — Root window and navigation shell
Status: BLOCKED — waiting for VP Designer root shell spec

## Open questions
None

## Blocked items
- Issue #8 blocked pending VP Designer root shell spec
  (no sidebar, game-inspired, context-driven, Civilization/The Sims reference)
