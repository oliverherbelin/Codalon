# Codalon — Release Mode Canvas Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, HUD Strip Spec v1.0, Development Mode Canvas Spec v1.0

---

## 1. Design Intent

Release Mode answers one question: **is this release ready to ship?**

The canvas is an operational cockpit, not a form. The developer sees the release state at a glance — what is done, what is missing, what is blocking — across every distribution target in a single surface.

---

## 2. Data Model Assumptions

| Model | Rule |
|---|---|
| `CodalonRelease` | Has `distributionTargets: Set<DistributionTarget>` |
| `DistributionTarget` | `.appStore`, `.testFlight`, `.gitHubRelease`, `.directDownload`, `.homebrew`, `.none` |
| Readiness checklist | Each target contributes its own checklist items. Assembled dynamically from active targets. |
| No target selected | Release is a planning milestone marker only. No readiness checks rendered. |
| Active release | Manual pin primary. Nearest target date as automatic fallback when nothing pinned. |

---

## 3. Canvas Layout Model

Three zones. Fixed proportional layout.

```
┌───────────────────────────────┬─────────────────────────────────┐
│                               │                                  │
│                               │   BUILDS & TARGETS              │
│   RELEASE READINESS PANEL     │   (top-right, 25%)              │
│                               │                                  │
│         (left, 50%)           ├─────────────────────────────────┤
│                               │                                  │
│                               │   BLOCKERS & LINKED ISSUES      │
│                               │   (bottom-right, 25%)           │
│                               │                                  │
└───────────────────────────────┴─────────────────────────────────┘
```

| Zone | Name | Height | Width |
|---|---|---|---|
| Left | Release Readiness Panel | Full canvas height | 50% |
| Top-right | Builds & Targets | 50% of canvas height | 50% |
| Bottom-right | Blockers & Linked Issues | 50% of canvas height | 50% |

Canvas padding: 24 pt all edges. Zone gap: 16 pt.

---

## 4. Zone 1 — Release Readiness Panel

### 4.1 Purpose

The centrepiece. A living checklist assembled from the release's active distribution targets. Submission readiness readable at a glance — no reading required.

### 4.2 Container

| Property | Value |
|---|---|
| Background | `.regularMaterial` + context tint (`#E8A020`) at 4% opacity |
| Corner radius | 16 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Shadow | `shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)` |
| Internal padding | 20 pt |

### 4.3 Panel Header

```
[release version]                [overall status badge]  [···]
[release name — optional]        [target date]
[distribution target pills]
```

| Element | Spec |
|---|---|
| Release version | 20pt, `.semibold`, `primary`. Format: `v1.4.2` |
| Release name | 13pt, `.regular`, `secondary`. Optional. Single line, truncated. |
| Overall status badge | Pill. States: `Ready`, `In Progress`, `Blocked`. Colours: green / amber / red. 11pt, `.medium`. |
| Target date | 12pt, `.medium`, `secondary`. Amber if ≤7 days. Red if overdue. |
| `···` button | SF Symbol `ellipsis`, `secondary`, 12pt, min tap target 28×28 pt |

**Distribution target pills** — shown below the header row.

One pill per active `DistributionTarget`. 10pt, `.medium`. Background: context tint at 10% opacity. Border: context tint at 40%.

Example:
```
[App Store]  [TestFlight]  [GitHub Release]
```

Tapping a pill scrolls the checklist to that target's section.

Header is **sticky** — remains visible while checklist scrolls.

### 4.4 Readiness Checklist

Assembled dynamically from active distribution targets. Each target renders its own section.

#### Section Header

```
[target icon]  [Target Name]  [n/total complete]
```

| Element | Spec |
|---|---|
| Target icon | SF Symbol per target (see §4.5) |
| Target name | 13pt, `.semibold`, `primary` |
| Completion count | 11pt, `secondary`. Format: `4/6` |
| Divider | 0.5 pt, `Color.primary.opacity(0.06)` below header |

#### Checklist Item Row

```
[check indicator]  [item label]  [status tag — conditional]  [action link — conditional]
```

