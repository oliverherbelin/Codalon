# Codalon — HUD Strip Component Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16

---

## 1. Component Identity

**Component name:** `CodalonHUDStrip`
**Type:** Persistent overlay, always renders on `HUD Layer` (z-index top)
**Scope:** Root shell only. Not present in onboarding state.

---

## 2. Dimensions and Positioning

| Property | Value |
|---|---|
| Height | 44 pt |
| Width | Full window width |
| Position | Anchored to bottom edge of window |
| Safe area | Respects `safeAreaInsets.bottom` — 0 on standard displays. Inset logic in place for future-proofing. |
| Z-position | Above all canvas and overlay content |
| Blur region | Extends 44 pt above the strip edge to create material bleed into canvas content |

---

## 3. Visual Appearance

| Property | Value |
|---|---|
| Background material | `.ultraThinMaterial` |
| Context tint overlay | Current context colour at 6% opacity, applied as `Rectangle` above material layer |
| Top border | 0.5 pt separator, `Color.primary.opacity(0.08)` |
| Shadow | `shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)` — casts upward |
| Corner radius | 0 — full-width flush strip |

### Context Tint Values

| Context | Tint |
|---|---|
| Development | `#4A90D9` — cool blue |
| Release | `#E8A020` — amber |
| Launch | `#2EB87A` — teal-green |

> To be reconciled against HelaiaDesign tokens before implementation.

---

## 4. Auto-Hide Behaviour

| State | Description |
|---|---|
| **Visible** | Fully rendered, opacity 1.0 |
| **Hidden** | Translated +44 pt on Y axis, opacity 0 |
| **Trigger to hide** | 2.0s inactivity timer. Resets on any mouse movement, keyboard input, or user interaction. |
| **Trigger to show** | Mouse enters 12 pt proximity zone at bottom window edge (via `NSTrackingArea`), OR any registered keyboard shortcut fires, OR a proposal pill appears. |
| **Show animation** | `translateY(+44 → 0)` + `opacity(0 → 1)`, 220ms, spring damping 0.9 |
| **Hide animation** | `translateY(0 → +44)` + `opacity(1 → 0)`, 180ms, ease-in |
| **Never auto-hides when** | A popover or panel is anchored to the HUD. HUD stays visible until that overlay is dismissed. |

> **[CTO] Build risk:** `NSTrackingArea` on a SwiftUI window edge requires bridging to `NSView`. If proximity detection proves unreliable in testing, default to **persist** with no other behaviour changes.

---

## 5. Three-Zone Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [●] Project Name          DEVELOPMENT ⬡        ● Healthy       │
│   Left Zone (flexible)    Center Zone (fixed)   Right Zone(fixed)│
└─────────────────────────────────────────────────────────────────┘
```

**Implementation:** `HStack(spacing: 0)` with:
- Left zone: `.frame(maxWidth: .infinity, alignment: .leading)` + 16 pt leading padding
- Center zone: `.frame(width: 220)` centered
- Right zone: `.frame(maxWidth: .infinity, alignment: .trailing)` + 16 pt trailing padding

---

## 6. Left Zone — Project Identity

### 6.1 Visual Structure

```
[app icon 16×16]  [Project Name]
```

| Element | Spec |
|---|---|
| App icon | `Image("AppIcon")`, 16×16 pt, `clipShape(RoundedRectangle(cornerRadius: 3))` |
| Project name | `Text`, 13pt, `.medium` weight, `primary` colour |
| Icon-label spacing | 6 pt |
| Tap target | Full zone as `.plain` `Button` |

### 6.2 Interaction

| Action | Result |
|---|---|
| Single click | Opens project switcher as a **sheet** (deliberate, heavyweight action) |
| Hover | `RoundedRectangle` fill at `Color.primary.opacity(0.06)`, corner radius 6 pt |

> Project switcher sheet is a separate component spec.

---

## 7. Center Zone — Context Indicator

### 7.1 Visual Structure

```
[mode icon 14×14]  [MODE NAME]  [proposal ring — conditional]
```

| Element | Spec |
|---|---|
| Mode icon | SF Symbol, 14×14 pt, context-tinted colour |
| Mode name | `Text`, 11pt, `.medium` weight, `.kerning(0.7)` (tracked uppercase), `primary.opacity(0.75)` |
| Layout | `HStack(spacing: 5)` |
| Tap target | Full zone as `.plain` `Button`, min 44×44 pt |

### Mode Icons

| Context | SF Symbol |
|---|---|
| Development | `hammer.fill` |
| Release | `shippingbox.fill` |
| Launch | `antenna.radiowaves.left.and.right` |

### 7.2 Proposal Ring

Shown when auto-detected mode differs from active mode.

| Property | Value |
|---|---|
| Shape | `Circle` stroke overlay around center zone button |
| Stroke | 1.5 pt, tinted with **proposed** context colour |
| Animation | `opacity` 1.0 → 0.3 → 1.0, 1.8s repeat, `.easeInOut` |
| Dismissal | Proposal accepted, dismissed, or manually overridden |

### 7.3 Interaction

| Action | Result |
|---|---|
| Single click | Opens mode override popover (see §7.4) |
| Hover | Same highlight as Left Zone |

### 7.4 Mode Override Popover

- Attachment: `.popover(attachmentAnchor: .point(.top))` anchored above HUD strip
- Width: 240 pt, height content-driven (~160 pt)
- Background: `.regularMaterial`, corner radius 10 pt, no explicit border

**Content:** `VStack(spacing: 2)` of three mode rows.

Each row layout:
```
[mode icon 16×16]  [Mode Name]          [✓ if active]
                   [One-line descriptor]
