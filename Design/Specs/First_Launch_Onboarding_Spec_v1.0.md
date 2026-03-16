# Codalon — First Launch & Onboarding Spec v1.0

**Status:** Closed
**Validated by:** Oli
**Date:** 2026-03-16
**Depends on:** Root Shell Spec v1.0, HUD Strip Spec v1.0

---

## 1. Design Intent

Onboarding is a single moment — not a wizard, not a setup assistant. The developer goes from zero to operational in the minimum number of steps. Nothing is required except a project name. Every integration can be connected later. The card gets out of the way as fast as the developer wants.

---

## 2. Trigger Conditions

| Condition | Result |
|---|---|
| No project has ever been configured | First launch state shown |
| Project exists | Dropped directly into last active context |
| App reset or project deleted | First launch state shown again |

First launch state is shown **once per project lifecycle**, not once per app install.

---

## 3. Overall Layout

Full canvas. Centered card. No HUD strip. No menu bar items active except the app menu.

Ambient layer renders at Development Mode default (cool blue-grey). The ambient layer is alive from the start — first impression of the shell environment.

### Card Container

| Property | Value |
|---|---|
| Width | 560 pt |
| Height | Content-driven, min 440 pt, max 560 pt |
| Corner radius | 20 pt |
| Background | `.thickMaterial` |
| Border | 0.5 pt, `Color.primary.opacity(0.08)` |
| Shadow | `shadow(color: .black.opacity(0.16), radius: 40, x: 0, y: 12)` |
| Position | Centered in window, both axes |
| Padding | 32 pt internal all sides |

### Card Appearance Animation

| Property | Value |
|---|---|
| Entry delay | 0.3s after window appears |
| Entry animation | `scale(0.94 → 1.0)` + `opacity(0 → 1)`, 360ms, `.spring(response: 0.4, dampingFraction: 0.82)` |

---

## 4. Step Navigation

Three steps. All inline within the card. No progress bar. No step counter. No back button on Step 1.

### Step Transition

| Property | Value |
|---|---|
| Outgoing step | `opacity(1 → 0)` + `translateY(0 → -16pt)`, 180ms, `.easeIn` |
| Incoming step | `opacity(0 → 1)` + `translateY(16pt → 0)`, 220ms, `.easeOut` |
| Card height | Animates to new content height with spring, 280ms |
| Reduce Motion | Opacity only — no translate |

### Steps

| # | Name |
|---|---|
| 1 | Connect integrations |
| 2 | Name your project |
| 3 | Choose your starting context |

---

## 5. Step 1 — Connect Integrations

### 5.1 Header

```
[Codalon app icon 32×32]
Welcome to Codalon
Connect your tools — or skip and connect later from Settings.
```

| Element | Spec |
|---|---|
| App icon | 32×32 pt, `clipShape(RoundedRectangle(cornerRadius: 7))` |
| Title | 22pt, `.semibold`, `primary`, centered |
| Subtitle | 14pt, `.regular`, `secondary`, centered, max 2 lines |
| Spacing icon → title | 12 pt |
| Spacing title → subtitle | 6 pt |
| Spacing subtitle → integrations | 24 pt |

### 5.2 Integration Rows

Three rows. Each independent — any can be connected or skipped in any order.

#### Row Structure

```
[service icon 28×28]  [service name]       [status]  [action]
                      [descriptor]
```

| Element | Spec |
|---|---|
| Row height | 56 pt |
| Service icon | 28×28 pt, `clipShape(RoundedRectangle(cornerRadius: 6))` |
| Service name | 14pt, `.medium`, `primary` |
| Descriptor | 12pt, `.regular`, `secondary`. One line. |
| Status | `Connected`, context tint, 12pt, `.medium`. Hidden when not connected. Trailing. |
| Action button | `Connect` when not connected. `Edit` when connected. 12pt text button. Trailing. |
| Row separator | 0.5 pt, `Color.primary.opacity(0.06)` |

#### GitHub Row

| Field | Value |
|---|---|
| Icon | GitHub mark asset |
| Name | `GitHub` |
| Descriptor | `Access repositories, issues, and pull requests` |
| Connect | Expands inline PAT input (§5.3) |

#### App Store Connect Row

| Field | Value |
|---|---|
| Icon | App Store icon asset |
| Name | `App Store Connect` |
| Descriptor | `Access builds, TestFlight, reviews, and sales` |
| Connect | Expands inline ASC key input (§5.4) |

#### AI Row

| Field | Value |
|---|---|
| Icon | Adapts to selected provider (Anthropic / OpenAI) |
| Name | `AI Assistant` |
| Descriptor | `Operational insights and analysis (BYOK)` |
| Connect | Expands inline AI key input (§5.5) |

### 5.3 GitHub PAT Inline Input

Expands below GitHub row with spring animation (180ms). Collapses on dismiss or success.

```
[Token field — secure]
Required scopes: repo, read:user
[Validate & Connect]  [Cancel]
```

