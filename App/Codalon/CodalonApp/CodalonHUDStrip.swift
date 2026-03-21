// Issue #8 — HUD strip: persistent bottom anchor (HUD Strip Spec v1.0)

import SwiftUI
import HelaiaDesign

// MARK: - CodalonHUDStrip

struct CodalonHUDStrip: View {

    @Environment(CodalonShellState.self) private var shellState
    @Environment(\.projectContext) private var context
    @Environment(\.healthState) private var health
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var isModePopoverShown = false
    @State private var isHealthPopoverShown = false
    @State private var isHoveredLeft = false
    @State private var isHoveredCenter = false
    @State private var isHoveredRight = false

    var body: some View {
        HStack(spacing: 0) {
            leftZone
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, CodalonSpacing.zoneGap)

            centerZone
                .frame(width: 220)

            rightZone
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, CodalonSpacing.zoneGap)
        }
        .frame(height: 44)
        .background { hudBackground }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SemanticColor.border(for: colorScheme))
                .frame(height: BorderWidth.hairline)
        }
        .codalonShadow(CodalonShadow.hud)
        .offset(y: isVisible ? 0 : 44)
        .opacity(isVisible ? 1 : 0)
        .animation(
            CodalonAnimation.animation(
                isVisible
                    ? CodalonAnimation.hudShow
                    : CodalonAnimation.rowAppearance,
                reduceMotion: reduceMotion
            ),
            value: isVisible
        )
        .onAppear { scheduleHide() }
        .onHover { hovering in
            if hovering {
                show()
            } else {
                scheduleHide()
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var hudBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            context.theme.color(for: colorScheme).opacity(Opacity.State.hover)
        }
    }

    // MARK: - Left Zone — Project Identity

    @ViewBuilder
    private var leftZone: some View {
        Button {
            shellState.isProjectSwitcherVisible = true
        } label: {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    shellState.projectIcon ?? "folder.fill",
                    size: .custom(16),
                    color: shellState.projectColor.flatMap { Color(hex: $0) }
                        ?? SemanticColor.textSecondary(for: colorScheme)
                )

                Text(shellState.projectName ?? "No Project")
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
            }
            .padding(.horizontal, Spacing._1_5)
            .padding(.vertical, Spacing._1)
            .background {
                if isHoveredLeft {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColor.textPrimary(for: colorScheme).opacity(Opacity.State.hover))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .onHover { isHoveredLeft = $0 }
        .accessibilityLabel("Switch project")
    }

    // MARK: - Center Zone — Context Indicator

    @ViewBuilder
    private var centerZone: some View {
        Button {
            isModePopoverShown = true
        } label: {
            HStack(spacing: Spacing._1) {
                HelaiaIconView(
                    context.iconName,
                    size: .sm,
                    color: context.theme.color(for: colorScheme)
                )

                Text(context.displayName.uppercased())
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1)
            .background {
                if isHoveredCenter {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColor.textPrimary(for: colorScheme).opacity(Opacity.State.hover))
                }
            }
            .overlay {
                if let proposed = shellState.proposedContext, proposed != context {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(proposed.theme.color(for: colorScheme), lineWidth: BorderWidth.medium)
                        .modifier(PulseOpacity(duration: 1.8, reduceMotion: reduceMotion))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .onHover { isHoveredCenter = $0 }
        .frame(minWidth: 44, minHeight: 44)
        .popover(isPresented: $isModePopoverShown, attachmentAnchor: .point(.top)) {
            ModeOverridePopover(
                activeContext: context,
                onSelect: { newContext in
                    shellState.activeContext = newContext
                    isModePopoverShown = false
                }
            )
        }
        .accessibilityLabel("Change context mode")
    }

    // MARK: - Right Zone — Health Pulse

    @ViewBuilder
    private var rightZone: some View {
        Button {
            isHealthPopoverShown = true
        } label: {
            HStack(spacing: Spacing._1) {
                Circle()
                    .fill(healthOrbColor)
                    .frame(width: 8, height: 8)
                    .modifier(PulseOpacity(
                        duration: healthNeedsPulse ? 2.0 : 0,
                        reduceMotion: reduceMotion
                    ))

                Text(healthLabel)
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, Spacing._1_5)
            .padding(.vertical, Spacing._1)
            .background {
                if isHoveredRight {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColor.textPrimary(for: colorScheme).opacity(Opacity.State.hover))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .onHover { isHoveredRight = $0 }
        .popover(isPresented: $isHealthPopoverShown, attachmentAnchor: .point(.top)) {
            HealthSummaryPopover(healthState: health)
        }
        .accessibilityLabel("View health summary")
    }

    // MARK: - Health Helpers

    private var healthOrbColor: Color {
        switch health {
        case .healthy: SemanticColor.success(for: colorScheme)
        case .warning: SemanticColor.warning(for: colorScheme)
        case .critical: SemanticColor.error(for: colorScheme)
        case .noData: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private var healthLabel: String {
        switch health {
        case .healthy: "Healthy"
        case .warning(let msg): msg
        case .critical(let msg): msg
        case .noData: "No signals"
        }
    }

    private var healthNeedsPulse: Bool {
        switch health {
        case .warning, .critical: true
        default: false
        }
    }

    // MARK: - Auto-Hide

    private var forceVisible: Bool {
        isModePopoverShown || isHealthPopoverShown || shellState.proposedContext != nil
    }

    private func show() {
        hideTask?.cancel()
        isVisible = true
    }

    private func scheduleHide() {
        guard !forceVisible else { return }
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(CodalonDuration.hudAutoHide))
            guard !Task.isCancelled, !forceVisible else { return }
            isVisible = false
        }
    }
}

// MARK: - PulseOpacity Modifier

private struct PulseOpacity: ViewModifier {
    let duration: Double
    let reduceMotion: Bool

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        if duration > 0, !reduceMotion {
            content
                .opacity(isPulsing ? Opacity.low : Opacity.full)
                .animation(
                    .easeInOut(duration: duration).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear { isPulsing = true }
        } else {
            content
        }
    }
}

// MARK: - Mode Override Popover

private struct ModeOverridePopover: View {

    let activeContext: CodalonContext
    let onSelect: (CodalonContext) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let modes: [(CodalonContext, String)] = [
        (.development, "Building features, fixing bugs"),
        (.release, "Preparing a release for submission"),
        (.launch, "Post-launch monitoring and response"),
    ]

    var body: some View {
        VStack(spacing: Spacing._0_5) {
            ForEach(modes, id: \.0) { mode, descriptor in
                modeRow(mode, descriptor: descriptor)
            }
        }
        .padding(Spacing._2)
        .frame(width: 240)
    }

    @ViewBuilder
    private func modeRow(_ mode: CodalonContext, descriptor: String) -> some View {
        let isActive = mode == activeContext

        Button {
            if !isActive { onSelect(mode) }
        } label: {
            HStack(spacing: Spacing._2) {
                HelaiaIconView(
                    mode.iconName,
                    size: .custom(16),
                    color: mode.theme.color(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text(mode.displayName)
                        .helaiaFont(.subheadline)

                    Text(descriptor)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }

                Spacer()

                if isActive {
                    HelaiaIconView(
                        "checkmark",
                        size: .xs,
                        color: mode.theme.color(for: colorScheme)
                    )
                }
            }
            .padding(.horizontal, Spacing._2)
            .frame(minHeight: 52)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColor.textPrimary(for: colorScheme).opacity(Opacity.State.hover))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(isActive)
    }
}

// MARK: - Health Summary Popover

private struct HealthSummaryPopover: View {

    let healthState: CodalonHealthState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing._1_5) {
                Circle()
                    .fill(orbColor)
                    .frame(width: 8, height: 8)

                Text(headerLabel)
                    .helaiaFont(.headline)
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._3)

            Divider()

            VStack(alignment: .leading, spacing: Spacing._1) {
                switch healthState {
                case .healthy:
                    signalRow(icon: "checkmark.circle", text: "All systems healthy")
                case .warning(let msg):
                    signalRow(icon: "exclamationmark.triangle", text: msg)
                case .critical(let msg):
                    signalRow(icon: "xmark.octagon", text: msg)
                case .noData:
                    signalRow(icon: "questionmark.circle", text: "No health data yet")
                }
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._2)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private func signalRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing._1_5) {
            HelaiaIconView(
                icon,
                size: .xs,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text(text)
                .helaiaFont(.subheadline)
        }
    }

    private var orbColor: Color {
        switch healthState {
        case .healthy: SemanticColor.success(for: colorScheme)
        case .warning: SemanticColor.warning(for: colorScheme)
        case .critical: SemanticColor.error(for: colorScheme)
        case .noData: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private var headerLabel: String {
        switch healthState {
        case .healthy: "Healthy"
        case .warning: "Warning"
        case .critical: "Critical"
        case .noData: "No Data"
        }
    }
}

// MARK: - Previews

#Preview("HUD Strip — Development") {
    let shell = CodalonShellState()
    shell.projectName = "Codalon"
    shell.projectIcon = "hammer.fill"
    shell.projectColor = "#4A90D9"
    return VStack {
        Spacer()
        CodalonHUDStrip()
    }
    .frame(width: 1200, height: 100)
    .environment(shell)
    .environment(\.projectContext, .development)
    .environment(\.healthState, .healthy)
}

#Preview("HUD Strip — Release + Warning") {
    let shell = CodalonShellState()
    shell.projectName = "Kitchee"
    shell.projectIcon = "fork.knife"
    shell.projectColor = "#4A7C59"
    return VStack {
        Spacer()
        CodalonHUDStrip()
    }
    .frame(width: 1200, height: 100)
    .environment(shell)
    .environment(\.projectContext, .release)
    .environment(\.healthState, .warning("3 overdue tasks"))
}

#Preview("HUD Strip — No Project") {
    VStack {
        Spacer()
        CodalonHUDStrip()
    }
    .frame(width: 1200, height: 100)
    .environment(CodalonShellState())
    .environment(\.projectContext, .development)
    .environment(\.healthState, .noData)
}