```

| Element | Spec |
|---|---|
| Row height | 52 pt minimum |
| Mode name | 13pt, medium |
| Descriptor | 11pt, `secondary` colour |
| Active row | Non-interactive, checkmark trailing, row tinted at 8% |
| Inactive row | `Button`, hover highlight consistent with zone style |
| On select | Popover dismisses → context transition fires |

---

## 8. Right Zone — Health Pulse

### 8.1 Visual Structure

```
[orb 8×8 pt]  [status label]
```

| Element | Spec |
|---|---|
| Orb | `Circle`, 8 pt diameter, health state colour |
| Status label | `Text`, 11pt, `.medium` weight, `primary.opacity(0.75)` |
| Spacing | 5 pt |
| Tap target | Full zone as `.plain` `Button` |

### Health States

| State | Orb colour | Label |
|---|---|---|
| Healthy | `#2EB87A` | `Healthy` |
| Warning | `#E8A020` | Most severe warning label |
| Critical | `#E84545` | Most severe critical label |
| No data | `Color.secondary.opacity(0.4)` | `No signals` |

> **Validated decision:** Label shows most severe signal only. Full breakdown in health popover.

Orb animation when Warning or Critical: `opacity` 1.0 → 0.4 → 1.0, 2.0s repeat, `.easeInOut`.

### 8.2 Interaction

| Action | Result |
|---|---|
| Single click | Opens health summary popover (see §8.3) |
| Hover | Same highlight as other zones |

### 8.3 Health Summary Popover

- Attachment: `.popover(attachmentAnchor: .point(.top))` anchored above HUD strip
- Width: 280 pt, height content-driven

**Content structure:**
1. Header: health state label + orb, 17pt semibold
2. `Divider`
3. Up to 5 active signals: `[signal icon]  [signal description]`, single-line rows
4. Footer: `View all` → opens inspector panel with full health detail

---

## 9. State Matrix

| App state | HUD visible | Left zone | Center zone | Right zone |
|---|---|---|---|---|
| Onboarding | Hidden | — | — | — |
| Project active, idle | Auto-hide | Project name | Active context | Health |
| Context proposal pending | Force visible | Project name | Active + pulse ring | Health |
| Mode popover open | Force visible | Project name | Active (popover open) | Health |
| Context transitioning | Visible, indicator flips | Project name | Animating | Health |
| Inspector open | Auto-hide normal | Project name | Active context | Health |
| Sheet open | Force visible | Project name | Active context | Health |

---

## 10. SwiftUI Component Sketch

Structure reference only — not final implementation.

```swift
// CodalonHUDStrip.swift

struct CodalonHUDStrip: View {
    @Environment(\.projectContext) var context
    @Environment(\.healthState) var health
    @State private var isVisible: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ProjectIdentityZone()
                .frame(maxWidth: .infinity, alignment: .leading)
            ContextIndicatorZone()
                .frame(width: 220)
            HealthPulseZone()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 44)
        .background(HUDMaterial(context: context))
        .overlay(alignment: .top) { Divider().opacity(0.08) }
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        .offset(y: isVisible ? 0 : 44)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isVisible)
    }
}
```

Environment keys `projectContext` and `healthState` are shell-level dependencies — injected at root, not owned by the HUD.

---

## 11. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | HUD visibility in full-screen | Auto-hide (2s), proximity reveal. Persist as fallback if `NSTrackingArea` unreliable. |
| 2 | Multi-monitor behaviour | Single primary window, freely movable. No secondary window. |
| 3 | Health pulse label format | Most severe signal only in strip. Full breakdown in popover. |
