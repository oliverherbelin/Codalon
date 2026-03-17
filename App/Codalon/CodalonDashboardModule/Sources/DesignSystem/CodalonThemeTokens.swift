// Issue #35 — Codalon theme tokens

import SwiftUI
import HelaiaDesign

// MARK: - CodalonTheme

public enum CodalonTheme: Sendable {

    public static func makeThemeConfig(
        for context: CodalonContext,
        colorScheme: ColorScheme = .dark
    ) -> HelaiaThemeConfig {
        HelaiaThemeConfig(
            accentColor: context.theme.color(for: colorScheme),
            density: .regular
        )
    }
}

// MARK: - CodalonSpacing

public enum CodalonSpacing: Sendable {
    public static let zoneGap: CGFloat = 16
    public static let cardPadding: CGFloat = 20
    public static let minWindowHeight: CGFloat = 760
}

// MARK: - CodalonRadius

public enum CodalonRadius: Sendable {
    public static let card: CGFloat = 16
    public static let zone: CGFloat = 12
    public static let row: CGFloat = 6
    public static let pill: CGFloat = 18
    public static let sheet: CGFloat = 16
    public static let onboarding: CGFloat = 20
}

// MARK: - CodalonShadow

public enum CodalonShadow: Sendable {

    public struct Config: Sendable, Equatable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
    }

    public static let card = Config(
        color: .black.opacity(0.08), radius: 16, x: 0, y: 4
    )
    public static let inspector = Config(
        color: .black.opacity(0.12), radius: 20, x: -4, y: 0
    )
    public static let hud = Config(
        color: .black.opacity(0.12), radius: 12, x: 0, y: -4
    )
    public static let sheet = Config(
        color: .black.opacity(0.20), radius: 40, x: 0, y: 12
    )
    public static let pill = Config(
        color: .black.opacity(0.10), radius: 8, x: 0, y: 4
    )
}

// MARK: - CodalonMonospacedStyle

public struct CodalonMonospacedStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content.monospacedDigit()
    }
}

extension View {

    public func codalonMonospaced() -> some View {
        modifier(CodalonMonospacedStyle())
    }
}

// MARK: - View + CodalonShadow

extension View {

    public func codalonShadow(_ config: CodalonShadow.Config) -> some View {
        shadow(
            color: config.color,
            radius: config.radius,
            x: config.x,
            y: config.y
        )
    }
}
