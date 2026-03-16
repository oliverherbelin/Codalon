# Codalon — Root Shell Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** HUD Strip Spec v1.0, Proposal Pill Spec v1.0

---

## 1. Design Intent

The shell is a living canvas, not a dashboard. There is no persistent navigation chrome. The window surface IS the product surface. UI elements appear when needed, disappear when not. The developer always knows where they are, what context is active, and what to focus on — without navigation menus telling them.

One question drives every decision in this shell:

> **What should I focus on now?**

---

## 2. Window Properties

| Property | Value |
|---|---|
| Minimum size | 1200 × 760 pt |
| Optimal size | 1440 × 900 pt |
| Full screen | Supported |
| Resizable | Yes |
| Title bar | Standard macOS. Project name centered. No document proxy icon. Traffic lights left. |
| Toolbar | None — removed entirely |
| Title bar right slot | Single optional context action, defined per-context canvas spec |

Title bar displays the **project name**, not "Codalon", once a project is active.

### Multi-monitor

Single primary window, freely movable across displays. No secondary window spawned automatically. Sheets and popovers anchor to the primary window. Inspector panel stays within primary window bounds.

---

## 3. Layer Stack

Five layers, bottom to top:

| Layer | Index | Name | Description |
|---|---|---|---|
| 0 | Ambient Layer | Full-window background. Animated gradient + noise texture. Context-reactive. |
| 1 | Canvas Layer | Primary working surface. Context-driven content. Owned entirely by the active context. |
| 2 | Overlay Layer | Popovers, inspector panels, sheets. Appears above canvas. |
| 3 | HUD Layer | Minimal persistent anchor strip. Always on top of canvas. Auto-hides. |
| 4 | Proposal Layer | Context-change proposal pill. Transient. Below HUD, above canvas. |

---

## 4. Navigation Paradigm

No sidebar. No tab bar. No toolbar. No breadcrumbs. No back buttons.

The developer always operates at the top level of the current context. Navigation is replaced by:

| Mechanism | Trigger | Use |
|---|---|---|
| Contextual menu | Right-click any element | Actions on that element |
| Popover | Click a discrete element | Quick detail, quick action |
| Inspector panel | Cmd+I or element disclosure | Deep-dive on selected item. Slides in from right edge. |
| Sheet | Explicit creation or edit action | New issue, new release, settings. Full or partial height. |
| HUD center zone tap | Single click | Mode override |
| HUD left zone tap | Single click | Project switcher |
| Keyboard shortcuts | Global | See §5 |

---

## 5. Global Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Switch to Development Mode | ⌥1 |
| Switch to Release Mode | ⌥2 |
| Switch to Launch Mode | ⌥3 |
| Toggle Inspector | ⌘I |
| Project switcher | ⌘⇧P |

---

## 6. Ambient Layer

Functional mood-signalling. Reinforces active context without requiring the developer to read labels.

| Context | Ambient character |
|---|---|
| Development | Deep neutral, cool blue-grey undertone. Low energy. Focus state. |
| Release | Warmer mid-tone. Subtle amber shift. Elevated energy. |
| Launch | Slightly more vivid. Teal-green cast. Live, monitored feeling. |

**Implementation:** Full-window SwiftUI `Canvas` or `AngularGradient` with low-opacity noise texture overlay. No Metal required unless performance demands it. Gradient animates on context change — cross-fade over 380ms. Never distracting.

**Blur test:** Blur the screen — the active context must still be readable by colour alone.

---

## 7. Context System

### 7.1 Three Contexts

| Context | Primary signal |
|---|---|
| Development | What is the active milestone and what is blocking it? |
| Release | Is this release ready to ship? |
| Launch | Is the live product healthy? |

### 7.2 Auto-Detection Rules

The rule engine (Epic 17) reads project signals and proposes the most relevant context:

| Signal | Proposed context |
|---|---|
| Active release with blockers | Release Mode |
| Recent App Store submission | Launch Mode |
| No active release, open milestone | Development Mode |

Auto-detection **proposes** — it does not force. The developer confirms or overrides.

