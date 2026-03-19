---
title: MVP QA Checklist
created: 2026-03-19
updated: 2026-03-19
version: 1.0
author: claude-code
---

# MVP QA Checklist

Comprehensive QA checklist covering all MVP epics. Each item maps to acceptance criteria from the corresponding epic.

## Epic 0 — Architecture & Module Scaffold

- [ ] All 11 modules register without errors
- [ ] ServiceContainer resolves all registered protocols
- [ ] ModuleRegistry lists all modules after bootstrap
- [ ] EventBus publishes `AppLaunchedEvent` on startup

## Epic 1 — App Bootstrap

- [ ] App launches to root window at 1440x900
- [ ] Minimum window size enforced (1200x760)
- [ ] AmbientLayer renders context-reactive background
- [ ] Shell state initializes with `.development` context
- [ ] All environment keys propagated through view hierarchy

## Epic 2 — Domain Model

- [ ] All entities round-trip encode/decode (JSON)
- [ ] All enums have correct raw values
- [ ] Soft delete (`deletedAt`) is respected in all entities
- [ ] CodalonChecklistItem and CodalonReleaseBlocker are Codable
- [ ] All entities conform to HelaiaRecord

## Epic 3 — Repository Layer

- [ ] All 7 repository protocols have concrete implementations
- [ ] CRUD operations work for all entity types
- [ ] Fetch-by-project filtering returns correct results
- [ ] Soft-deleted records excluded from standard queries

## Epic 4 — Project Lifecycle

- [ ] Create project with all required fields
- [ ] Edit project name, platform, type
- [ ] Archive project (soft delete)
- [ ] Project summary calculates correctly (open tasks, milestones, health)
- [ ] Project slug generated from name

## Epic 5 — Dashboard Module

- [ ] Dashboard loads without data (empty states visible)
- [ ] Context routing shows correct canvas per context
- [ ] DashboardStrip shows context-specific KPIs
- [ ] Refresh button triggers data reload
- [ ] All widgets render in correct positions

## Epic 6 — Planning: Milestones & Roadmap

- [ ] Create milestone with title, summary, due date, priority
- [ ] Edit milestone fields
- [ ] Delete milestone (soft delete)
- [ ] Board view groups milestones by status
- [ ] Timeline view shows milestones on horizontal axis
- [ ] List view shows all milestones with progress
- [ ] Overdue milestones highlighted in timeline
- [ ] Progress recalculation works

## Epic 7 — Planning: Tasks & Execution

- [ ] Create task with all fields
- [ ] Change task status (full lifecycle)
- [ ] Change task priority
- [ ] Link task to milestone
- [ ] Link task to epic
- [ ] Board view groups tasks by status
- [ ] Filter by status, priority, milestone
- [ ] Search finds tasks by title
- [ ] Blocked/launch-critical/waiting-external flags work

## Epic 8 — Decision Log & Daily Focus

- [ ] Create decision log entry
- [ ] Filter by category
- [ ] Daily focus screen shows top priorities
- [ ] Weekly focus screen shows milestone + task overview
- [ ] Stuck items section highlights blocked tasks
- [ ] Waiting external section shows external dependencies

## Epic 9 — UI System

- [ ] All HelaiaDesign components used correctly
- [ ] SemanticColor tokens applied everywhere
- [ ] CodalonSpacing values consistent
- [ ] Dark mode renders correctly
- [ ] Accessibility labels on interactive elements

## Epic 10 — GitHub: Connection & Repo Linking

- [ ] GitHub auth flow completes
- [ ] Repo selector shows available repositories
- [ ] Repo links to project
- [ ] Disconnect clears credentials
- [ ] Graceful degradation when disconnected

## Epic 11 — GitHub: Issues, Milestones, PRs

- [ ] Fetch issues from linked repo
- [ ] Fetch milestones from linked repo
- [ ] Fetch pull requests from linked repo
- [ ] Create issue from Codalon
- [ ] Update issue from Codalon
- [ ] Sync status reflects correctly

## Epic 12 — Release Core

- [ ] Create release with version, build number
- [ ] Release status transitions are valid
- [ ] Checklist items toggle correctly
- [ ] Blockers add/resolve correctly
- [ ] Readiness score calculates correctly
- [ ] Link tasks and GitHub issues to release

## Epic 13 — Release Cockpit

- [ ] Cockpit loads for active release
- [ ] Readiness summary shows correct percentage
- [ ] Ship readiness indicator reflects score
- [ ] Blockers panel shows resolved/unresolved
- [ ] Checklist panel shows completion progress
- [ ] Linked issues panel shows GitHub refs
- [ ] Timeline panel shows target date
- [ ] Export action generates Markdown
- [ ] Export action generates PDF
- [ ] Share button triggers share sheet

## Epic 14 — ASC Connect

- [ ] ASC connection flow completes
- [ ] Graceful degradation when disconnected
- [ ] Credential storage in keychain

## Epic 15 — ASC Builds & Metadata

- [ ] Fetch builds from ASC
- [ ] View build metadata
- [ ] View app metadata
- [ ] Release notes editing

## Epic 16 — Alerts & Notifications

- [ ] Alerts generate from rules
- [ ] Alert dismissal works
- [ ] Alert routing navigates to source
- [ ] Alert severity colors correct
- [ ] Read/unread state tracked

## Epic 17 — Rule-Based Insights

- [ ] Rule engine generates insights
- [ ] Insights display in InsightCenterView
- [ ] Health score calculates from dimensions
- [ ] Filter by severity and type
- [ ] Actionable vs informational sections separate

## Epic 19 — Context-Driven UI Engine

- [ ] Context auto-detection works
- [ ] Manual context override works
- [ ] Context proposal pill appears on change
- [ ] Each context mode renders correct canvas
- [ ] Context action bar shows correct actions

## Epic 20 — Settings & Diagnostics

- [ ] All settings tabs accessible
- [ ] AI settings load available models
- [ ] Analytics tab shows usage data
- [ ] Debug tools tab functions
- [ ] Settings persist across restarts

## Epic 21 — Analytics

- [ ] Events fire on key user actions
- [ ] Analytics dashboard shows summary
- [ ] Period picker changes data range
- [ ] Category chart renders
- [ ] Recent events list populates

## Epic 22 — Export & Sharing

- [ ] Roadmap exports as Markdown
- [ ] Roadmap exports as PDF
- [ ] Release checklist exports as Markdown
- [ ] Release checklist exports as PDF
- [ ] Project summary exports as Markdown
- [ ] Insights report exports as Markdown
- [ ] Share button works on dashboard
- [ ] Share button works in cockpit
