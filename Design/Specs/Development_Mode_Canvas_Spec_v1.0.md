# Codalon — Development Mode Canvas Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, HUD Strip Spec v1.0

---

## 0. CTO Action Item

Before any canvas implementation begins — audit HelaiaDesign against all closed specs (Root Shell, HUD Strip, Proposal Pill, Development Mode Canvas). Produce a mapping table: Use as-is / Extend / Build new. No implementation starts until audit is complete.

---

## 1. Design Intent

Development Mode answers one question: **what is the active milestone and what is blocking it?**

The canvas is a focus environment, not a project management dashboard. The milestone is the hero — everything else is context that serves it.

---

## 2. Data Model Assumptions

| Model | Rule |
|---|---|
| `CodalonTask` | Unified task type. Native tasks have no `githubIssueRef`. GitHub-backed tasks have a `githubIssueRef`. Both appear identically in lists unless GitHub indicator is shown. |
| GitHub issues | Never displayed raw. Must be synced/imported into `CodalonTask` first. |
| Milestones | Codalon-native. GitHub milestone sync is optional. A milestone can exist with or without a GitHub counterpart. |

---

## 3. Canvas Layout Model

Three zones. Fixed proportional layout. No resizable panes.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                                                                  │
│                  MILESTONE FOCUS CARD                           │
│                        (60%)                                     │
│                                                                  │
│                                                                  │
├────────────────────────────┬────────────────────────────────────┤
│                            │                                     │
│    GIT ACTIVITY FEED       │    SPRINT HORIZON                  │
│        (bottom-left)       │    (bottom-right)                   │
│                            │                                     │
└────────────────────────────┴────────────────────────────────────┘
```

| Zone | Name | Height | Width |
|---|---|---|---|
| Top | Milestone Focus Card | 60% of canvas height | Full width |
| Bottom-left | Git Activity Feed | 40% of canvas height | 50% of canvas width |
| Bottom-right | Sprint Horizon | 40% of canvas height | 50% of canvas width |

Canvas padding: 24 pt all edges. Zone gap: 16 pt. Usable height at optimal window: ~716 pt (760 pt minus 44 pt HUD).

---

## 4. Zone 1 — Milestone Focus Card

### 4.1 Purpose

The active milestone rendered as a living card. Everything needed to understand milestone progress and unblock forward motion is visible without drilling into any other view.

### 4.2 Active Milestone Selection

**Validated decision:** Manual pin is primary. Automatic fallback when nothing is pinned.

| Rule | Behaviour |
|---|---|
| Developer has pinned a milestone | Pinned milestone is always the hero |
| No pin set | Milestone with most recent commit or task update is the hero |
| No milestones exist | No active milestone state (§4.6) |

Pinning is one tap from the `···` menu on the card.

### 4.3 Card Container

| Property | Value |
|---|---|
| Width | Full canvas width minus 48 pt (24 pt padding each side) |
| Height | ~60% of usable canvas height (~430 pt at optimal window size) |
| Background | `.regularMaterial` + context tint at 4% opacity |
| Corner radius | 16 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Shadow | `shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)` |

### 4.4 Card Internal Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  [Milestone name]                    [due date]  [progress ring] │
│  [description — single line, truncated]                    [···] │
├──────────────────────────────────────────────────────────────────┤
│  BLOCKERS (conditional)                                          │
│  ─────────────────────────────────────────────────────────────  │
│  [blocker task row]                                              │
│  [blocker task row]                                              │
├──────────────────────────────────────────────────────────────────┤
│  OPEN TASKS                                                      │
│  ─────────────────────────────────────────────────────────────  │
│  [task row]                                                      │
│  [task row]                                                      │
│  [task row]                                                      │
│  [+ N more]                                                      │
└──────────────────────────────────────────────────────────────────┘
```

#### Header Row

| Element | Spec |
|---|---|
| Milestone name | 20pt, `.semibold`, `primary` |
| Description | 13pt, `.regular`, `secondary`, single line, truncated |
| Due date | 12pt, `.medium`, `secondary`. Amber if ≤7 days. Red if overdue. |
| Progress ring | 32×32 pt `CircularProgressView`. Stroke 3pt. Context tint. Shows % tasks complete. |
| `···` button | SF Symbol `ellipsis`, `secondary`, 12pt, min tap target 28×28 pt. Trailing. |