### 7.3 Manual Override

- Always one deliberate action away: tap HUD center zone
- Manual selection persists until either: developer manually switches again, or rule engine detects a high-confidence signal change (threshold defined in Epic 17)
- Manual override suppresses auto-detection proposals until significant signal change

### 7.4 Context Detection Priority

1. Auto-detection (primary)
2. Manual override (always available, always wins once set)

---

## 8. Context Switching — Full Mechanic

### 8.1 Auto-Detection Proposal Flow

1. Rule engine emits `ContextProposalEvent` via `EventBus`
2. Proposal Pill appears at top-center canvas (see Proposal Pill Spec v1.0)
3. HUD Center Zone proposal ring activates simultaneously
4. Developer taps **Switch** → context transition executes (§8.3)
5. Developer taps **✕** or ignores → pill auto-dismisses at 8s, proposal suppressed

### 8.2 Manual Override Flow

1. Developer taps HUD Center Zone
2. Mode override popover opens immediately above HUD strip
3. Developer selects a mode
4. Popover dismisses → context transition executes (§8.3)

### 8.3 Context Transition Animation

| Property | Value |
|---|---|
| Total duration | 380ms |
| Curve | `.spring(dampingFraction: 0.82, response: 0.45)` |
| Canvas content exit | `opacity(1 → 0)` + `translateX(±24 pt)` in direction of travel |
| Canvas content entry | `opacity(0 → 1)` + from `±24 pt` offset in direction of travel |
| Ambient layer | Cross-fade to new context tint over 380ms |
| HUD center indicator | `.rotation3DEffect` on Y axis, 200ms, centered on transition |

**Direction of travel:**
- Dev → Release → Launch: content exits left, enters from right (forward)
- Any reverse direction: content exits right, enters from left (backward)
- Manual override to non-adjacent mode: cross-fade only, no directional slide

---

## 9. Context Canvases

Each context owns its full canvas layout. These are complete environment states, not tabs.

### 9.1 Development Mode Canvas

**Primary signal:** What is the active milestone and what is blocking it?

| Zone | Content | Weight |
|---|---|---|
| Top 60% | Active milestone focus card + open issue stack | Primary |
| Bottom-left 40% | Recent git activity feed | Secondary |
| Bottom-right 40% | Upcoming milestones / next sprint preview | Tertiary |

### 9.2 Release Mode Canvas

**Primary signal:** Is this release ready to ship?

| Zone | Content | Weight |
|---|---|---|
| Left 50% | Release readiness panel (checklist with status indicators) | Primary |
| Top-right 25% | Linked builds / TestFlight status | Secondary |
| Bottom-right 25% | Blockers list, linked issues | Tertiary |

The readiness panel is the centrepiece. Blockers render amber/red. Complete items render with a check. Submission readiness is readable at a glance with no reading required.

**Example readiness panel:**
```
Release 1.4 ──────────────────
Code ready:       ✓
QA completed:     ✓
Store metadata:   ✗
Screenshots:      ✓
Localization:     80%
Submission:       pending
```

### 9.3 Launch Mode Canvas

**Primary signal:** Is the live product healthy?

| Zone | Content | Weight |
|---|---|---|
| Left 40% | Crash feed + error rate graph | Primary |
| Top-right 30% | Reviews feed (App Store) + rating trend | Secondary |
| Bottom-right 30% | Support signal (ticket count, unread) | Tertiary |

> Individual canvas zone layouts are each a separate component spec.

---

## 10. Inspector Panel

| Property | Value |
|---|---|
| Trigger | Cmd+I or explicit disclosure on any element |
| Width | 320 pt fixed |
| Position | Slides in from right window edge |
| Animation | 280ms, `.spring(response: 0.32, dampingFraction: 0.82)` |
| Background | `.ultraThinMaterial` + context tint at 8% opacity |
| Dismissal | Cmd+I again, click outside, Escape |
| Canvas behaviour | Canvas content does NOT resize — inspector overlaps right edge |
| Default state | If nothing selected: shows project-level summary |

---

## 11. First Launch State