| Element | Spec |
|---|---|
| Token field | `SecureField`. Placeholder `ghp_xxxxxxxxxxxx`. Full width. |
| Scope hint | 11pt, `secondary`. `Required scopes: repo, read:user` |
| Validate & Connect | Primary button, context tint |
| Cancel | Text button, `secondary`. Collapses input. |
| In progress | Button shows spinner, disabled |
| Success | Row animates to `Connected`. Input collapses. Token stored in `HelaiaKeychain`. |
| Failure | Inline error, 11pt, `#E84545`: `Invalid token or insufficient scopes.` |

### 5.4 App Store Connect Inline Input

```
[Issuer ID field]
[Key ID field]
[Private key — multiline or file import]
[Validate & Connect]  [Cancel]
```

| Element | Spec |
|---|---|
| Issuer ID | `TextField`. Placeholder `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Key ID | `TextField`. Placeholder `XXXXXXXXXX` |
| Private key | `TextEditor`, 5 lines, monospaced. Placeholder `Paste .p8 key contents here` |
| File import | `Import from .p8 file` link. Opens `NSOpenPanel` filtered to `.p8` |
| Validate & Connect | Same pattern as GitHub. Validates against ASC API. |
| Failure | `Invalid credentials. Check Issuer ID, Key ID, and private key.` |

### 5.5 AI Provider Inline Input

```
[Provider selector]
[API key field — secure]
[Validate & Connect]  [Cancel]
```

| Element | Spec |
|---|---|
| Provider selector | Inline pill selector: `Anthropic`, `OpenAI`, `Ollama`. Default: `Anthropic`. |
| API key field | `SecureField`. Placeholder adapts: `sk-ant-...` / `sk-...` |
| Ollama | Replaces key field with `Base URL` `TextField`. Placeholder `http://localhost:11434` |
| Validate & Connect | Validates with minimal test call to provider API |
| Failure — key error | `Invalid API key.` |
| Failure — Ollama | `Cannot reach Ollama at [url].` |

### 5.6 Step 1 Footer

```
[Continue →]
```

| Element | Spec |
|---|---|
| Button | Full-width, primary style, context tint, 44pt height, corner radius 10pt |
| Label | `Continue` if no integrations connected. `Continue →` once any integration is connected. |
| Behaviour | Always tappable — integrations are optional. Advances to Step 2. |

No explicit "skip" label. The button being always available communicates optionality.

---

## 6. Step 2 — Name Your Project

### 6.1 Header

```
Name your project
This is how Codalon will refer to your product.
You can change this any time.
```

| Element | Spec |
|---|---|
| Title | 22pt, `.semibold`, `primary`, centered |
| Subtitle | 14pt, `.regular`, `secondary`, centered |

### 6.2 Project Name Field

| Element | Spec |
|---|---|
| Field | `TextField`. Font: 17pt, `.regular`. Placeholder `My App`. Full width. Auto-focused on step entry. |
| Character limit | 64 characters. Counter appears at trailing edge when >48 chars: `12/64`, 11pt, `secondary`. |

### 6.3 GitHub Repository Selector

Shown only if GitHub was connected in Step 1.

```
Link to a GitHub repository (optional)
[Repo dropdown / search]
```

| Element | Spec |
|---|---|
| Label | 12pt, `secondary` |
| Selector | Searchable dropdown. Populated from GitHub repos via `HelaiaGit`. Placeholder `Search repositories`. |
| Auto-populate | Selecting a repo auto-fills project name field if still empty. Does not overwrite existing input. |
| Skip | Leave empty — project is Codalon-native only. |

Hidden entirely if GitHub was not connected.

### 6.4 Step 2 Footer

```
[← Back]                    [Create Project →]
```

| Element | Spec |
|---|---|
| Back | Text button, `secondary`, leading. Returns to Step 1 with reverse animation. |
| Create Project | Primary button, context tint. Enabled only when name field has ≥1 non-whitespace character. |
| On tap | Creates `CodalonProject` record. Advances to Step 3. |

---

## 7. Step 3 — Choose Your Starting Context

### 7.1 Header

```
How do you want to start?
Codalon will update this automatically as your project evolves.
```

| Element | Spec |
|---|---|
| Title | 22pt, `.semibold`, `primary`, centered |
| Subtitle | 14pt, `.regular`, `secondary`, centered |

### 7.2 Smart Suggestion Block

Shown only if GitHub was connected and a repo was selected in Step 2. Codalon performs a quick signal read on the repo (open issues, recent commits, active releases) and surfaces a suggestion.

```
[mode icon]  Looks like you're actively developing.
             We suggest starting in Development Mode.
```

| Element | Spec |
|---|---|
| Container | `RoundedRectangle`, context tint at 8% fill, 0.5pt context tint border, corner radius 10pt, 12pt padding |
| Icon | SF Symbol for suggested mode, 14pt, context tint |
| Text | 13pt, `.regular`, `primary`. First sentence `.medium`. |