| Element | Spec |
|---|---|
| Row height | 36 pt |
| Check indicator | 16×16 pt. Filled circle + checkmark = complete. Empty circle = incomplete. Red filled = blocking. Context tint for complete, `#E84545` for blocking, `secondary` stroke for incomplete. |
| Item label | 13pt, `.regular`. `primary` if incomplete. `secondary` + strikethrough if complete. |
| Status tag | Conditional pill: `Missing`, `Incomplete`, `Pending Review`. 10pt. Appears only when item needs attention. |
| Action link | Conditional inline tappable text: `Add now`, `Upload`, `Edit`. 12pt, context tint. Fires relevant sheet or deep link. |
| Row padding | 20 pt horizontal |
| Hover | `RoundedRectangle` fill `Color.primary.opacity(0.04)`, corner radius 6 pt |
| Tap (row) | Opens inspector or relevant sheet for that checklist item |
| Blocking row | Full row background `#E84545` at 4% opacity. Check indicator red. |

#### Checklist Items Per Target

**App Store:**
- App version set
- Build uploaded to App Store Connect
- Release notes (all active locales)
- Screenshots (all required sizes)
- App metadata complete
- Age rating set
- Export compliance answered
- Pricing set
- Submission ready

**TestFlight:**
- Build uploaded
- What to test notes written
- Beta group assigned
- Expiry date checked

**GitHub Release:**
- Git tag created
- Release notes written
- Release branch merged to main
- Assets attached (if applicable)

**Direct Download:**
- Build signed and notarized
- Download URL set
- Release notes written

**Homebrew:**
- Formula updated
- SHA256 checksum set
- PR submitted to tap

**None (planning marker only):**
- No checklist items rendered
- Panel center: `This release is a planning marker. No distribution targets selected.` 13pt, `secondary`, center-aligned.

### 4.5 Target Icons

| Target | SF Symbol |
|---|---|
| App Store | `apple.logo` |
| TestFlight | `airplane` |
| GitHub Release | `tag.fill` |
| Direct Download | `arrow.down.circle.fill` |
| Homebrew | `shippingbox.fill` |

### 4.6 Overall Readiness Logic

| Condition | Status badge |
|---|---|
| All checklist items complete across all targets | `Ready` — green |
| Some items incomplete, none blocking | `In Progress` — amber |
| One or more items blocking | `Blocked` — red |
| No targets, planning marker only | No badge rendered |

### 4.7 `···` Contextual Menu

| Action | Condition |
|---|---|
| Pin release | Always. Toggles to Unpin if already pinned. |
| Edit release | Always |
| Add distribution target | Always |
| Archive release | Always |
| View on GitHub | Only if `gitHubRelease` target active |
| View in App Store Connect | Only if `appStore` or `testFlight` target active |

### 4.8 No Active Release State

| Element | Spec |
|---|---|
| Panel opacity | 0.5 |
| Center content | `No active release`, 17pt, `.medium`, `secondary` |
| Action | `Create release` button, standard bordered style, context tint |

---

## 5. Zone 2 — Builds & Targets

### 5.1 Purpose

Live status of builds across distribution targets. TestFlight builds, App Store Connect builds, GitHub releases, or manual build records — whatever is relevant to the active release's targets.

### 5.2 Container

| Property | Value |
|---|---|
| Background | `.ultraThinMaterial` + context tint at 3% opacity |
| Corner radius | 12 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Internal padding | 16 pt |

### 5.3 Header