Shown only when no project has been configured. Never shown again after initial setup.

### 11.1 Layout

Full canvas, centered card. No HUD strip visible. Ambient layer renders at Development Mode default.

| Property | Value |
|---|---|
| Card dimensions | 560 × 440 pt |
| Corner radius | 20 pt |
| Background | `.thickMaterial` |
| Position | Centered in window |

### 11.2 Three-Step Flow

Step content is inline within the card. No navigation chrome, no progress bar, no back button. Each step replaces the previous with a crossfade + 16 pt upward slide (180ms, `.easeInOut`).

| Step | Content |
|---|---|
| 1 | Connect GitHub — PAT input field + required scopes hint (repo, read:user) |
| 2 | Select or create project — list of GitHub repos, searchable |
| 3 | Codalon analyses project signals → proposes initial context → developer selects |

**Step 3 validated decision:** Selecting a context directly commits and launches — no confirm button. Action is obvious and trivially reversible.

### 11.3 Completion Animation

On Step 3 context selection:
- Card animates away: `scale(1 → 0.94)` + `opacity(1 → 0)`, 320ms, `.easeIn`
- Shell loads with confirmed context transition (§8.3)
- HUD strip fades in after shell canvas is visible

---

## 12. Re-launch Behaviour

| Condition | Behaviour |
|---|---|
| Project configured, last context known | Drops directly into last active context. No neutral home state. |
| Project configured, no last context | Runs auto-detection, proposes context via pill |
| No project configured | First launch state (§11) |

---

## 13. What Is Never Visible

| Element | Status |
|---|---|
| Sidebar | Never |
| Tab bar | Never |
| Toolbar | Never |
| Breadcrumb trail | Never |
| Persistent navigation buttons | Never |
| Hamburger or overflow menus at root level | Never |
| Visible scroll indicators at canvas level | Never (content zones scroll normally internally) |
| Status bar beyond HUD strip | Never |

---

## 14. Component Dependency Map

```
Root Shell
├── Ambient Layer               (owned by shell)
├── Canvas Layer
│   ├── Development Mode Canvas (separate spec)
│   ├── Release Mode Canvas     (separate spec)
│   └── Launch Mode Canvas      (separate spec)
├── Overlay Layer
│   ├── Inspector Panel         (separate spec)
│   ├── Sheets                  (per-feature specs)
│   └── Popovers                (per-feature specs)
├── HUD Layer
│   └── CodalonHUDStrip         (HUD Strip Spec v1.0)
└── Proposal Layer
    └── CodalonProposalPill     (Proposal Pill Spec v1.0)
```

---

## 15. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Project scope at root | One project active at a time. Switching is deliberate. |
| 2 | Launch behaviour | Drops into last active context. First launch only gets onboarding state. |
| 3 | Context switching authority | Auto-detection primary. Manual override always available, one action away. Codalon proposes — developer confirms. |
| 4 | HUD visibility in full-screen | Auto-hide (2s inactivity). Proximity reveal via `NSTrackingArea` (12 pt zone). Persist as fallback. |
| 5 | Multi-monitor | Single primary window, freely movable. No secondary window. |
| 6 | Onboarding Step 3 confirm | No confirm button — direct selection commits and launches. Trivially reversible. |
| 7 | Health pulse label format | Most severe signal only in HUD. Full breakdown in health popover. |
| 8 | Multiple rapid proposals | Replace — incoming replaces outgoing if confidence delta significant. No queue. Threshold in Epic 17. |

---

## 16. Open Items (Deferred to Child Specs)

| Item | Deferred to |
|---|---|
| Development Mode canvas zone layout detail | Development Mode Canvas Spec |
| Release Mode canvas zone layout detail | Release Mode Canvas Spec |
| Launch Mode canvas zone layout detail | Launch Mode Canvas Spec |
| Inspector panel content and states | Inspector Panel Spec |
| Project switcher sheet | Project Switcher Sheet Spec |
| Rule engine signal definitions and thresholds | Epic 17 |
| Context tint token reconciliation | HelaiaDesign token audit |
