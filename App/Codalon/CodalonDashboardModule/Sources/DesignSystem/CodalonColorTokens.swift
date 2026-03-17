// Issue #37 — Codalon semantic color mapping

import SwiftUI
import HelaiaDesign

// MARK: - CodalonContextColor

public enum CodalonContextColor: String, Sendable, CaseIterable {
    case development
    case release
    case launch

    public var tint: Color {
        switch self {
        case .development: Color(hex: "#4A90D9")
        case .release: Color(hex: "#E8A020")
        case .launch: Color(hex: "#2EB87A")
        }
    }

    public var ambientBackground: Color {
        switch self {
        case .development: Color(hex: "#1A1E2E")
        case .release: Color(hex: "#1E1A10")
        case .launch: Color(hex: "#101E1A")
        }
    }

    public var tintOpacity4: Color {
        tint.opacity(0.04)
    }

    public var tintOpacity8: Color {
        tint.opacity(0.08)
    }

    public var tintOpacity10: Color {
        tint.opacity(0.10)
    }
}

// MARK: - CodalonStatusColor

public enum CodalonStatusColor: Sendable {
    public static let healthy = Color(hex: "#2EB87A")
    public static let warning = Color(hex: "#E8A020")
    public static let critical = Color(hex: "#E84545")
    public static let blocker = Color(hex: "#E84545")
    public static let neutral = Color.secondary
}

// MARK: - CodalonMonospacedStyle

public struct CodalonMonospacedStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content.font(.system(.body, design: .monospaced))
    }
}

extension View {

    public func codalonMonospaced() -> some View {
        modifier(CodalonMonospacedStyle())
    }
}
