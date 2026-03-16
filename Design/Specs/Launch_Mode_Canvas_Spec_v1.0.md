# Codalon — Launch Mode Canvas Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, HUD Strip Spec v1.0, Release Mode Canvas Spec v1.0

---

## 1. Design Intent

Launch Mode answers one question: **is the live product healthy?**

The canvas is a monitoring environment. Signal set adapts to what is available for the active distribution target — unavailable signals are hidden, not shown as empty or disabled. The developer sees only what is real.

---

## 2. Data Model Assumptions

| Signal | Source | Available for |
|---|---|---|
| Crash data | App Store Connect API | App Store, TestFlight |
| Reviews | App Store Connect API | App Store only |
| Ratings trend | App Store Connect API | App Store only |
| Tester feedback | App Store Connect API | TestFlight only |
| Download count | App Store Connect API | App Store, TestFlight, Direct Download |

Unavailable signals: zones hidden entirely. No placeholder, no disabled state. Canvas recomposes around what exists.

Multi-target active: signals from all active targets aggregated. Source labelled per signal row where ambiguity exists.

---

## 3. Canvas Layout Model

Layout is dynamic — composes from available signal zones based on active distribution targets.

### 3.1 Full Signal Canvas (App Store active)

```
┌──────────────────────────┬──────────────────────────────────────┐
│                          │                                       │
│                          │   REVIEWS & RATINGS                  │
│   CRASH MONITOR          │   (top-right)                        │
│                          │                                       │
│   (left, 40%)            ├───────────────────────────────────── ┤
│                          │                                       │
│                          │   DISTRIBUTION PULSE                 │
│                          │   (bottom-right)                     │
│                          │                                       │
└──────────────────────────┴──────────────────────────────────────┘
```

| Zone | Name | Height | Width |
|---|---|---|---|
| Left | Crash Monitor | Full canvas height | 40% |
| Top-right | Reviews & Ratings | 55% of canvas height | 60% |
| Bottom-right | Distribution Pulse | 45% of canvas height | 60% |

### 3.2 TestFlight-only Canvas

Reviews & Ratings hidden. Tester Feedback replaces it.

```
┌──────────────────────────┬──────────────────────────────────────┐
│                          │                                       │
│                          │   TESTER FEEDBACK                    │
│   CRASH MONITOR          │   (top-right)                        │
│                          │                                       │
│   (left, 40%)            ├───────────────────────────────────── ┤
│                          │                                       │
│                          │   DISTRIBUTION PULSE                 │
│                          │   (bottom-right)                     │
│                          │                                       │
└──────────────────────────┴──────────────────────────────────────┘
```

### 3.3 GitHub Release / Direct Download Canvas

No crash data. No reviews. Distribution Pulse only.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                   DISTRIBUTION PULSE                             │
│                   (full canvas)                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

Canvas padding: 24 pt all edges. Zone gap: 16 pt.

---

## 4. Zone 1 — Crash Monitor

### 4.1 Purpose

Primary signal. Surfaces crash rate, crash feed, and error trend at a glance. Available when distribution target is App Store or TestFlight.

### 4.2 Container

| Property | Value |
|---|---|
| Background | `.regularMaterial` + context tint (`#2EB87A`) at 4% opacity |
| Corner radius | 16 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)`. Turns `#E84545` at 40% opacity when crash rate is critical. |
| Shadow | `shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)` |
| Internal padding | 20 pt |

### 4.3 Header

