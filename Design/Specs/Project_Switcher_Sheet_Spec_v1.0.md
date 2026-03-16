# Codalon — Project Switcher Sheet Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, HUD Strip Spec v1.0, First Launch & Onboarding Spec v1.0

---

## 1. Design Intent

Project switching is a deliberate, heavyweight action. It is not persistent navigation chrome. The sheet surfaces when explicitly invoked, presents the developer's projects clearly, and gets out of the way. Switching a project is a full environment replacement — the entire shell reloads for the new project.

---

## 2. Trigger

| Trigger | Result |
|---|---|
| Tap HUD left zone (project identity) | Sheet presents |
| `Cmd+Shift+P` | Sheet presents |

Sheet is never auto-shown. Always an explicit developer action.

---

## 3. Presentation

| Property | Value |
|---|---|
| Presentation style | `.sheet` anchored to main window |
| Width | 480 pt |
| Height | Content-driven, min 320 pt, max 600 pt |
| Corner radius | 16 pt |
| Background | `.regularMaterial` |
| Shadow | `shadow(color: .black.opacity(0.20), radius: 40, x: 0, y: 12)` |
| Dismissal | Escape, click outside, explicit Cancel |
| Animation entry | Standard macOS sheet slide-in from top, 280ms, `.spring(response: 0.35, dampingFraction: 0.82)` |

---

## 4. Sheet Structure

```
┌──────────────────────────────────────────────┐
│  Projects                      [+ New]  [✕]  │  ← Header, 52pt
├──────────────────────────────────────────────┤
│  [Search field]                              │  ← Search, 44pt
├──────────────────────────────────────────────┤
│                                              │
│  [Project row — active]                      │  ← Scrollable list
│  [Project row]                               │
│  [Project row]                               │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 5. Header

| Element | Spec |
|---|---|
| Title | `Projects`, 17pt, `.semibold`, `primary` |
| New project button | SF Symbol `plus`, 14pt, context tint. Trailing. Tap opens new project flow (§9). |
| Dismiss button | SF Symbol `xmark`, 12pt, `secondary`. Trailing, after `+`. Min tap target 28×28 pt. |
| Height | 52 pt |
| Bottom border | 0.5 pt, `Color.primary.opacity(0.08)` |

---

## 6. Search Field

| Property | Value |
|---|---|
| Height | 44 pt |
| Style | Standard macOS search field. `magnifyingglass` leading icon. |
| Placeholder | `Search projects` |
| Behaviour | Filters project list in real time. Case-insensitive. Matches on project name. |
| Clear | Standard clear button appears when field has content. |
| Auto-focus | Yes — focused on sheet presentation. Developer can type immediately. |
| Bottom border | 0.5 pt, `Color.primary.opacity(0.08)` |

---

## 7. Project List

Scrollable `List` or `ScrollView + LazyVStack`. No section headers unless count exceeds 10 — in that case a single `RECENT` section (last 3 opened) is pinned above `ALL PROJECTS`.

### 7.1 Project Row

```
[project icon 32×32]  [project name]       [active badge — conditional]
                      [last opened — or GitHub repo name]
                                            [context dot]
