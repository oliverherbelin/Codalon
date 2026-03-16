# Codalon — Inspector Panel Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, Development Mode Canvas Spec v1.0, Release Mode Canvas Spec v1.0, Launch Mode Canvas Spec v1.0

---

## 1. Design Intent

The inspector is a contextual detail surface. One element at a time. Flat — no navigation depth, no back button. Tapping a related object replaces the current content with a cross-fade. Inline editing with no confirm required — changes commit immediately.

---

## 2. Component Identity

**Component name:** `CodalonInspectorPanel`
**Type:** Overlay panel, renders on `Overlay Layer`
**Scope:** All three context canvases. Behaviour identical across contexts — only content varies.

---

## 3. Dimensions and Positioning

| Property | Value |
|---|---|
| Width | 320 pt fixed |
| Height | Full canvas height (window height minus HUD strip 44 pt) |
| Position | Anchored to right edge of window |
| Overlap | Overlaps canvas content. Canvas does NOT resize. |
| Z-position | Overlay Layer — above canvas, below HUD strip, below proposal pill |

---

## 4. Visual Appearance

| Property | Value |
|---|---|
| Background | `.ultraThinMaterial` + active context tint at 8% opacity |
| Left border | 0.5 pt, `Color.primary.opacity(0.08)` |
| Corner radius | 0 — flush with window right edge |
| Shadow | `shadow(color: .black.opacity(0.12), radius: 20, x: -4, y: 0)` — casts left onto canvas |

---

## 5. Trigger and Dismissal

| Trigger | Result |
|---|---|
| Tap any inspectable element on canvas | Inspector slides in (if not open) or content replaces (if already open) |
| `Cmd+I` | Toggles inspector. If nothing selected: shows project-level summary. |
| Escape | Dismisses inspector |
| Click outside inspector bounds | Dismisses inspector |
| Tapping a related object inside inspector | Content replaces in place — no dismiss/reopen cycle |

---

## 6. Animation

### 6.1 Open

| Property | Value |
|---|---|
| Entry | `translateX(320 → 0)`, 280ms, `.spring(response: 0.32, dampingFraction: 0.82)` |
| Canvas | Does not shift |

### 6.2 Dismiss

| Property | Value |
|---|---|
| Exit | `translateX(0 → 320)` + `opacity(1 → 0)`, 220ms, `.easeIn` |

### 6.3 Content Replace

When tapping a related object replaces inspector content:

| Property | Value |
|---|---|
| Outgoing | `opacity(1 → 0)` + `translateY(0 → -8pt)`, 150ms, `.easeIn` |
| Incoming | `opacity(0 → 1)` + `translateY(8pt → 0)`, 180ms, `.easeOut` |
| Panel | Does not move — content cross-fades only |

---

## 7. Panel Structure

Every inspector state shares the same structural shell.

```
┌──────────────────────────────────────┐
│  [element type label]    [✕ dismiss] │  ← Header strip, 44pt
├──────────────────────────────────────┤
│                                      │
│  [Hero section]                      │  ← Title, status, key metadata
│                                      │
├──────────────────────────────────────┤
│                                      │
│  [Detail sections]                   │  ← Scrollable content body
│                                      │
├──────────────────────────────────────┤
│  [Action bar]                        │  ← Persistent bottom actions
└──────────────────────────────────────┘
```

### 7.1 Header Strip

| Property | Value |
|---|---|
| Height | 44 pt |
| Bottom border | 0.5 pt, `Color.primary.opacity(0.08)` |
| Element type label | 11pt, `.medium`, tracked uppercase, `secondary`. Examples: `TASK`, `MILESTONE`, `COMMIT`, `RELEASE`, `CRASH`, `REVIEW`, `FEEDBACK`, `PROJECT`. |
| Dismiss button | SF Symbol `xmark`, 12pt, `secondary`. Trailing. Min tap target 28×28 pt. |

### 7.2 Hero Section

Below header. Not scrollable — always visible.