```
[waveform.path.ecg]  CRASH MONITOR  [health badge]  [time range selector]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `waveform.path.ecg`, 12pt, context tint. Turns red when critical. |
| Label | `CRASH MONITOR`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Health badge | Pill. `Stable` green, `Elevated` amber, `Critical` red. 10pt, `.medium`. |
| Time range selector | `24h`, `7d`, `30d`. 11pt. Trailing. Adjusts all data in zone. |

### 4.4 Crash Rate Summary

```
[large crash rate number]  crashes / session
[delta indicator vs previous period]
```

| Element | Spec |
|---|---|
| Rate number | 34pt, `.semibold`, `primary`. Format: `0.4%` |
| Unit label | 13pt, `.regular`, `secondary`. `crashes / session` |
| Delta | 12pt, `.medium`. Format: `↑ 0.2% vs last 7d`. Red if increasing, green if decreasing, secondary if flat. |

### 4.5 Error Rate Sparkline

| Property | Value |
|---|---|
| Height | 56 pt |
| Width | Full zone width minus padding |
| Style | Area chart. Fill: context tint at 15% opacity. Line: context tint, 1.5pt stroke. Turns red when critical. |
| X axis | No labels. Implicit time progression left to right. |
| Y axis | No labels. Relative scale only. |
| Interaction | Tap+hold: floating label shows exact value + timestamp above touched point. |
| Implementation | Swift Charts (`Chart` framework) |

### 4.6 Crash Feed

Scrollable list of recent crash events below sparkline.

#### Crash Row

```
[severity dot]  [crash type]  [affected sessions]  [first seen]
```

| Element | Spec |
|---|---|
| Row height | 44 pt |
| Severity dot | 8×8 pt. Red = crash, amber = non-fatal error. |
| Crash type | 13pt, `.medium`, `primary`. Single line, truncates. |
| Affected sessions | 11pt, `secondary`. Format: `42 sessions` |
| First seen | 11pt, `secondary`. Format: `2h ago`. Trailing. |
| NEW badge | `NEW` pill, 9pt, red. Shown if crash first appeared within last 24h. |
| Source tag | `App Store` or `TestFlight`, 9pt, `secondary`. Shown only if multiple targets active. |
| Tap | Opens crash detail popover (§4.7) |

Sort: severity descending, then affected session count descending.

New crash arrival animation: row slides in from top, 240ms, `.spring`. `NEW` badge pulses for 3s then settles. Health badge and HUD orb re-evaluate immediately.

### 4.7 Crash Detail Popover

| Property | Value |
|---|---|
| Width | 340 pt |
| Attachment | Anchored to tapped row |
| Content | Exception type, crash signature (3 lines max), OS version, device model, affected session count, first seen, last seen, `View in App Store Connect` link |

### 4.8 Empty State (no crashes)

```
[checkmark.shield.fill — large, context tint]
No crashes recorded
```

Positive signal — renders in context tint, not secondary.

### 4.9 Not Available

Zone hidden entirely when target has no crash signal. Canvas recomposes (§3.3).

---

## 5. Zone 2a — Reviews & Ratings

### 5.1 Purpose

App Store review feed and ratings trend. App Store distribution only.

### 5.2 Container

| Property | Value |
|---|---|
| Background | `.ultraThinMaterial` + context tint at 3% opacity |
| Corner radius | 12 pt |
| Border | 0.5 pt, `Color.primary.opacity(0.06)` |
| Internal padding | 16 pt |

### 5.3 Header

```
[star.fill]  REVIEWS & RATINGS  [current rating]  [time range selector]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `star.fill`, 12pt, context tint |
| Label | `REVIEWS & RATINGS`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Current rating | `4.7 ★`, 13pt, `.semibold`, `primary`. Trailing. |
| Time range | `7d`, `30d`, `All`. 11pt. Trailing. |

### 5.4 Rating Distribution Bars

```
★★★★★  ████████████████░░░░  142
★★★★   ████░░░░░░░░░░░░░░░░  38
★★★    ██░░░░░░░░░░░░░░░░░░  12
★★     █░░░░░░░░░░░░░░░░░░░  6
★      █░░░░░░░░░░░░░░░░░░░  4
```

| Element | Spec |
|---|---|
| Star labels | 10pt, `secondary` |
| Bar | `RoundedRectangle`, 6pt height, context tint fill, `secondary.opacity(0.15)` track |
| Count | 10pt, `secondary`, trailing |
| Block height | 80 pt total |

### 5.5 Review Feed

#### Review Row

```
[star rating]  [review title]  [territory flag]  [date]
[review body — 2 lines max]
```

| Element | Spec |
|---|---|
| Row height | 72 pt minimum |
| Star rating | 5 stars, 10pt. Context tint for earned stars. |
| Review title | 13pt, `.semibold`, `primary`. Single line, truncated. |
| Territory | Country flag emoji, 12pt |
| Date | 11pt, `secondary`. Trailing. |
| Review body | 12pt, `.regular`, `secondary`. 2 lines max, truncated. |
| Tap | Expands row inline to show full review. Second tap collapses. |

Sort: most recent first.

### 5.6 Empty State

```
[star — large, secondary]
No reviews yet
Reviews will appear after your first ratings
```

---

## 6. Zone 2b — Tester Feedback

### 6.1 Purpose

Replaces Reviews & Ratings for TestFlight-only distribution. Surfaces feedback submitted by testers via TestFlight Feedback API.

### 6.2 Container

Same as Zone 2a.

### 6.3 Header