Header padding: 20 pt horizontal, 16 pt vertical.
Divider below header: 0.5 pt, `Color.primary.opacity(0.06)`.

#### Blockers Section

Shown only when one or more `CodalonTask` has a blocker flag or is overdue.

| Element | Spec |
|---|---|
| Section label | `BLOCKERS`, 10pt, `.medium`, tracked uppercase, `#E84545` |
| Background tint | `#E84545` at 3% opacity fill across entire section |
| Max rows shown | 3. Overflow: `+ N more blockers` link, 12pt, `#E84545` |
| Overflow action | Opens inspector filtered to milestone blockers |

If no blockers: section hidden entirely. No placeholder.

#### Open Tasks Section

| Element | Spec |
|---|---|
| Section label | `OPEN TASKS`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Sort order | Priority descending, then creation date |
| Max rows shown | Fills remaining card height |
| Overflow | `+ N more` tappable label, 12pt, context tint. Opens inspector filtered to full milestone task list. |

### 4.5 Task Row

Used in both Blockers and Open Tasks sections.

```
[checkbox]  [status indicator]  [task title]  [github badge]  [priority dot]
```

| Element | Spec |
|---|---|
| Row height | 36 pt |
| Checkbox | 16×16 pt. Tap marks task complete. Validated: direct completion from row — no inspector required. |
| Status indicator | 10×10 pt circle. Empty = open, half-filled = in progress. Context tint. |
| Task title | 13pt, `.regular`, `primary`. Single line, truncates. |
| GitHub badge | Shown if `githubIssueRef` present. SF Symbol `link`, 10pt, `secondary`. |
| Priority dot | 6×6 pt filled circle. High: `#E84545`. Medium: `#E8A020`. Low: `secondary.opacity(0.4)`. |
| Row padding | 20 pt horizontal |
| Hover | `RoundedRectangle` fill `Color.primary.opacity(0.04)`, corner radius 6 pt |
| Tap (title area) | Opens inspector panel focused on that `CodalonTask` |
| Tap (checkbox) | Marks complete. Row animates out: `opacity(1→0)` + `translateX(-12pt)`, 200ms, `.easeIn`. Remaining rows close gap with spring. |

Completed tasks are not shown in the card.

### 4.6 `···` Contextual Menu

| Action | Condition |
|---|---|
| Pin milestone | Always. Toggles to Unpin if already pinned. |
| Edit milestone | Always |
| Add task | Always |
| Close milestone | Always |
| View on GitHub | Only if milestone has GitHub counterpart |

### 4.7 No Active Milestone State

| Element | Spec |
|---|---|
| Card opacity | 0.5 |
| Center content | `No active milestone`, 17pt, `.medium`, `secondary` |
| Action | `Create milestone` button, standard bordered style, context tint |
| Hidden sections | Blockers and Open Tasks sections not rendered |

---

## 5. Zone 2 — Git Activity Feed

### 5.1 Purpose

Recent repository activity. Milestone-related commits visually elevated. Context-aware, not context-locked — shows all repo activity, elevates what is relevant.

### 5.2 Container

| Property | Value |
|---|---|
| Background | `.ultraThinMaterial` + context tint at 3% opacity |
| Corner radius | 12 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Internal padding | 16 pt |

### 5.3 Header