| Property | Value |
|---|---|
| Padding | 16 pt all sides |
| Bottom border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Content | Varies by element type (see §9) |

### 7.3 Detail Sections

Scrollable content body. `ScrollView` with no visible indicator.

```
SECTION LABEL
─────────────
[content rows]
```

| Element | Spec |
|---|---|
| Section label | 10pt, `.medium`, tracked uppercase, `secondary` |
| Section divider | 0.5 pt, `Color.primary.opacity(0.06)` |
| Section spacing | 20 pt between sections |
| Row height | 32 pt minimum |

### 7.4 Action Bar

Persistent. Always visible at bottom of panel. Does not scroll.

| Property | Value |
|---|---|
| Height | 52 pt |
| Top border | 0.5 pt, `Color.primary.opacity(0.08)` |
| Padding | 16 pt horizontal |
| Max actions | 3 |
| Primary action | Context tint, `.medium` |
| Secondary actions | `secondary` colour, `.regular` |
| Destructive action | Always rightmost. `#E84545`. Specific verb: `Remove`, `Close`, `Archive` — never generic `Delete` unless no alternative. |

---

## 8. Inline Editing

All editable fields commit immediately on change. No save button. No confirm dialog.

| Field type | Behaviour |
|---|---|
| Short text (title, name) | Tap → `TextField` in place. Commits on Return or focus loss. |
| Long text (description, notes) | Tap → `TextEditor` in place. Expands to content height. Commits on focus loss. |
| Date | Tap → inline `DatePicker` below field. Dismisses on selection. |
| Status / enum | Tap → inline option list (not sheet, not popover). Selectable rows replace field. Commits immediately. |
| Toggle | `Toggle` control. Commits on tap. |
| Priority | Inline dot selector. Commits on tap. |

**Commit feedback:** Brief background flash (`context tint at 12% opacity`, 300ms fade) on the edited field confirms the change landed.

---

## 9. Element Type Specs

### 9.1 CodalonTask

**Header label:** `TASK`

**Hero section:**
```
[status indicator 12×12]  [task title — editable]
[priority selector]  [due date — editable]
```

| Element | Spec |
|---|---|
| Task title | 17pt, `.semibold`, `primary`. Tap to edit. |
| Status indicator | 12×12 pt circle. Tap cycles: open → in progress → done. |
| Priority selector | Three dots: high / medium / low. Active dot: filled context tint. |
| Due date | 12pt, `secondary`. Tap → inline `DatePicker`. |

**Detail sections:**

| Section | Content |
|---|---|
| DESCRIPTION | `TextEditor`. Placeholder `Add a description`. Expands to content. |
| MILESTONE | Linked milestone name. Tap → replaces inspector with milestone inspector. `Not linked` if none. |
| GITHUB ISSUE | Issue number + title if linked. `View on GitHub` link. `Not linked` if none. |
| LABELS | Inline tag list. `+` tap adds label via popover. Tap existing label removes it. |
| ACTIVITY | Read-only. Recent state changes. 11pt, `secondary`. |

**Action bar:**
- `Mark Complete` / `Reopen` (primary)
- `Link to Release` (secondary)
- `Remove` (destructive)

---

### 9.2 Milestone

**Header label:** `MILESTONE`

**Hero section:**
```
[milestone name — editable]
[progress ring 28×28]  [X of Y tasks complete]  [due date — editable]
```

| Element | Spec |
|---|---|
| Milestone name | 17pt, `.semibold`. Tap to edit. |
| Progress ring | 28×28 pt, stroke 3pt, context tint. |
| Task count | 13pt, `secondary`. Format: `8 of 12 tasks complete` |
| Due date | 12pt, `secondary`. Tap → inline DatePicker. Amber ≤7 days. Red if overdue. |

**Detail sections:**

| Section | Content |
|---|---|
| DESCRIPTION | `TextEditor`. Placeholder `Add a description`. |
| TASKS | Compact task list. Row height 32pt. Tap task → replaces inspector with task inspector. `+ Add task` at bottom. |
| GITHUB MILESTONE | Linked GitHub milestone if present. Sync status + `Sync now` link. |

