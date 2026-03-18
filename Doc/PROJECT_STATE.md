 # Codalon — Project State

## Last updated
2026-03-18

## Current phase
Epic 19 — Context-Driven UI Engine

## Active epic
Epic 19 — Context-Driven UI Engine (issues #184–#202)

## Last decision made
- All previous decisions retained
- UI system built on HelaiaDesign — Codalon is a Helaia product
- Codalon context themes added to HelaiaFrameworks HelaiaTheme
- CodalonSpacing keeps only 3 product-specific values: zoneGap (16), cardPadding (20), minWindowHeight (760)
- All other spacing, color, typography from HelaiaDesign tokens
- CodalonColorTokens.swift deleted — status colors use SemanticColor
- CLAUDE.md updated: HelaiaFrameworks usage non-negotiable
- CLAUDE.md updated: SwiftUI previews non-negotiable
- All 8 UI system components built, HelaiaDesign aligned, accessibility checked

## Repo structure
/Users/oliverherbelin/Development/Helaia/Codalon
├── App/Codalon/          ← source
├── App/Codalon.xcodeproj
├── App/CodalonCompanion/
├── CodalonTests/         ← test target, organized by module
├── Design/Specs/         ← 9 VP Designer specs
├── Doc/CLAUDE.md
└── Doc/PROJECT_STATE.md

## Issue number map
- Epic 0: #1–#5
- Epic 1: #6–#11
- Epic 2: #12–#21
- Epic 3: #103–#110
- Epic 4: #111–#120
- Epic 5: #123–#154
- Epic 6: #22–#34
- Epic 7: #36–#72
- Epic 8: #74–#94
- Epic 9: #35–#57
- Epic 10: #59–#81
- Epic 11: #83–#102
- Epic 12: #121–#151
- Epic 13: #155–#177
- Epic 14: #179–#197
- Epic 15: #199–#226
- Epic 16: #131–#158
- Epic 17: #160–#182
- Epic 19: #184–#202
- Epic 20: #204–#224
- Epic 21: #227–#236
- Epic 22: #237–#244
- Epic 23: #245–#258

## Completed epics
- Epic 0 — Architecture & Module Scaffold ✅
- Epic 1 — App Bootstrap ✅
- Epic 2 — Domain Model ✅
- Epic 3 — Repository Layer ✅
- Epic 4 — Project Lifecycle ✅
- Epic 9 — UI System ✅
- Epic 5 — Dashboard Module ✅
- Epic 6 — Planning: Milestones & Roadmap ✅
- Epic 7 — Planning: Tasks & Execution ✅
- Epic 8 — Decision Log & Daily Focus ✅
- Epic 10 — GitHub: Connection & Repo Linking ✅
- Epic 11 — GitHub: Issues, Milestones, PRs ✅
- Epic 12 — Release Core ✅
- Epic 13 — Release Cockpit ✅
- Epic 14 — ASC Connect ✅
- Epic 15 — ASC Builds & Metadata ✅
- Epic 16 — Alerts & Notifications ✅
- Epic 17 — Rule-Based Insights ✅

## Completed issues
- Epic 0: #1–#5 ✅
- Epic 1: #6–#11 ✅
- Epic 2: #12–#21 ✅
- Epic 3: #103–#110 ✅
- Epic 4: #111–#120 ✅
- Epic 9: #35, #37, #39, #41, #43, #45, #47, #49, #51, #53, #55, #57 ✅
- Epic 5: #123, #125, #126, #128, #130, #132, #135, #140, #142, #145, #147, #149, #152, #154 ✅
- Epic 6: #22, #23, #24, #25, #26, #28, #29, #30, #31, #32, #33, #34 ✅
- Epic 7: #36–#72 ✅
- Epic 8: #72, #74, #76, #78, #80, #82, #84, #86, #88, #90, #92, #94 ✅
- Epic 10: #59, #61, #63, #65, #67, #69, #71, #73, #75, #77, #79, #81 ✅
- Epic 11: #83, #85, #87, #89, #91, #93, #95, #96, #97, #98, #99, #100, #101, #102 ✅
- Epic 12: #121, #122, #124, #127, #129, #133, #136, #138, #141, #144, #148, #151 ✅
- Epic 13: #155, #157, #159, #161, #164, #166, #168, #169, #171, #173, #175, #177 ✅
- Epic 14: #179, #181, #183, #185, #187, #189, #191, #193, #195, #197 ✅
- Epic 15: #199, #201, #203, #206, #208, #210, #212, #214, #217, #219, #221, #223, #225, #226 ✅
- Epic 16: #131, #134, #137, #139, #143, #146, #150, #153, #156, #158 ✅
- Epic 17: #160, #162, #163, #165, #167, #170, #172, #174, #176, #178, #180, #182 ✅

## Open questions
None

## Blocked items
None