```
[person.2.fill]  TESTER FEEDBACK  [unread count badge]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `person.2.fill`, 12pt, context tint |
| Label | `TESTER FEEDBACK`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Unread badge | Circular, red, 10pt. Shown only if unread feedback exists. |

### 6.4 Feedback Row

```
[tester identifier]  [build version]  [date]
[feedback text — 2 lines max]
[screenshot indicator — conditional]
```

| Element | Spec |
|---|---|
| Row height | 72 pt minimum |
| Tester identifier | 13pt, `.medium`, `primary`. Anonymised: `Tester A`, `Tester B`. |
| Build version | 11pt, `secondary`. Format: `Build 47` |
| Date | 11pt, `secondary`. Trailing. |
| Feedback text | 12pt, `.regular`, `secondary`. 2 lines max, truncated. |
| Screenshot indicator | SF Symbol `photo`, 10pt, `secondary`. Tap opens screenshot in popover. |
| Tap | Expands row inline. Second tap collapses. |

### 6.5 Empty State

```
[person.2.fill — large, secondary]
No tester feedback yet
Feedback will appear when testers submit via TestFlight
```

---

## 7. Zone 3 — Distribution Pulse

### 7.1 Purpose

Download and distribution activity. Available for all targets that report download/install counts. Always shown when any active distribution target is present.

### 7.2 Container

Same as Zone 2a.

### 7.3 Header

```
[arrow.down.circle.fill]  DISTRIBUTION PULSE  [time range selector]
```

| Element | Spec |
|---|---|
| Icon | SF Symbol `arrow.down.circle.fill`, 12pt, context tint |
| Label | `DISTRIBUTION PULSE`, 10pt, `.medium`, tracked uppercase, `secondary` |
| Time range | `24h`, `7d`, `30d`. Trailing. |

### 7.4 Download Summary

```
[large download count]  downloads
[delta vs previous period]
```

Same layout as crash rate summary (§4.4). Count in 34pt `.semibold`. Delta green if increasing, secondary if flat, red if declining.

### 7.5 Download Sparkline

Same spec as §4.5. Context tint throughout — no critical colour state.

### 7.6 Per-Target Breakdown

```
[target icon]  [target name]  [count]  [delta]
```

| Element | Spec |
|---|---|
| Row height | 36 pt |
| Target icon | SF Symbol per target, 12pt, context tint |
| Target name | 12pt, `.regular`, `primary` |
| Count | 12pt, `.medium`, `primary`. Trailing. |
| Delta | 11pt. Green / red / secondary. Format: `+14%` |

### 7.7 Empty State

```
[arrow.down.circle — large, secondary]
No download data yet
Data will appear after first distribution activity
```

---

## 8. HUD Health Pulse Integration

Launch Mode is the primary driver of the HUD health orb.

| Canvas state | HUD orb | HUD label |
|---|---|---|
| No crashes, ratings stable | Green | `Healthy` |
| Crash rate elevated or rating declining | Amber | `Elevated` |
| Crash rate critical or new crash in last hour | Red | `Crash detected` |
| No signal data available | Secondary | `No signals` |

Refresh interval: 5 minutes background. Immediate on app foreground.

---

## 9. Motion Principles

| Element | Motion |
|---|---|
| Canvas entry | Per Root Shell Spec §8.3 |
| Canvas recomposition | Zones fade out, remaining zones reflow with spring, 300ms |
| New crash row | Slides in from top, 240ms, `.spring` |
| Health badge change | Cross-fade, 250ms |
| Sparkline data update | Path animates to new values, 400ms, `.easeInOut` |
| Rating bar update | Bar width animates, 350ms, `.spring` |
| New review row | Slides in from top, 220ms, `.spring` |
| Row expand | Height animates open, 200ms, `.spring(response: 0.3, dampingFraction: 0.82)` |

---

## 10. SwiftUI Component Sketch

Structure reference only.

```swift
// LaunchModeCanvas.swift

struct LaunchModeCanvas: View {
    @Environment(\.activeDistribution) var distribution
    @Environment(\.projectContext) var context

    var availableSignals: SignalSet {
        SignalSet(from: distribution.activeTargets)
    }

    var body: some View {
        HStack(spacing: 16) {
            if availableSignals.hasCrashData {
                CrashMonitorZone()
                    .frame(width: canvasWidth * 0.40)
            }

            VStack(spacing: 16) {
                if availableSignals.hasReviews {
                    ReviewsAndRatingsZone()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if availableSignals.hasTesterFeedback {
                    TesterFeedbackZone()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if availableSignals.hasDownloadData {
                    DistributionPulseZone()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: availableSignals)
    }
}
```

`SignalSet` computed from active distribution targets. Canvas composition fully driven by signal availability.

---

## 11. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | Launch Mode activation | Any active distribution target. No App Store requirement. |
| 2 | MVP signal set | Crash data (ASC API), App Store reviews, ratings trend, tester feedback (TestFlight), download counts. Third-party SDKs post-MVP. |
| 3 | Unavailable signals | Hidden entirely. Canvas recomposes. No empty or disabled states for unavailable signals. |
| 4 | Multi-target aggregation | Signals from all active targets aggregated. Source labelled per row where ambiguity exists. |
| 5 | HUD health pulse driver | Launch Mode is the primary driver. Re-evaluates every 5 minutes or on app foreground. |