**Action bar:**
- `Pin as Active` / `Unpin` (primary)
- `Close Milestone` (secondary)
- `Archive` (destructive)

---

### 9.3 Commit

**Header label:** `COMMIT`

**Hero section:**
```
[full commit hash — monospaced, selectable]
[commit message — full, wraps]
[author]  [date + time]
```

| Element | Spec |
|---|---|
| Hash | 11pt, `.monospacedDigit`, `secondary`. Full 40-char. Selectable. |
| Message | 14pt, `.regular`, `primary`. Full message, wraps. Read-only. |
| Author | 12pt, `secondary` |
| Date | 12pt, `secondary`. Format: `16 Mar 2026, 14:32` |

**Detail sections:**

| Section | Content |
|---|---|
| CHANGED FILES | File paths. 11pt, `.monospacedDigit`, `secondary`. `+N` added, `-N` removed in header. |
| LINKED TASKS | `CodalonTask` objects detected via message parsing. Tap → replaces with task inspector. Empty: `No linked tasks detected`. |
| BRANCH | Branch name. 12pt, `.monospacedDigit`. |

**Action bar:**
- `View on GitHub` (primary — only if GitHub-backed)
- `Copy Hash` (secondary)

Read-only. No inline editing. No destructive action.

---

### 9.4 Release

**Header label:** `RELEASE`

**Hero section:**
```
[version — editable]  [overall status badge]
[release name — editable, optional]
[target date — editable]
[distribution target pills]
```

Same layout as Release Mode Canvas readiness panel header at inspector proportions.

**Detail sections:**

| Section | Content |
|---|---|
| DISTRIBUTION TARGETS | One row per target. Toggle to add/remove. Tap target name → target-specific detail popover. |
| LINKED TASKS | Tasks linked to this release. Tap → replaces with task inspector. `+ Link issue` at bottom. |
| NOTES | `TextEditor`. Internal release notes (not App Store release notes). |
| BUILDS | Most recent build per active target. Same row spec as Release Mode Canvas builds zone. |

**Action bar:**
- `Pin as Active` / `Unpin` (primary)
- `Archive Release` (secondary)
- `Delete` — only if release has no submitted builds. Hidden otherwise. (destructive)

---

### 9.5 Crash Event

**Header label:** `CRASH`

**Hero section:**
```
[severity dot 12×12]  [exception type]
[affected sessions]  [first seen]  [last seen]
```

| Element | Spec |
|---|---|
| Exception type | 16pt, `.semibold`, `primary`. Read-only. |
| Affected sessions | 13pt, `secondary` |
| First / last seen | 12pt, `secondary` |

**Detail sections:**

| Section | Content |
|---|---|
| CRASH SIGNATURE | Full crash signature. `.monospacedDigit`, 10pt, `secondary`. Max 10 lines, scrollable. |
| AFFECTED DEVICES | OS version + device model breakdown. 12pt, `secondary`. |
| DISTRIBUTION | Source: `App Store` or `TestFlight`. 12pt, `secondary`. |

**Action bar:**
- `View in App Store Connect` (primary)
- `Create Task` (secondary — pre-filled with crash info)

Read-only. No inline editing.

---

### 9.6 App Store Review

**Header label:** `REVIEW`

**Hero section:**
```
[star rating]
[review title]
[territory flag]  [date]
```

| Element | Spec |
|---|---|
| Star rating | 5 stars, 16pt. Context tint for earned stars. |
| Review title | 16pt, `.semibold`, `primary`. Read-only. |
| Territory + date | 12pt, `secondary` |

**Detail sections:**

| Section | Content |
|---|---|
| REVIEW BODY | Full review text. 13pt, `.regular`, `primary`. Read-only. Wraps fully. |
| REVIEWER | Reviewer display name as provided by ASC API. 12pt, `secondary`. |

**Action bar:**
- `View in App Store Connect` (primary)
- `Create Task` (secondary)