Informational only — all three cards remain equally selectable. Hidden if no GitHub data available.

### 7.3 Context Option Cards

Three cards in `VStack(spacing: 10)`.

```
[mode icon 20×20]  [mode name]
                   [one-line descriptor]
```

| Element | Spec |
|---|---|
| Card height | 64 pt |
| Corner radius | 12 pt |
| Background unselected | `.regularMaterial` |
| Background selected | Context tint at 10% opacity + context tint border 1pt |
| Mode icon | 20pt SF Symbol. Context tint when selected, `secondary` when not. |
| Mode name | 15pt, `.semibold`. `primary` when selected, `primary.opacity(0.7)` when not. |
| Descriptor | 12pt, `.regular`, `secondary` |
| Padding | 16pt horizontal |
| Tap feedback | Spring scale `0.97 → 1.0`, 120ms |
| Tap action | Selects card → commits → launches shell |

#### Options

| Mode | SF Symbol | Descriptor |
|---|---|---|
| Development | `hammer.fill` | `Focus on tasks, milestones, and git activity` |
| Release | `shippingbox.fill` | `Manage builds, readiness, and submission` |
| Launch | `antenna.radiowaves.left.and.right` | `Monitor crashes, reviews, and distribution` |

### 7.4 Validated Decision

Tapping a context card directly commits and launches. No confirm button. Trivially reversible via HUD center zone.

### 7.5 Step 3 Footer

```
[← Back]
```

Back button only. The context card tap IS the completion action. Back returns to Step 2 — does not undo project creation.

---

## 8. Completion Sequence

On context card tap:

1. Selected card scales to 0.98 briefly (spring, 120ms)
2. Card animates out: `scale(1.0 → 0.94)` + `opacity(1 → 0)`, 320ms, `.easeIn`
3. Ambient layer transitions to selected context colour, 380ms cross-fade
4. Shell canvas fades in with selected context (per Root Shell Spec §8.3)
5. HUD strip fades in: `opacity(0 → 1)`, 200ms, `.easeOut`, 100ms delay after canvas appears
6. If integrations connected: data sync begins immediately in background
7. If no integrations: canvas shows empty states per context — no blocking loading state

---

## 9. Post-Onboarding Integration Access

Skipped integrations accessible from: `Project Settings → Integrations`

No persistent prompt or banner. If a feature requires an unconnected integration, a contextual inline prompt surfaces at the point of need only — never before.

---

## 10. Accessibility

| Element | Spec |
|---|---|
| Auto-focus | Step 1: none. Step 2: project name field. Step 3: none — VoiceOver reads cards. |
| VoiceOver — integration rows | Label: `[Service] integration, [connected/not connected]`. Action: `Connect [service]` |
| VoiceOver — context cards | Label: `[Mode name]: [descriptor]`. Action: `Start in [mode] mode` |
| Keyboard navigation | Full tab order. Return on context card selects and launches. |
| Reduce Motion | Transitions use opacity only. Card entry is instant fade. Completion is instant fade. |

---

## 11. SwiftUI Component Sketch

Structure reference only.

```swift
// OnboardingCard.swift

struct OnboardingCard: View {
    @State private var step: OnboardingStep = .connectIntegrations
    @State private var projectName: String = ""
    @State private var selectedRepo: GitHubRepo? = nil

    var body: some View {
        ZStack {
            switch step {
            case .connectIntegrations:
                ConnectIntegrationsStep(onContinue: {
                    step = .nameProject
                })
            case .nameProject:
                NameProjectStep(
                    name: $projectName,
                    selectedRepo: $selectedRepo,
                    onBack: { step = .connectIntegrations },
                    onContinue: {
                        createProject()
                        step = .chooseContext
                    }
                )
            case .chooseContext:
                ChooseContextStep(
                    onBack: { step = .nameProject },
                    onSelect: { context in
                        launchShell(context: context)
                    }
                )
            }
        }
        .padding(32)
        .frame(width: 560)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.16), radius: 40, x: 0, y: 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
    }
}

enum OnboardingStep {
    case connectIntegrations
    case nameProject
    case chooseContext
}
```

---

## 12. Decisions Log

| # | Decision | Outcome |
|---|---|---|
| 1 | GitHub auth MVP | PAT only. OAuth post-MVP. Stored in `HelaiaKeychain`. Validated on entry. Required scopes: `repo`, `read:user`. |
| 2 | Integration requirement | All optional. GitHub PAT, ASC key, AI key can all be skipped and connected later from Settings. |
| 3 | Distribution target | Deferred. Not asked during onboarding. Set when creating first release. |
| 4 | Project name | Required (min 1 non-whitespace char). Only mandatory field in onboarding. |
| 5 | Context selection | Direct card tap commits and launches. No confirm button. Trivially reversible. |
| 6 | Post-skip integration prompts | No persistent banner. Surfaces contextually at point of need only. |