```
[arrow.triangle.branch]  GIT ACTIVITY  [branch selector pill]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `arrow.triangle.branch`, 12pt, context tint |
| Label | `GIT ACTIVITY`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Branch selector | Pill button: current branch name, 11pt, `.medium`. Tap opens branch popover. |

### 5.4 Commit Row

```
[elevation bar]  [hash]  [message]  [time ago]
```

| Element | Spec |
|---|---|
| Row height | 32 pt |
| Elevation bar | 3 pt wide vertical bar, leading edge. Context tint if milestone-related. Transparent if not. |
| Commit hash | 7 characters, 11pt, `.monospacedDigit`, `secondary` |
| Commit message | 12pt, `.regular`, `primary`. Single line, truncates. |
| Time ago | 11pt, `secondary`. Format: `2h`, `3d`, `just now`. Trailing. |
| Milestone-related row | Full row background: context tint at 5% opacity |
| Tap | Opens commit detail popover (§5.5) |

**Milestone-related detection:** Commit message references a task ID or GitHub issue number linked to the active milestone.

Feed is scrollable within zone. Shows most recent N commits that fit zone height.

### 5.5 Commit Detail Popover

| Property | Value |
|---|---|
| Width | 320 pt |
| Attachment | Anchored to tapped row |
| Content | Full commit hash (monospaced), author, date, full commit message, changed files count, `View on GitHub` link (conditional on GitHub ref) |

### 5.6 Empty State

```
[arrow.triangle.branch — large, secondary]
No git activity
Connect a repository in project settings
```

Center-aligned. No action button in zone — settings via project settings sheet.

---

## 6. Zone 3 — Sprint Horizon

### 6.1 Purpose

Surfaces the next 2–4 upcoming milestones so the developer can plan forward motion without leaving the canvas.

### 6.2 Container

Same visual treatment as Git Activity Feed (§5.2).

### 6.3 Header

```
[chart.line.uptrend.xyaxis]  SPRINT HORIZON
```

Same spec pattern as Git Activity header. No interactive control in header.

### 6.4 Milestone Row

```
[status dot]  [milestone name]  [task count]  [due date]
```

| Element | Spec |
|---|---|
| Row height | 44 pt |
| Status dot | 8×8 pt. Amber = upcoming, no date set. Green = scheduled. Red = overdue, no tasks started. |
| Milestone name | 13pt, `.medium`, `primary` |
| Task count | 11pt, `secondary`. Format: `12 tasks` |
| Due date | 11pt, `secondary`. Amber if ≤14 days out. |
| Tap | Opens milestone detail in inspector panel |

Rows: up to 4 upcoming milestones, sorted by due date ascending. No due date → sorted by creation date.

### 6.5 Quick Add

Bottom of zone, always visible:

```
[plus]  New milestone
```

12pt, context tint. Tap opens new milestone sheet.

### 6.6 Empty State

```
[flag.checkered — large, secondary]
All clear
No upcoming milestones
[New milestone — button]
```

---

## 7. Scrolling Behaviour

| Zone | Behaviour |
|---|---|
| Milestone Focus Card — task list | Scrollable within card bounds. Card does not scroll. |
| Git Activity Feed | Scrollable within zone bounds |
| Sprint Horizon | Scrollable within zone bounds if >4 milestones |
| Canvas itself | Does not scroll. Fixed layout. Zones scroll internally. |

---

## 8. Responsive Behaviour

At minimum window width (1200 pt):
- All zones compress proportionally
- Task row titles truncate earlier
- Commit messages truncate earlier
- No layout reflow — proportions hold

Below minimum: shell enforces minimum window size via `windowResizability`.

---

## 9. Motion Principles

| Element | Motion |
|---|---|
| Canvas entry (context switch) | Per Root Shell Spec §8.3 |
| Blocker section appearance | Slides down from header, 220ms, `.spring(response: 0.3, dampingFraction: 0.8)` |
| Task row completion | `opacity(1→0)` + `translateX(-12pt)`, 200ms, `.easeIn`. Remaining rows close gap with spring. |
| New task appearance | `opacity(0→1)` + slides down 8 pt, 180ms, `.easeOut` |
| Commit row addition (live) | Slides in from top of feed, pushes rows down, 240ms, `.spring` |
| Progress ring update | Animates to new value, 400ms, `.easeInOut` |

---

## 10. SwiftUI Component Sketch

Structure reference only.

```swift
// DevelopmentModeCanvas.swift

struct DevelopmentModeCanvas: View {
    @Environment(\.activeMilestone) var milestone
    @Environment(\.projectContext) var context

    var body: some View {
        VStack(spacing: 16) {
            MilestoneFocusCard(milestone: milestone)
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight * 0.60)

            HStack(spacing: 16) {
                GitActivityFeed()
                    .frame(maxWidth: .infinity)

                SprintHorizon()
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(24)
    }
}
```

`activeMilestone` is a shell-level environment value. The canvas owns no milestone selection logic.

---

## 11. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Task model | Unified `CodalonTask`. GitHub issues must be imported. Never two raw types mixed. |
| 2 | Git activity scope | All recent repo activity. Milestone-related commits visually elevated. Context-aware, not context-locked. |
| 3 | Active milestone selection | Manual pin primary. Most recent activity as automatic fallback. |
| 4 | Task completion from canvas | Direct checkbox on task row. No inspector required for completion. |