Read-only. No inline editing.

---

### 9.7 Tester Feedback

**Header label:** `FEEDBACK`

**Hero section:**
```
[tester identifier]  [build version]  [date]
```

| Element | Spec |
|---|---|
| Tester identifier | 16pt, `.semibold`, `primary`. Anonymised. Read-only. |
| Build version | 13pt, `secondary` |
| Date | 12pt, `secondary` |

**Detail sections:**

| Section | Content |
|---|---|
| FEEDBACK | Full feedback text. 13pt, `.regular`, `primary`. Read-only. |
| SCREENSHOT | Inline thumbnail if attached. Full width. Tap → expands in popover. Hidden if none. |
| DEVICE | Device model + OS version. 12pt, `secondary`. |

**Action bar:**
- `View in App Store Connect` (primary)
- `Create Task` (secondary)

Read-only. No inline editing.

---

### 9.8 Project Summary (default state)

Shown when inspector opened via `Cmd+I` with no element selected.

**Header label:** `PROJECT`

**Hero section:**
```
[project name]
[GitHub repo — if connected]
[last activity — time ago]
```

**Detail sections:**

| Section | Content |
|---|---|
| HEALTH | Overall health score + breakdown by signal type |
| ACTIVE MILESTONE | Milestone name + progress. Tap → replaces with milestone inspector. |
| ACTIVE RELEASE | Release version + status. Tap → replaces with release inspector. |
| INTEGRATIONS | GitHub: connected / disconnected. App Store Connect: connected / disconnected. Status dots. |

**Action bar:**
- `Project Settings` (primary — opens settings sheet)

---

## 10. SwiftUI Component Sketch

Structure reference only.

```swift
// CodalonInspectorPanel.swift

struct CodalonInspectorPanel: View {
    @Binding var selection: InspectorSelection?
    @Environment(\.projectContext) var context

    var body: some View {
        VStack(spacing: 0) {
            InspectorHeader(selection: selection) {
                selection = nil
            }

            Group {
                switch selection {
                case .task(let task):
                    TaskInspector(task: task, onNavigate: { selection = $0 })
                case .milestone(let milestone):
                    MilestoneInspector(milestone: milestone, onNavigate: { selection = $0 })
                case .commit(let commit):
                    CommitInspector(commit: commit, onNavigate: { selection = $0 })
                case .release(let release):
                    ReleaseInspector(release: release, onNavigate: { selection = $0 })
                case .crash(let crash):
                    CrashInspector(crash: crash, onNavigate: { selection = $0 })
                case .review(let review):
                    ReviewInspector(review: review)
                case .feedback(let feedback):
                    TesterFeedbackInspector(feedback: feedback, onNavigate: { selection = $0 })
                case nil:
                    ProjectSummaryInspector()
                }
            }
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 8)),
                    removal: .opacity.combined(with: .offset(y: -8))
                )
            )
            .animation(.easeOut(duration: 0.18), value: selection)
        }
        .frame(width: 320)
        .background(InspectorBackground(context: context))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, x: -4, y: 0)
    }
}

enum InspectorSelection: Hashable {
    case task(CodalonTask)
    case milestone(CodalonMilestone)
    case commit(CodalonCommit)
    case release(CodalonRelease)
    case crash(CrashEvent)
    case review(AppStoreReview)
    case feedback(TesterFeedback)
}
```

`onNavigate` callback receives a new `InspectorSelection`. Shell replaces `selection` binding, triggering the content cross-fade. No navigation stack involved.

---

## 11. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Navigation depth | Flat — always one level. No back button. |
| 2 | Related object navigation | Tapping a related object replaces inspector content in place. No dismiss/reopen. |
| 3 | Editing confirmation | Inline, immediate commit. No save button. No confirm dialog. |
| 4 | Default state | Project summary when opened with no selection via Cmd+I. |
| 5 | Read-only types | Commit, Crash Event, App Store Review, Tester Feedback. No inline editing. |