```
[cube.fill]  BUILDS & TARGETS
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `cube.fill`, 12pt, context tint |
| Label | `BUILDS & TARGETS`, 10pt, `.medium`, tracked uppercase, `secondary` |

### 5.4 Build Row

```
[target icon]  [build number / tag]  [status badge]  [time ago]
```

| Element | Spec |
|---|---|
| Row height | 40 pt |
| Target icon | SF Symbol per target, 14pt, context tint |
| Build number | 13pt, `.medium`, `primary`. Format: `Build 47`, `v1.4.2`, `tag: v1.4.2` depending on target. |
| Status badge | Small pill. `Processing` amber, `Ready` green, `Rejected` red, `Uploaded` blue, `Published` green, `Draft` secondary. 10pt, `.medium`. |
| Time ago | 11pt, `secondary`. Trailing. |
| Tap | Opens build detail popover (§5.5) |

Sorted by recency. Scrollable within zone.

### 5.5 Build Detail Popover

| Property | Value |
|---|---|
| Width | 300 pt |
| Attachment | Anchored to tapped row |
| Content | Build/version number, target, status, upload date, size (if known), `View in App Store Connect` / `View on GitHub` link (conditional) |

### 5.6 Empty State

```
[cube.fill — large, secondary]
No builds recorded
Builds will appear when uploaded or synced
```

Center-aligned in zone.

---

## 6. Zone 3 — Blockers & Linked Issues

### 6.1 Purpose

Release-scoped blockers and linked `CodalonTask` objects. Everything that must be resolved before this release ships.

### 6.2 Container

Same visual treatment as Zone 2.

### 6.3 Header

```
[exclamationmark.triangle.fill]  BLOCKERS & ISSUES  [count badge]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `exclamationmark.triangle.fill`, 12pt. `#E84545` if blockers present, context tint otherwise. |
| Label | `BLOCKERS & ISSUES`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Count badge | Open linked task count. Circular pill, 10pt. Red if any blockers, amber if open tasks only. |

### 6.4 Task Row

Same spec as Development Mode Canvas task row with one addition:

| Addition | Spec |
|---|---|
| Blocker flag | SF Symbol `exclamationmark`, 10pt, red, leading — shown only if task is a release blocker |

Sort order: blockers first, then open tasks by priority.
Tap: opens inspector focused on that `CodalonTask`.
Checkbox: marks complete directly from row.

### 6.5 Quick Link

Bottom of zone, always visible:

```
[plus]  Link issue to release
```

12pt, context tint. Tap opens task/issue search sheet to link an existing `CodalonTask` to the release.

### 6.6 Empty State

```
[checkmark.seal.fill — large, secondary]
No blockers
All linked issues resolved
```

---

## 7. Scrolling Behaviour

| Zone | Behaviour |
|---|---|
| Readiness Panel | Scrollable. Panel header sticky. |
| Builds & Targets | Scrollable within zone |
| Blockers & Linked Issues | Scrollable within zone |
| Canvas | Does not scroll |

---

## 8. Responsive Behaviour

At minimum window width (1200 pt):
- Right column zones compress to 50% width
- Checklist item labels truncate earlier
- Status tags hidden at very narrow widths, replaced by indicator colour only
- No layout reflow — proportions hold

---

## 9. Motion Principles

| Element | Motion |
|---|---|
| Canvas entry | Per Root Shell Spec §8.3 |
| Checklist item completion | Strikethrough animates in, 200ms. Check indicator fills with spring. |
| Blocking item resolved | Row background fades from red tint to neutral, 300ms, `.easeInOut` |
| Overall status badge change | Cross-fade between states, 250ms |
| New build row appearance | Slides in from top, 240ms, `.spring` |
| Distribution target pill added | Fades in + scales from 0.8, 200ms, `.spring` |

---

## 10. SwiftUI Component Sketch

Structure reference only.

```swift
// ReleaseModeCanvas.swift

struct ReleaseModeCanvas: View {
    @Environment(\.activeRelease) var release
    @Environment(\.projectContext) var context

    var body: some View {
        HStack(spacing: 16) {
            ReleaseReadinessPanel(release: release)
                .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                BuildsAndTargetsZone(release: release)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                BlockersAndIssuesZone(release: release)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
    }
}
```

`activeRelease` is a shell-level environment value. Canvas owns no release selection logic.

---

## 11. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Distribution targets | Multiple per release via `distributionTargets: Set<DistributionTarget>`. Each target contributes its own checklist items. |
| 2 | No-target release | Valid. Functions as planning marker only. No readiness checks rendered. |
| 3 | Active release selection | Manual pin primary. Nearest target date as automatic fallback. Consistent with milestone model. |
| 4 | Task completion from canvas | Direct checkbox on task row. No inspector required. Consistent with Development Mode. |