```

| Element | Spec |
|---|---|
| Row height | 56 pt |
| Project icon | 32×32 pt. If GitHub repo linked: repo owner avatar via GitHub API. If no GitHub: generated from project name initials, context tint background. `clipShape(RoundedRectangle(cornerRadius: 8))` |
| Project name | 15pt, `.medium`, `primary` |
| Subtitle | 12pt, `secondary`. If GitHub linked: `owner/repo-name`. If not: `Last opened [time ago]`. |
| Active badge | `ACTIVE` pill, 9pt, `.medium`, context tint background + label. Shown only on current project. |
| Context dot | 8×8 pt filled circle. Colour matches last active context tint for that project. Trailing. Tooltip on hover: `Last in Development Mode` etc. |
| Hover | `RoundedRectangle` fill `Color.primary.opacity(0.05)`, corner radius 8pt |
| Tap | Triggers project switch (§8). Sheet dismisses. |

### 7.2 Active Project Row

The currently active project:
- Renders at top of list regardless of sort order
- `ACTIVE` badge shown
- Non-interactive — tap does nothing, no hover state
- Subtle background: context tint at 5% opacity, full row width

### 7.3 Sort Order

| Condition | Sort |
|---|---|
| Default | Most recently opened first |
| Search active | Relevance — exact name match first, then prefix match, then contains |

### 7.4 Empty Search State

When search returns no results:

```
[magnifyingglass — large, secondary]
No projects matching "[query]"
```

Center-aligned in list area.

### 7.5 No Projects State

When no projects exist (should not occur in normal flow — onboarding creates at least one):

```
[folder — large, secondary]
No projects yet
[Create your first project]  ← button, context tint
```

---

## 8. Project Switch Sequence

On tapping an inactive project row:

1. Sheet dismisses immediately (100ms fade — faster than standard to feel responsive)
2. Shell canvas animates out: `opacity(1 → 0)`, 200ms, `.easeIn`
3. Ambient layer cross-fades to new project's last active context colour, 300ms
4. New project data loads (synchronous from local `HelaiaStorage` — no network required to render shell)
5. Shell canvas fades in with new project's last active context, 250ms, `.easeOut`
6. HUD strip updates: project name, context indicator, health pulse — all update in place with cross-fade, 200ms
7. Background sync begins for new project's integrations

If new project has never been opened (freshly created): context defaults to Development Mode. Auto-detection runs and may propose a different context via Proposal Pill.

---

## 9. New Project Flow

Triggered by `+` button in sheet header.

Presented as a **second sheet** over the project switcher sheet — or the project switcher sheet content replaces inline with a new project form. 

**Decision: inline replacement.** Project switcher sheet content cross-fades to new project form. No second sheet stacking. Simpler, cleaner.

### 9.1 New Project Form

```
[Project name field — auto-focused]
[GitHub repository selector — optional, shown if GitHub connected]

[Cancel]  [Create Project]
```

| Element | Spec |
|---|---|
| Project name | `TextField`. 17pt, `.regular`. Placeholder `My App`. Auto-focused. Full width. |
| GitHub selector | Searchable dropdown. Same spec as Onboarding Step 2 (§6.3 of Onboarding Spec). Hidden if GitHub not connected. |
| Cancel | Text button, `secondary`. Returns to project list with reverse cross-fade. |
| Create Project | Primary button, context tint. Enabled when name ≥1 non-whitespace char. |
| On create | Project created in `HelaiaStorage`. Sheet transitions to new project immediately (same sequence as §8). New project opens in Development Mode. |

---

## 10. Accessibility

| Element | Spec |
|---|---|
| VoiceOver — project rows | Label: `[Project name], last opened [time]. [Active — if current]`. Action: `Switch to [project name]` |
| VoiceOver — active row | Label: `[Project name], currently active`. Trait: not interactive. |
| VoiceOver — new project button | Label: `New project` |
| Keyboard | Tab order: search → project rows → new button → dismiss. Return on project row triggers switch. Escape dismisses. |
| Search | VoiceOver announces result count change after each keystroke: `3 projects` |

---

## 11. SwiftUI Component Sketch

Structure reference only.

```swift
// ProjectSwitcherSheet.swift

struct ProjectSwitcherSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.projectContext) var currentContext
    @State private var searchQuery: String = ""
    @State private var showingNewProject: Bool = false

    var filteredProjects: [CodalonProject] {
        guard !searchQuery.isEmpty else { return projects }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: "Projects",
                onNew: { showingNewProject = true },
                onDismiss: { dismiss() }
            )

            SearchField(text: $searchQuery, placeholder: "Search projects")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            Divider().opacity(0.08)

            if showingNewProject {
                NewProjectForm(
                    onCancel: { showingNewProject = false },
                    onCreate: { project in
                        switchToProject(project)
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .offset(y: 8)))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredProjects) { project in
                            ProjectRow(
                                project: project,
                                isActive: project.id == activeProject.id,
                                onSelect: {
                                    switchToProject(project)
                                    dismiss()
                                }
                            )
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(width: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.20), radius: 40, x: 0, y: 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showingNewProject)
    }
}
```

---

## 12. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Presentation style | `.sheet` anchored to main window. Deliberate, heavyweight — not a popover. |
| 2 | Active project in list | Shown at top, non-interactive, badged `ACTIVE`. Always visible regardless of sort or search. |
| 3 | New project flow | Inline replacement within the sheet. No second sheet stacking. |
| 4 | Switch sequence | Sheet dismisses first (fast), then shell transitions. Feels immediate. |
| 5 | Project icon | GitHub avatar if repo linked. Generated initials avatar if not. |
| 6 | Section headers | Only when >10 projects. `RECENT` (last 3) + `ALL PROJECTS`. |
